# Deploy all CDK stacks in correct dependency order
param(
    [string]$EnvName = "dev"
)

Write-Host "Starting deployment of all stacks for environment: $EnvName" -ForegroundColor Green

# Set environment variable
$env:ENV_NAME = $EnvName

# Layer 1: Independent stacks
Write-Host "Layer 1: Deploying independent stacks..." -ForegroundColor Yellow

$layer1Stacks = @(
    "$EnvName-AmplifyHostingStack",
    "$EnvName-AuthStack", 
    "$EnvName-StorageStack",
    "$EnvName-IoTStack"
)

foreach ($stack in $layer1Stacks) {
    Write-Host "Deploying $stack..." -ForegroundColor Cyan
    cdk deploy $stack --require-approval never
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to deploy $stack" -ForegroundColor Red
        exit 1
    }
    Write-Host "$stack deployed successfully" -ForegroundColor Green
}

# Layer 2: Dependent stacks
Write-Host "Layer 2: Deploying dependent stacks..." -ForegroundColor Yellow

$layer2Stacks = @(
    "$EnvName-AppSyncStack",
    "$EnvName-UiJsonStack"
)

foreach ($stack in $layer2Stacks) {
    Write-Host "Deploying $stack..." -ForegroundColor Cyan
    cdk deploy $stack --require-approval never
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to deploy $stack" -ForegroundColor Red
        exit 1
    }
    Write-Host "$stack deployed successfully" -ForegroundColor Green
}

# Update Cognito callback URLs
Write-Host "Updating Cognito callback URLs..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File "scripts\update-cognito-callback-urls.ps1" -EnvName $EnvName

Write-Host "All stacks deployed successfully!" -ForegroundColor Green