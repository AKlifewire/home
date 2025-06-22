# Smart Home IoT Platform Production E2E Test Suite
param(
    [Parameter(Mandatory=$false)]
    [string]$EnvName = "dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipFrontend,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

Write-Host "🚀 Smart Home IoT Platform - Production E2E Test Suite" -ForegroundColor Green
Write-Host "Environment: $EnvName" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Gray

# Check prerequisites
Write-Host "`n🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check AWS CLI
try {
    $awsIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "✅ AWS CLI configured - Account: $($awsIdentity.Account)" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not configured. Run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js available - Version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js." -ForegroundColor Red
    exit 1
}

# Install test dependencies
Write-Host "`n📦 Installing test dependencies..." -ForegroundColor Yellow
Set-Location tests
if (!(Test-Path "node_modules")) {
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}
Set-Location ..

# Set environment variables
$env:AWS_REGION = "us-east-1"
$env:ENV_NAME = $EnvName

Write-Host "`n🧪 Starting E2E Test Execution..." -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Gray

$testResults = @()

# Test 1: Backend API Integration
Write-Host "`n1️⃣ Backend API Integration Tests" -ForegroundColor Cyan
try {
    Set-Location tests
    $apiResult = node api-integration.test.js
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Backend API tests completed successfully" -ForegroundColor Green
        $testResults += @{ Name = "Backend API"; Status = "PASS" }
    } else {
        Write-Host "❌ Backend API tests failed" -ForegroundColor Red
        $testResults += @{ Name = "Backend API"; Status = "FAIL" }
    }
    Set-Location ..
} catch {
    Write-Host "❌ Backend API tests encountered an error: $_" -ForegroundColor Red
    $testResults += @{ Name = "Backend API"; Status = "ERROR" }
}

# Test 2: Full E2E Integration
Write-Host "`n2️⃣ Full E2E Integration Tests" -ForegroundColor Cyan
try {
    Set-Location tests
    $e2eResult = node e2e-integration.test.js
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ E2E integration tests completed successfully" -ForegroundColor Green
        $testResults += @{ Name = "E2E Integration"; Status = "PASS" }
    } else {
        Write-Host "❌ E2E integration tests failed" -ForegroundColor Red
        $testResults += @{ Name = "E2E Integration"; Status = "FAIL" }
    }
    Set-Location ..
} catch {
    Write-Host "❌ E2E integration tests encountered an error: $_" -ForegroundColor Red
    $testResults += @{ Name = "E2E Integration"; Status = "ERROR" }
}

# Test 3: Frontend E2E (Optional)
if (!$SkipFrontend) {
    Write-Host "`n3️⃣ Frontend E2E Tests" -ForegroundColor Cyan
    try {
        Set-Location tests
        $frontendResult = node frontend-e2e.test.js
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Frontend E2E tests completed successfully" -ForegroundColor Green
            $testResults += @{ Name = "Frontend E2E"; Status = "PASS" }
        } else {
            Write-Host "❌ Frontend E2E tests failed" -ForegroundColor Red
            $testResults += @{ Name = "Frontend E2E"; Status = "FAIL" }
        }
        Set-Location ..
    } catch {
        Write-Host "❌ Frontend E2E tests encountered an error: $_" -ForegroundColor Red
        $testResults += @{ Name = "Frontend E2E"; Status = "ERROR" }
    }
} else {
    Write-Host "`n3️⃣ Frontend E2E Tests - SKIPPED" -ForegroundColor Yellow
    $testResults += @{ Name = "Frontend E2E"; Status = "SKIPPED" }
}

# Test Results Summary
Write-Host "`n📊 PRODUCTION TEST RESULTS SUMMARY" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Gray

$passCount = 0
$failCount = 0
$errorCount = 0
$skipCount = 0

foreach ($result in $testResults) {
    $status = $result.Status
    $name = $result.Name
    
    switch ($status) {
        "PASS" { 
            Write-Host "✅ $name - PASSED" -ForegroundColor Green
            $passCount++
        }
        "FAIL" { 
            Write-Host "❌ $name - FAILED" -ForegroundColor Red
            $failCount++
        }
        "ERROR" { 
            Write-Host "💥 $name - ERROR" -ForegroundColor Magenta
            $errorCount++
        }
        "SKIPPED" { 
            Write-Host "⏭️ $name - SKIPPED" -ForegroundColor Yellow
            $skipCount++
        }
    }
}

$totalTests = $testResults.Count
Write-Host "`n🎯 OVERALL RESULTS:" -ForegroundColor Cyan
Write-Host "   Total Tests: $totalTests" -ForegroundColor White
Write-Host "   Passed: $passCount" -ForegroundColor Green
Write-Host "   Failed: $failCount" -ForegroundColor Red
Write-Host "   Errors: $errorCount" -ForegroundColor Magenta
Write-Host "   Skipped: $skipCount" -ForegroundColor Yellow

# Final verdict
if ($failCount -eq 0 -and $errorCount -eq 0) {
    Write-Host "`n🎉 ALL TESTS PASSED! Your Smart Home IoT Platform is production-ready!" -ForegroundColor Green
    exit 0
} elseif ($failCount -gt 0) {
    Write-Host "`n⚠️ Some tests failed. Review the logs above and fix issues before production deployment." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`n💥 Test execution encountered errors. Check your environment and try again." -ForegroundColor Red
    exit 2
}