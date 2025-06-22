# GitHub Repository Setup Script
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    
    [Parameter(Mandatory=$false)]
    [string]$Description = "Smart Home IoT Platform - Full-stack serverless application for managing smart devices"
)

Write-Host "Setting up GitHub repository: $RepoName" -ForegroundColor Green

# Check if GitHub CLI is installed
try {
    gh --version | Out-Null
} catch {
    Write-Host "GitHub CLI not found. Please install it from: https://cli.github.com/" -ForegroundColor Red
    Write-Host "After installation, run: gh auth login" -ForegroundColor Yellow
    exit 1
}

# Create GitHub repository
Write-Host "Creating GitHub repository..." -ForegroundColor Yellow
gh repo create $RepoName --public --description $Description --confirm

# Add remote origin
Write-Host "Adding remote origin..." -ForegroundColor Yellow
git remote remove origin 2>$null
git remote add origin "https://github.com/$(gh api user --jq .login)/$RepoName.git"

# Push to GitHub
Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
git branch -M main
git push -u origin main

Write-Host "✅ Repository created successfully!" -ForegroundColor Green
Write-Host "🌐 Repository URL: https://github.com/$(gh api user --jq .login)/$RepoName" -ForegroundColor Cyan
Write-Host "📚 Clone command: git clone https://github.com/$(gh api user --jq .login)/$RepoName.git" -ForegroundColor Cyan