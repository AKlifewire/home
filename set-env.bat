@echo off
REM Set these values according to your AWS environment
set LAMBDA_ROLE_ARN=arn:aws:iam::<account-id>:role/lambda-execution-role
set DEVICES_TABLE=SmartHomeDevices-dev
set UI_BUCKET=smart-home-ui-pages-dev
set IOT_POLICY_NAME=SmartHomeDevicePolicy
set IOT_ENDPOINT=<your-iot-endpoint>.iot.<region>.amazonaws.com
set APPSYNC_API_ID=<your-appsync-api-id>

echo Environment variables set successfully!