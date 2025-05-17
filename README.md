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