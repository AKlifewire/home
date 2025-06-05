@echo off
REM Setup script for end-to-end testing environment

echo Setting up test environment...

REM Check if .env file exists, create from example if not
if not exist .env (
  echo Creating .env file from .env.example...
  copy .env.example .env
  echo Please update the .env file with your actual values
) else (
  echo .env file already exists
)

REM Install required dependencies
echo Installing required dependencies...
npm install aws-sdk uuid node-fetch

REM Deploy the device-config-to-ui Lambda function
echo Deploying device-config-to-ui Lambda function...
echo This will ensure the Lambda function exists with the correct name

REM Check if AWS CLI is installed
where aws >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo AWS CLI is not installed. Please install it first.
  exit /b 1
)

REM Check if user is logged in to AWS
aws sts get-caller-identity >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo You are not logged in to AWS. Please run 'aws configure' first.
  exit /b 1
)

REM Deploy the CDK stack that contains the device-config-to-ui Lambda
echo Running CDK deployment...
npx cdk deploy dev-DeviceConfigToUiStack --require-approval never

echo Test environment setup complete!
echo You can now run test-e2e.bat to execute the end-to-end tests.