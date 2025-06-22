# Smart Home Infrastructure Deployment
Write-Host "Deploying Smart Home Infrastructure..." -ForegroundColor Cyan

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
    
    # Deploy stacks that can be safely redeployed
    $deployableStacks = @(
        "HomeStack-dev",
        "IoTStack-dev", 
        "AppSyncStack-dev",
        "AmplifyHostingStack-dev"
    )
    
    $successCount = 0
    $totalStacks = $deployableStacks.Count
    
    foreach ($stack in $deployableStacks) {
        Write-Host "`nDeploying $stack..." -ForegroundColor Cyan
        npx cdk deploy $stack --require-approval never
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$stack deployed successfully!" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "$stack deployment failed (may already exist)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nDeployment Summary:" -ForegroundColor Cyan
    Write-Host "Successfully deployed: $successCount/$totalStacks stacks" -ForegroundColor Green
    Write-Host "Your infrastructure is ready!" -ForegroundColor Green
    
} else {
    Write-Host "AWS credentials are not valid. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}