# Smart Home Flutter Build & Deploy Script
param(
    [string]$env = "dev"
)

Write-Host "Building and deploying Flutter app for environment: $env" -ForegroundColor Cyan

# Check if Flutter project exists
if (-not (Test-Path "frontend/pubspec.yaml")) {
    Write-Host "Flutter project not found in frontend/ directory" -ForegroundColor Red
    exit 1
}

# Fetch environment variables from SSM
Write-Host "Fetching configuration from AWS SSM..." -ForegroundColor Yellow

try {
    $USER_POOL_ID = aws ssm get-parameter --name "/SmartHome/$env/USER_POOL_ID" --query "Parameter.Value" --output text
    $USER_POOL_CLIENT_ID = aws ssm get-parameter --name "/SmartHome/$env/USER_POOL_CLIENT_ID" --query "Parameter.Value" --output text
    $IDENTITY_POOL_ID = aws ssm get-parameter --name "/SmartHome/$env/IDENTITY_POOL_ID" --query "Parameter.Value" --output text
    $APPSYNC_URL = aws ssm get-parameter --name "/SmartHome/$env/APPSYNC_URL" --query "Parameter.Value" --output text
    $APPSYNC_API_KEY = aws ssm get-parameter --name "/SmartHome/$env/APPSYNC_API_KEY" --query "Parameter.Value" --output text
    $FRONTEND_DOMAIN = aws ssm get-parameter --name "/SmartHome/$env/FRONTEND_DOMAIN" --query "Parameter.Value" --output text
    $AMPLIFY_APP_ID = aws ssm get-parameter --name "/SmartHome/$env/AMPLIFY_APP_ID" --query "Parameter.Value" --output text
    
    Write-Host "Configuration loaded successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to fetch configuration from SSM. Make sure your backend is deployed." -ForegroundColor Red
    exit 1
}

# Change to Flutter project directory
Set-Location "frontend"

# Get Flutter dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Cyan
flutter pub get

# Build Flutter web app with environment variables
Write-Host "Building Flutter web app..." -ForegroundColor Cyan

flutter build web --release `
    --dart-define=USER_POOL_ID=$USER_POOL_ID `
    --dart-define=USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID `
    --dart-define=IDENTITY_POOL_ID=$IDENTITY_POOL_ID `
    --dart-define=APPSYNC_URL=$APPSYNC_URL `
    --dart-define=APPSYNC_API_KEY=$APPSYNC_API_KEY `
    --dart-define=ENV_NAME=$env

if ($LASTEXITCODE -eq 0) {
    Write-Host "Flutter build completed successfully!" -ForegroundColor Green
    
    # Create deployment package
    Write-Host "Creating deployment package..." -ForegroundColor Cyan
    Set-Location "build/web"
    Compress-Archive -Path * -DestinationPath "../../frontend-$env.zip" -Force
    Set-Location "../../.."
    
    Write-Host "Deployment package created: frontend-$env.zip" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://console.aws.amazon.com/amplify/home?region=us-east-1#/$AMPLIFY_APP_ID" -ForegroundColor White
    Write-Host "2. Click 'Deploy manually'" -ForegroundColor White
    Write-Host "3. Upload: frontend-$env.zip" -ForegroundColor White
    Write-Host "4. Your app will be live at: $FRONTEND_DOMAIN" -ForegroundColor White
    
} else {
    Write-Host "Flutter build failed!" -ForegroundColor Red
    Set-Location ".."
    exit 1
}