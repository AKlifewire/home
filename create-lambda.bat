@echo off
REM Script to create the device-config-to-ui Lambda function

echo Creating device-config-to-ui Lambda function...

REM Install required dependencies if not already installed
if not exist node_modules\dotenv (
  echo Installing dependencies...
  npm install dotenv aws-sdk
)

REM Create a temporary zip file for the Lambda function
echo Creating Lambda deployment package...
cd lambda
powershell Compress-Archive -Path device-config-to-ui.js -DestinationPath ..\lambda-package.zip -Force
cd ..

REM Use AWS CLI to create or update the Lambda function
echo Checking if Lambda function exists...
aws lambda get-function --function-name device-config-to-ui > nul 2>&1
if %ERRORLEVEL% EQU 0 (
  echo Updating existing Lambda function...
  aws lambda update-function-code --function-name device-config-to-ui --zip-file fileb://lambda-package.zip
) else (
  echo Creating new Lambda function...
  
  REM Create a basic execution role for the Lambda if it doesn't exist
  aws iam get-role --role-name device-config-to-ui-role > nul 2>&1
  if %ERRORLEVEL% NEQ 0 (
    echo Creating IAM role for Lambda...
    aws iam create-role --role-name device-config-to-ui-role --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}" > role-output.json
    
    echo Attaching policies to role...
    aws iam attach-role-policy --role-name device-config-to-ui-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    aws iam attach-role-policy --role-name device-config-to-ui-role --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
    aws iam attach-role-policy --role-name device-config-to-ui-role --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
    
    echo Waiting for role to propagate...
    timeout /t 10 /nobreak > nul
    
    for /f "tokens=*" %%a in ('type role-output.json ^| findstr "Arn"') do set ROLE_ARN=%%a
    set ROLE_ARN=%ROLE_ARN:*:=%
    set ROLE_ARN=%ROLE_ARN:~0,-2%
    set ROLE_ARN=arn:aws:iam::%ROLE_ARN%
  ) else (
    echo Using existing IAM role...
    for /f "tokens=*" %%a in ('aws iam get-role --role-name device-config-to-ui-role --query "Role.Arn" --output text') do set ROLE_ARN=%%a
  )
  
  echo Creating Lambda function with role: %ROLE_ARN%
  
  REM Get environment variables from .env file
  for /f "tokens=*" %%a in (.env) do (
    set %%a
  )
  
  aws lambda create-function --function-name device-config-to-ui --runtime nodejs18.x --role %ROLE_ARN% --handler device-config-to-ui.handler --zip-file fileb://lambda-package.zip --timeout 30 --environment "Variables={UI_BUCKET=%UI_BUCKET%,DEVICES_TABLE=%DEVICES_TABLE%}"
)

REM Clean up
echo Cleaning up...
del lambda-package.zip
if exist role-output.json del role-output.json

echo Lambda function device-config-to-ui is ready!
echo You can now run test-e2e.bat to execute the end-to-end tests.