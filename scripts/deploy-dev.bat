@echo off
REM Quick deployment script for dev environment

echo ===== AK Smart Home Platform Dev Deployment =====
echo.

REM Navigate to project root
cd ..

REM Create Lambda asset folders if needed
echo Creating Lambda asset folders...
if not exist "dist\lambdas\resolvers" mkdir dist\lambdas\resolvers
if not exist "dist\lambdas\automation" mkdir dist\lambdas\automation
if not exist "dist\lambdas\iot" mkdir dist\lambdas\iot
if not exist "dist\lambdas\stripe" mkdir dist\lambdas\stripe

REM Create placeholder files if they don't exist
if not exist "dist\lambdas\resolvers\index.js" echo // placeholder > dist\lambdas\resolvers\index.js
if not exist "dist\lambdas\automation\index.js" echo // placeholder > dist\lambdas\automation\index.js
if not exist "dist\lambdas\iot\index.js" echo // placeholder > dist\lambdas\iot\index.js
if not exist "dist\lambdas\stripe\index.js" echo // placeholder > dist\lambdas\stripe\index.js

echo.
echo Deploying to dev environment...
call npx cdk deploy --all --require-approval never -c env=dev

if %ERRORLEVEL% NEQ 0 (
  echo ERROR: Deployment failed!
  exit /b 1
)

echo.
echo Dev deployment completed successfully!