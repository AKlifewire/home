<<<<<<< Updated upstream
# AK Smart Home Platform – Project Overview

## Overview
This is a *fully serverless smart home automation platform* built using *AWS CDK, designed to support **multi-user, **multi-device* control in real time. It integrates authentication, device communication, real-time updates, and a dynamic user interface.

The frontend is built with *Flutter, hosted on **AWS Amplify Hosting, and the backend is built entirely with **AWS CDK stacks* using a modular multi-stack architecture.

---

## Architecture Components

### Backend (AWS CDK)
- *AuthStack* – AWS Cognito for user authentication (UserPool, IdentityPool, UserPoolClient)
- *LambdaStack* – Backend functions (e.g. get-ui-page, control-device) in TypeScript
- *IoTStack* – AWS IoT Core to send/receive MQTT messages to/from smart devices (relays, sensors)
- *AppSyncStack* – AWS AppSync with GraphQL API connected to Lambda for queries, mutations, and subscriptions
- *StorageStack* – S3 bucket to store JSON-based UI layouts per user or device
- *AmplifyHostingStack* – Hosts the Flutter web application with environment-specific configurations
- *SSM Parameters* – Stores critical stack outputs (GraphQL endpoint, S3 URL, Cognito IDs) in SSM for centralized config access

### Frontend (Flutter + Amplify)
- Flutter web app deployed with *Amplify Hosting*
- Uses *Amplify Auth, **Amplify API, and **GraphQL Subscriptions* to connect to backend
- UI is dynamically rendered from JSON layouts stored in S3 (e.g., dashboard page, control buttons)
- Device control is handled via AppSync mutations that trigger MQTT publish functions via Lambda

---

## Multi-Environment Support
The platform supports multiple deployment environments (dev, prod) with:
- Environment-specific resource naming to avoid collisions
- Separate AWS resources per environment
- Environment variables passed to Lambda functions and Amplify app
- CI/CD workflows for each environment (.github/workflows/deploy-dev.yml, deploy-prod.yml)

### Deployment Commands
```bash
# Deploy to development environment
npx cdk deploy --all --require-approval never -c env=dev

# Deploy to production environment
npx cdk deploy --all --require-approval never -c env=prod
```

---

## Key Use Case
> Each authenticated user can log in and control multiple smart devices (e.g. lights, sensors, fans) via real-time interactions powered by MQTT, GraphQL subscriptions, and Flutter widgets dynamically rendered from S3 UI schemas.

---

## Current Dev Status

- ✅ CDK stacks deployed: Auth, Lambda, AppSync, IoT, Storage, AmplifyHosting
- ✅ Flutter frontend connected to Amplify Hosting
- ✅ AppSync schema includes mutations (controlDevice) and subscriptions (onDeviceStateChanged)
- ✅ Lambda resolver sends MQTT command to IoT
- ✅ UI JSON files stored in S3 and served to Flutter app
- ✅ CI/CD working: backend auto-deploys via GitHub Actions, frontend via Amplify Hosting
- ✅ Multi-environment support (dev/prod) with environment-specific resource naming

---

### 1. *Authentication UI*
- [ ] Create login/signup screen using Amplify.Auth
- [ ] Enable session persistence and check current user on app launch

### 2. *UI Fetch and Rendering*
- [ ] Query AppSync getUiPage and download JSON from S3
- [ ] Render Flutter widgets based on layout definition

### 3. *Device Control*
- [ ] Implement device control buttons linked to GraphQL controlDevice
- [ ] Validate that mutation sends correct MQTT message via Lambda to IoT Core

### 4. *Subscriptions*
- [ ] Implement real-time onDeviceStateChanged subscription in Flutter
- [ ] Reflect device state updates immediately in UI (e.g., button toggle, sensor readout)

### 5. *Custom Domain*
- [ ] Connect ak.lifewire.com to Amplify Hosting via DNS settings

### 6. *Production Readiness*
- [ ] Add user-specific UI and devices via Cognito identity
- [ ] Encrypt SSM parameters and secrets
- [ ] Add monitoring (CloudWatch), logging, and error handling

