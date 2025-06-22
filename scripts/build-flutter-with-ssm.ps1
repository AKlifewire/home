# Build Flutter app with SSM parameters
param(
    [string]$EnvName = "dev"
)

Write-Host "Fetching SSM parameters for environment: $EnvName"

# Fetch SSM parameters
$USER_POOL_ID = aws ssm get-parameter --name "/SmartHome/$EnvName/USER_POOL_ID" --query "Parameter.Value" --output text
$USER_POOL_CLIENT_ID = aws ssm get-parameter --name "/SmartHome/$EnvName/USER_POOL_CLIENT_ID" --query "Parameter.Value" --output text
$IDENTITY_POOL_ID = aws ssm get-parameter --name "/SmartHome/$EnvName/IDENTITY_POOL_ID" --query "Parameter.Value" --output text
$FRONTEND_DOMAIN = aws ssm get-parameter --name "/SmartHome/$EnvName/FRONTEND_DOMAIN" --query "Parameter.Value" --output text
$AMPLIFY_APP_ID = aws ssm get-parameter --name "/SmartHome/$EnvName/AMPLIFY_APP_ID" --query "Parameter.Value" --output text

Write-Host "Building Flutter app with environment variables:"
Write-Host "USER_POOL_ID: $USER_POOL_ID"
Write-Host "USER_POOL_CLIENT_ID: $USER_POOL_CLIENT_ID"
Write-Host "FRONTEND_DOMAIN: $FRONTEND_DOMAIN"
Write-Host "AMPLIFY_APP_ID: $AMPLIFY_APP_ID"

# Build Flutter app
Set-Location frontend
flutter build web --release `
  --dart-define=USER_POOL_ID=$USER_POOL_ID `
  --dart-define=USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID `
  --dart-define=IDENTITY_POOL_ID=$IDENTITY_POOL_ID `
  --dart-define=ENV_NAME=$EnvName

# Create deployment zip
if (Test-Path "build/web") {
    Compress-Archive -Path "build/web/*" -DestinationPath "frontend-$EnvName.zip" -Force
    Write-Host "Frontend built and zipped as frontend-$EnvName.zip"
    Write-Host "Upload to Amplify Console: https://console.aws.amazon.com/amplify/home?region=us-east-1#/$AMPLIFY_APP_ID"
} else {
    Write-Host "Build failed - build/web directory not found"
}

Set-Location ..