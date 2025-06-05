@echo off
echo === Smart Home IoT Platform Deployment ===

REM Create deployment directory
if not exist deploy mkdir deploy

echo.
echo === 1. Packaging Lambda Functions ===
cd lambda

echo Packaging enhanced-device-registration-handler...
powershell Compress-Archive -Path enhanced-device-registration-handler.js -DestinationPath ..\deploy\enhanced-device-registration.zip -Force

echo Packaging device-config-to-ui-enhanced...
powershell Compress-Archive -Path device-config-to-ui-enhanced.js -DestinationPath ..\deploy\device-config-to-ui-enhanced.zip -Force

echo Packaging batch-get-device-uis...
powershell Compress-Archive -Path batch-get-device-uis.js -DestinationPath ..\deploy\batch-get-device-uis.zip -Force

cd ..

echo.
echo === 2. Deploying Lambda Functions ===
echo NOTE: You need to have AWS CLI configured with proper credentials

echo Deploying enhanced-device-registration-handler...
aws lambda create-function --function-name enhanced-device-registration-handler --runtime nodejs18.x --handler enhanced-device-registration-handler.handler --zip-file fileb://deploy/enhanced-device-registration.zip --role %LAMBDA_ROLE_ARN% || aws lambda update-function-code --function-name enhanced-device-registration-handler --zip-file fileb://deploy/enhanced-device-registration.zip

echo Deploying device-config-to-ui-enhanced...
aws lambda create-function --function-name device-config-to-ui-enhanced --runtime nodejs18.x --handler device-config-to-ui-enhanced.handler --zip-file fileb://deploy/device-config-to-ui-enhanced.zip --role %LAMBDA_ROLE_ARN% || aws lambda update-function-code --function-name device-config-to-ui-enhanced --zip-file fileb://deploy/device-config-to-ui-enhanced.zip

echo Deploying batch-get-device-uis...
aws lambda create-function --function-name batch-get-device-uis --runtime nodejs18.x --handler batch-get-device-uis.handler --zip-file fileb://deploy/batch-get-device-uis.zip --role %LAMBDA_ROLE_ARN% || aws lambda update-function-code --function-name batch-get-device-uis --zip-file fileb://deploy/batch-get-device-uis.zip

echo.
echo === 3. Setting Environment Variables ===
aws lambda update-function-configuration --function-name enhanced-device-registration-handler --environment "Variables={DEVICES_TABLE=%DEVICES_TABLE%,UI_BUCKET=%UI_BUCKET%,IOT_POLICY_NAME=%IOT_POLICY_NAME%,IOT_ENDPOINT=%IOT_ENDPOINT%}"

aws lambda update-function-configuration --function-name device-config-to-ui-enhanced --environment "Variables={DEVICES_TABLE=%DEVICES_TABLE%,UI_BUCKET=%UI_BUCKET%}"

aws lambda update-function-configuration --function-name batch-get-device-uis --environment "Variables={DEVICES_TABLE=%DEVICES_TABLE%,UI_BUCKET=%UI_BUCKET%}"

echo.
echo === 4. Updating AppSync Schema ===
echo NOTE: This step requires the AppSync API ID

if defined APPSYNC_API_ID (
  aws appsync start-schema-creation --api-id %APPSYNC_API_ID% --definition file://cdk/stacks/schema/schema.graphql
  echo Schema update initiated. Check AWS Console for status.
) else (
  echo APPSYNC_API_ID not set. Skipping schema update.
)

echo.
echo === 5. Configuring Flutter App ===
cd smart_home_flutter

echo Updating main.dart to use enhanced MQTT service...
echo // TODO: Manually update main.dart to use enhanced MQTT service

echo.
echo === 6. Running Integration Tests ===
echo Running device simulator test...
flutter test integration_test/device_simulator_test.dart

echo Running end-to-end test...
flutter test integration_test/e2e_device_flow_test.dart

cd ..

echo.
echo === Deployment Complete ===
echo Check the output above for any errors.
echo You may need to manually update the AppSync resolvers to use the new Lambda functions.