---

## Stack Summary
| Stack               | Description                                      |
|---------------------|--------------------------------------------------|
| AuthStack           | Cognito for user login/signup                    |
| LambdaStack         | Business logic (get UI, control device)          |
| IoTStack            | MQTT messaging with AWS IoT Core                 |
| AppSyncStack        | GraphQL API with queries, mutations, subscriptions |
| StorageStack        | S3 bucket to store dynamic UI JSON               |
| AmplifyHostingStack | Hosts the Flutter web application               |

---

## Tech Stack
- *Frontend:* Flutter Web, Amplify Hosting
- *Backend:* AWS CDK (TypeScript), AWS Lambda, AppSync, IoT Core, Cognito, S3, SSM
- *CI/CD:* GitHub Actions for environment-specific deployments (dev/prod)

---

## Contact / Author
- *GitHub:* [AKlifewire](https://github.com/AKlifewire)
- *Domain:* [ak.lifewire.com](https://ak.lifewire.com)
=======
# Smart Home IoT Platform

This repository contains a complete smart home IoT platform built with AWS services and Flutter.

## Architecture

The platform consists of the following components:

- **Frontend**: Flutter app for web and mobile
- **Authentication**: AWS Cognito
- **API**: AWS AppSync (GraphQL) and API Gateway (REST)
- **Database**: DynamoDB
- **IoT**: AWS IoT Core
- **Storage**: S3
- **Analytics**: Timestream
- **Hosting**: AWS Amplify
- **Edge Computing**: AWS Greengrass
- **Digital Twin**: AWS TwinMaker
- **Payments**: Stripe integration

## Getting Started

### Prerequisites

- Flutter SDK
- AWS CLI configured with appropriate credentials
- Git

### Setup

1. Run the dependency checker:
   ```
   check-dependencies.bat
   ```

2. Launch the platform:
   ```
   launch-platform.bat
   ```

This will:
- Update the AWS configuration with the latest stack outputs
- Launch the Flutter app in Chrome

### Using the Platform

1. **Login**: Use your Cognito credentials to log in
2. **Add Devices**: Click the + button to add a new device
   - Scan a QR code or enter device details manually
3. **Control Devices**: Tap on a device to view its controls
   - The UI is dynamically generated based on the device type
4. **Monitor**: View real-time data from your devices

## Device Provisioning

Devices connect to AWS IoT Core using the following endpoint:
```
a3rbulpildf8ig-ats.iot.us-east-1.amazonaws.com
```

The provisioning template `SmartHomeProvisioningTemplate-dev` is used to automatically register devices.

## Key Endpoints

- **GraphQL API**: https://m3kglrtcvfhwfp4mngf6tzqcn4.appsync-api.us-east-1.amazonaws.com/graphql
- **Device Registration API**: https://7jp1vhved6.execute-api.us-east-1.amazonaws.com/prod/
- **Payment API**: https://bnlpk8fq10.execute-api.us-east-1.amazonaws.com/dev/
- **Web App**: https://d3g783pol7yev2.amplifyapp.com

## Development

### Project Structure

- `smart_home_iot/`: Flutter app
  - `lib/models/`: Data models
  - `lib/providers/`: State management
  - `lib/screens/`: UI screens
  - `lib/services/`: API services
  - `lib/widgets/`: Reusable UI components

- `cdk/`: AWS CDK infrastructure code
  - `stacks/`: CDK stack definitions
  - `lambda/`: Lambda functions

### Adding New Device Types

1. Create a device configuration in the UI JSON format
2. The platform will automatically generate a UI for the device

### Customizing the UI

The UI is dynamically generated based on the device type. You can customize the UI by modifying the UI JSON files in the `ui-json` directory.

## Troubleshooting

If you encounter any issues:

1. Check the AWS configuration in `smart_home_iot/assets/config/aws_config.json`
2. Verify that all AWS services are properly deployed
3. Check the Flutter app logs for errors

## License

This project is licensed under the MIT License - see the LICENSE file for details.
>>>>>>> Stashed changes
