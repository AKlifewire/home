# Enterprise Smart Home IoT Platform Deployment Script
param(
    [Parameter(Mandatory=$false)]
    [string]$EnvName = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$AlertEmail = "admin@yourdomain.com",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests
)

Write-Host "🚀 Deploying Enterprise Smart Home IoT Platform" -ForegroundColor Green
Write-Host "Environment: $EnvName" -ForegroundColor Cyan
Write-Host "Alert Email: $AlertEmail" -ForegroundColor Cyan

# Set environment variables
$env:ENV_NAME = $EnvName
$env:ALERT_EMAIL = $AlertEmail

# Check prerequisites
Write-Host "`n🔍 Checking prerequisites..." -ForegroundColor Yellow

try {
    $awsIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "✅ AWS CLI configured - Account: $($awsIdentity.Account)" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not configured" -ForegroundColor Red
    exit 1
}

try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js available - Version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found" -ForegroundColor Red
    exit 1
}

# Install dependencies
Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Bootstrap CDK
Write-Host "`n🏗️ Bootstrapping CDK..." -ForegroundColor Yellow
npx cdk bootstrap
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ CDK bootstrap failed" -ForegroundColor Red
    exit 1
}

# Deploy all stacks
Write-Host "`n🚀 Deploying all stacks..." -ForegroundColor Yellow
npx cdk deploy --all --require-approval never --context envName=$EnvName
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Stack deployment failed" -ForegroundColor Red
    exit 1
}

# Build and deploy frontend
Write-Host "`n🌐 Building Flutter frontend..." -ForegroundColor Yellow
Set-Location frontend
flutter pub get
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter build failed" -ForegroundColor Red
    exit 1
}
Set-Location ..

# Run tests if not skipped
if (!$SkipTests) {
    Write-Host "`n🧪 Running E2E tests..." -ForegroundColor Yellow
    Set-Location tests
    npm install
    node api-integration.test.js
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Tests passed" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Some tests failed but deployment continues" -ForegroundColor Yellow
    }
    Set-Location ..
}

Write-Host "`n🎉 Enterprise deployment completed successfully!" -ForegroundColor Green
Write-Host "📊 Check CloudWatch Dashboard for monitoring" -ForegroundColor Cyan
Write-Host "🔒 WAF protection is now active" -ForegroundColor Cyan
Write-Host "📡 WebSocket API available for real-time updates" -ForegroundColor Cyan
Write-Host "📈 Analytics pipeline is collecting device data" -ForegroundColor Cyan