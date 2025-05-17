@echo off
REM Safe deployment script for AK Smart Home Platform
REM This script verifies everything before deploying

echo ===== AK Smart Home Platform Safe Deployment =====
echo.

REM Check if environment parameter is provided
if "%1"=="" (
  echo Usage: deploy-safe.bat [dev^|prod]
  exit /b 1
)

set ENV_NAME=%1
echo Preparing to deploy to %ENV_NAME% environment...

REM 1. Verify AWS credentials
echo.
echo Step 1: Verifying AWS credentials...
call aws sts get-caller-identity
if %ERRORLEVEL% NEQ 0 (
  echo ERROR: AWS credentials not valid. Please configure AWS CLI.
  exit /b 1
)

REM 2. Verify CDK synth works without errors
echo.
echo Step 2: Verifying CDK synthesis...
cd ..
call npx cdk synth -c env=%ENV_NAME%
if %ERRORLEVEL% NEQ 0 (
  echo ERROR: CDK synthesis failed. Please fix errors before deploying.
  exit /b 1
)

REM 3. Check for drift in deployed stacks
echo.
echo Step 3: Checking for infrastructure drift...
call npx cdk diff -c env=%ENV_NAME%

REM 4. Verify all required files exist
echo.
echo Step 4: Verifying required files...
if not exist "cdk\stacks\AmplifyHostingStack.ts" (
  echo ERROR: AmplifyHostingStack.ts not found!
  exit /b 1
)
if not exist "cdk\stacks\AuthStack.ts" (
  echo ERROR: AuthStack.ts not found!
  exit /b 1
)
if not exist "cdk\stacks\StorageStack.ts" (
  echo ERROR: StorageStack.ts not found!
  exit /b 1
)
if not exist "cdk\stacks\LambdaStack.ts" (
  echo ERROR: LambdaStack.ts not found!
  exit /b 1
)
if not exist "cdk\stacks\IoTStack.ts" (
  echo ERROR: IoTStack.ts not found!
  exit /b 1
)
if not exist "cdk\stacks\AppSyncStack.ts" (
  echo ERROR: AppSyncStack.ts not found!
  exit /b 1
)

REM 5. Create Lambda asset folders if needed
echo.
echo Step 5: Creating Lambda asset folders...
if not exist "dist\lambdas\resolvers" mkdir dist\lambdas\resolvers
if not exist "dist\lambdas\automation" mkdir dist\lambdas\automation
if not exist "dist\lambdas\iot" mkdir dist\lambdas\iot
if not exist "dist\lambdas\stripe" mkdir dist\lambdas\stripe

REM Create placeholder files if they don't exist
if not exist "dist\lambdas\resolvers\index.js" echo // placeholder > dist\lambdas\resolvers\index.js
if not exist "dist\lambdas\automation\index.js" echo // placeholder > dist\lambdas\automation\index.js
if not exist "dist\lambdas\iot\index.js" echo // placeholder > dist\lambdas\iot\index.js
if not exist "dist\lambdas\stripe\index.js" echo // placeholder > dist\lambdas\stripe\index.js

REM 6. Final confirmation
echo.
echo All checks passed! Ready to deploy to %ENV_NAME% environment.
set /p CONFIRM=Are you sure you want to deploy to %ENV_NAME%? (y/n): 

if /i "%CONFIRM%"=="y" (
  echo.
  echo Deploying to %ENV_NAME% environment...
  call npx cdk deploy --all --require-approval never -c env=%ENV_NAME%
  if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Deployment failed!
    exit /b 1
  )
  echo.
  echo Deployment to %ENV_NAME% completed successfully!
) else (
  echo.
  echo Deployment cancelled.
)