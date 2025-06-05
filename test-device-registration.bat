@echo off
echo Testing device registration workflow...

rem Set environment variables
set AWS_REGION=us-east-1
set LAMBDA_FUNCTION_NAME=device-registration-dev
set CONFIG_LAMBDA_FUNCTION_NAME=device-config-to-ui
set DEVICES_TABLE=Devices
set TEST_USER_ID=test-user

rem Run the test script
node test-device-registration.js

echo Done!