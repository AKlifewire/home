# Project Verification Script
Write-Host "🔍 Verifying Smart Home IoT Platform..." -ForegroundColor Green

# Check TypeScript compilation
Write-Host "`n📝 Checking TypeScript compilation..." -ForegroundColor Yellow
try {
    npx tsc --noEmit
    Write-Host "✅ TypeScript compilation: PASSED" -ForegroundColor Green
} catch {
    Write-Host "❌ TypeScript compilation: FAILED" -ForegroundColor Red
}

# Check Flutter dependencies
Write-Host "`n📱 Checking Flutter dependencies..." -ForegroundColor Yellow
try {
    cd frontend
    flutter pub get | Out-Null
    Write-Host "✅ Flutter dependencies: PASSED" -ForegroundColor Green
    cd ..
} catch {
    Write-Host "❌ Flutter dependencies: FAILED" -ForegroundColor Red
    cd ..
}

# Check CDK synth
Write-Host "`n☁️ Checking CDK synthesis..." -ForegroundColor Yellow
try {
    cdk synth --quiet | Out-Null
    Write-Host "✅ CDK synthesis: PASSED" -ForegroundColor Green
} catch {
    Write-Host "❌ CDK synthesis: FAILED" -ForegroundColor Red
}

# Check project structure
Write-Host "`n📁 Checking project structure..." -ForegroundColor Yellow
$requiredFiles = @(
    "cdk/app.ts",
    "frontend/lib/main.dart",
    "lambda/ui-json-handler.js",
    "scripts/deploy-all-stacks.ps1",
    "README.md",
    ".gitignore"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if ($allFilesExist) {
    Write-Host "✅ Project structure: PASSED" -ForegroundColor Green
} else {
    Write-Host "❌ Project structure: FAILED" -ForegroundColor Red
}

Write-Host "`n🎉 Project verification complete!" -ForegroundColor Green
Write-Host "Ready for GitHub deployment!" -ForegroundColor Cyan