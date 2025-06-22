# Update Cognito User Pool Client with frontend domain
param(
    [string]$EnvName = "dev"
)

Write-Host "Updating Cognito OAuth URLs for environment: $EnvName"

# Get SSM parameters
$USER_POOL_ID = aws ssm get-parameter --name "/SmartHome/$EnvName/USER_POOL_ID" --query "Parameter.Value" --output text
$USER_POOL_CLIENT_ID = aws ssm get-parameter --name "/SmartHome/$EnvName/USER_POOL_CLIENT_ID" --query "Parameter.Value" --output text
$FRONTEND_DOMAIN = aws ssm get-parameter --name "/SmartHome/$EnvName/FRONTEND_DOMAIN" --query "Parameter.Value" --output text

Write-Host "USER_POOL_ID: $USER_POOL_ID"
Write-Host "USER_POOL_CLIENT_ID: $USER_POOL_CLIENT_ID"
Write-Host "FRONTEND_DOMAIN: $FRONTEND_DOMAIN"

# Update User Pool Client with new callback URLs
aws cognito-idp update-user-pool-client `
  --user-pool-id $USER_POOL_ID `
  --client-id $USER_POOL_CLIENT_ID `
  --callback-urls "$FRONTEND_DOMAIN" "http://localhost:3000" `
  --logout-urls "$FRONTEND_DOMAIN" "http://localhost:3000" `
  --supported-identity-providers "COGNITO" `
  --allowed-o-auth-flows "code" `
  --allowed-o-auth-scopes "email" "openid" "profile" `
  --allowed-o-auth-flows-user-pool-client

Write-Host "✅ Cognito User Pool Client updated with frontend domain"