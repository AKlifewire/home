# Smart Home IoT System

This project implements a complete IoT solution for smart home devices with a dynamic UI system.

## Deployment Instructions

### Local Development

1. Install dependencies:
   ```
   npm install
   ```

2. Build the project:
   ```
   npm run build
   ```

3. Deploy the CDK stacks:
   ```
   npx cdk deploy --all --require-approval never --context environment=dev --exclude dev-MonitoringStack
   ```

4. Update frontend configuration:
   ```
   node get-ssm-params.js
   node update-frontend-config.js
   ```

### CI/CD Deployment

The project uses GitHub Actions for CI/CD:

- **Development Environment**: Pushes to the `develop` branch trigger the `deploy-dev.yml` workflow
- **Production Environment**: Pushes to the `main` branch trigger the `deploy-prod.yml` workflow

## Stack Structure

- **AuthStack**: Cognito user pools and identity pools
- **StorageStack**: S3 buckets for UI assets, OTA updates, and logs
- **IoTStack**: IoT Core setup with policies and provisioning templates
- **AnalyticsStack**: Timestream database for device metrics
- **UiJsonStack**: Dynamic UI configuration storage
- **LambdaStack**: Backend Lambda functions
- **AppSyncStack**: GraphQL API
- **PaymentStack**: Payment processing infrastructure
- **GreengrassStack**: Edge computing components
- **TwinMakerStack**: Digital twin capabilities
- **AmplifyHostingStack**: Frontend hosting

## Flutter Application

The Flutter application is located in the `smart_home_flutter` directory.

To build the web version:
```
cd smart_home_flutter
flutter build web
```