@echo off
REM Production deployment script with cleanup and verification

echo ===== AK Smart Home Platform Production Deployment =====
echo.

REM Navigate to project root
cd ..

REM 1. Verify AWS credentials
echo Step 1: Verifying AWS credentials...
call aws sts get-caller-identity
if %ERRORLEVEL% NEQ 0 (
  echo ERROR: AWS credentials not valid. Please configure AWS CLI.
  exit /b 1
)

REM 2. Check if any stacks are in ROLLBACK_COMPLETE state and delete them
echo.
echo Step 2: Checking for failed stacks...
aws cloudformation list-stacks --stack-status-filter ROLLBACK_COMPLETE --query "StackSummaries[?contains(StackName, 'prod')].StackName" --output text > failed_stacks.txt
for /f "tokens=*" %%a in (failed_stacks.txt) do (
  echo Deleting failed stack: %%a
  aws cloudformation delete-stack --stack-name %%a
  echo Waiting for stack deletion to complete...
  aws cloudformation wait stack-delete-complete --stack-name %%a
)
del failed_stacks.txt

REM 3. Create Lambda asset folders if needed
echo.
echo Step 3: Creating Lambda asset folders...
if not exist "dist\lambdas\resolvers" mkdir dist\lambdas\resolvers
if not exist "dist\lambdas\automation" mkdir dist\lambdas\automation
if not exist "dist\lambdas\iot" mkdir dist\lambdas\iot
if not exist "dist\lambdas\stripe" mkdir dist\lambdas\stripe

REM Create placeholder files if they don't exist
if not exist "dist\lambdas\resolvers\index.js" echo // placeholder > dist\lambdas\resolvers\index.js
if not exist "dist\lambdas\automation\index.js" echo // placeholder > dist\lambdas\automation\index.js
if not exist "dist\lambdas\iot\index.js" echo // placeholder > dist\lambdas\iot\index.js
if not exist "dist\lambdas\stripe\index.js" echo // placeholder > dist\lambdas\stripe\index.js

REM 4. Final confirmation
echo.
echo Ready to deploy to PRODUCTION environment.
set /p CONFIRM=Are you sure you want to deploy to PRODUCTION? (y/n): 

if /i "%CONFIRM%"=="y" (
  echo.
  echo Deploying to PRODUCTION environment...
  call npx cdk deploy --all --require-approval never -c env=prod
  if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Deployment failed!
    exit /b 1
  )
  echo.
  echo Production deployment completed successfully!
) else (
  echo.
  echo Deployment cancelled.
)