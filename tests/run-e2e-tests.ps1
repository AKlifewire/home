# Smart Home IoT Platform E2E Test Runner
param(
    [Parameter(Mandatory=$false)]
    [string]$EnvName = "dev"
)

Write-Host "🚀 Running Smart Home IoT Platform E2E Tests" -ForegroundColor Green
Write-Host "Environment: $EnvName" -ForegroundColor Cyan

# Check if AWS CLI is configured
try {
    aws sts get-caller-identity | Out-Null
    Write-Host "✅ AWS CLI configured" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not configured. Run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Install test dependencies if needed
if (!(Test-Path "node_modules")) {
    Write-Host "📦 Installing test dependencies..." -ForegroundColor Yellow
    npm install aws-sdk axios
}

# Set environment variables
$env:AWS_REGION = "us-east-1"
$env:ENV_NAME = $EnvName

# Run the E2E tests
Write-Host "🧪 Executing E2E test suite..." -ForegroundColor Yellow
node tests/e2e-integration.test.js

Write-Host "`n✨ E2E test execution completed!" -ForegroundColor Green