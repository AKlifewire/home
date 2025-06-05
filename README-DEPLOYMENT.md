# Smart Home IoT Platform Deployment Guide

This guide walks you through deploying and testing the Smart Home IoT Platform.

## Prerequisites

1. AWS CLI installed and configured with appropriate permissions
2. Flutter SDK installed
3. Node.js installed

## Deployment Steps

### 1. Set Environment Variables

Edit the `set-env.bat` file and update the following values:

```
LAMBDA_ROLE_ARN=arn:aws:iam::<account-id>:role/lambda-execution-role
DEVICES_TABLE=SmartHomeDevices-dev
UI_BUCKET=smart-home-ui-pages-dev
IOT_POLICY_NAME=SmartHomeDevicePolicy
IOT_ENDPOINT=<your-iot-endpoint>.iot.<region>.amazonaws.com
APPSYNC_API_ID=<your-appsync-api-id>
```

Then run:

```
set-env.bat
```

### 2. Test Components Locally

Run the local test script to verify components:

```
test-deployment.bat
```

This will:
- Run the local workflow test
- Test Flutter components
- Create test UI layouts

### 3. Deploy to AWS

Run the deployment script:

```
deploy.bat
```

This will:
- Package Lambda functions
- Deploy to AWS Lambda
- Set environment variables
- Update AppSync schema
- Run integration tests

### 4. Verify Deployment

1. Check AWS Console to verify Lambda functions are deployed
2. Check AppSync Console to verify schema updates
3. Run the Flutter app with the enhanced components:

```
cd smart_home_flutter
flutter run -t lib/main_enhanced.dart
```

### 5. Run Integration Tests

```
cd smart_home_flutter
flutter test integration_test/device_simulator_test.dart
flutter test integration_test/e2e_device_flow_test.dart
```

## Troubleshooting

### Lambda Deployment Issues

If Lambda deployment fails, check:
- IAM role permissions
- Lambda function names (they might already exist)
- ZIP file contents

### AppSync Schema Issues

If schema update fails:
- Check AppSync API ID
- Verify schema syntax
- Update resolvers manually in AWS Console

### MQTT Connection Issues

If MQTT connection fails:
- Verify IoT endpoint
- Check IoT policy permissions
- Verify device certificates

## Next Steps

After successful deployment:

1. Add more device types
2. Implement device grouping/rooms
3. Add pagination for device listing
4. Implement offline command queuing
5. Add historical data storage for charts