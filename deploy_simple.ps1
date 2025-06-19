# Smart Home Infrastructure Test Deployment
Write-Host "Testing deployment of all stacks..." -ForegroundColor Cyan

# Verify AWS credentials
Write-Host "Verifying AWS credentials..." -ForegroundColor Cyan
aws sts get-caller-identity

if ($LASTEXITCODE -eq 0) {
    Write-Host "AWS credentials are valid" -ForegroundColor Green
    
    # Install dependencies
    Write-Host "Installing dependencies..." -ForegroundColor Cyan
    npm install
    
    # Bootstrap CDK
    Write-Host "Bootstrapping CDK..." -ForegroundColor Cyan
    npx cdk bootstrap
    
    # Deploy stacks in order
    $stacks = @(
        "AuthStack",
        "StorageStack",
        "DeviceRegistrationStack",
        "IoTStack",
        "UiJsonStack",
        "PaymentStack",
        "TwinMakerStack",
        "GreengrassStack",
        "AnalyticsStack",
        "AppSyncStack",
        "AmplifyHostingStack"
    )
    
    foreach ($stack in $stacks) {
        Write-Host "`nDeploying $stack..." -ForegroundColor Cyan
        npx cdk deploy "dev-$stack" --require-approval never
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to deploy $stack" -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host "`nAll stacks deployed successfully!" -ForegroundColor Green
} else {
    Write-Host "AWS credentials are not valid. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}
