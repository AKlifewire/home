@echo off
echo === Smart Home IoT Platform Test Deployment ===

REM Create test output directory
if not exist test-output mkdir test-output

echo.
echo === 1. Running Local Tests ===
echo Running local workflow test...
node test-local-workflow.js

echo.
echo === 2. Testing Flutter Components ===
cd smart_home_flutter

echo Building SmartDeviceWidgetFactory...
flutter test --no-pub test/widget_test.dart

echo.
echo === 3. Testing Device Simulator ===
echo NOTE: This test requires MQTT broker access
echo Skipping device simulator test for now. Run manually with:
echo flutter test integration_test/device_simulator_test.dart

echo.
echo === 4. Testing Enhanced UI Components ===
echo Creating test UI layout...
echo {^
  "title": "Test Device",^
  "deviceId": "test-device-123",^
  "deviceType": "relay",^
  "components": [^
    {^
      "type": "switch",^
      "field": "relay1",^
      "label": "Relay 1",^
      "topic": "devices/test-device-123/components/relay1/set",^
      "statusTopic": "devices/test-device-123/components/relay1/status"^
    },^
    {^
      "type": "switch",^
      "field": "relay2",^
      "label": "Relay 2",^
      "topic": "devices/test-device-123/components/relay2/set",^
      "statusTopic": "devices/test-device-123/components/relay2/status"^
    },^
    {^
      "type": "status",^
      "field": "connection",^
      "label": "Connection Status",^
      "topic": "devices/test-device-123/connection"^
    }^
  ]^
} > ..\test-output\test-ui-layout.json

echo.
echo === Test Deployment Complete ===
echo.
echo Next steps:
echo 1. Review the test output in the test-output directory
echo 2. Update set-env.bat with your AWS credentials
echo 3. Run set-env.bat to set environment variables
echo 4. Run deploy.bat to deploy to AWS
echo 5. Run integration tests with real devices

cd ..