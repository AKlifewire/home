@echo off
echo Staging changes...
git add cdk\stacks\AmplifyHostingStack.ts
git add .github\workflows\auto-commit-changes.yml

echo Committing changes...
git commit -m "Fix environment-specific resource naming in AmplifyHostingStack"

echo Pushing to remote repository...
git push origin dev

echo Done!