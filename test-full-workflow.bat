@echo off
echo Testing full end-to-end workflow...

rem Set environment variables
set AWS_REGION=us-east-1
set REGISTRATION_LAMBDA=device-registration-dev
set CONFIG_LAMBDA=device-config-to-ui
set UI_BUCKET=dev-storagestack-uipagebucketacd75cdc-wbwnvre1dnb9
set TEST_USER_ID=test-user

rem Run the test script
node test-full-workflow.js

echo Done!