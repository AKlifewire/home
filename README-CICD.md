# CI/CD Setup for Smart Home IoT Platform

This document describes the Continuous Integration and Continuous Deployment (CI/CD) setup for the Smart Home IoT Platform.

## Overview

The CI/CD pipeline is implemented using GitHub Actions and consists of the following workflows:

1. **Backend CI/CD**: Tests and deploys the AWS CDK infrastructure
2. **Flutter CI/CD**: Tests and deploys the Flutter application
3. **Integration Tests**: Runs end-to-end tests on the entire platform

## Prerequisites

Before using the CI/CD pipeline, you need to set up the following:

1. **GitHub Repository**: Push your code to a GitHub repository
2. **GitHub Secrets**: Configure the following secrets in your repository:
   - `AWS_ACCESS_KEY_ID`: AWS access key with permissions to deploy resources
   - `AWS_SECRET_ACCESS_KEY`: AWS secret key
   - `AWS_REGION`: AWS region to deploy to (e.g., `us-east-1`)
   - `WEB_BUCKET`: S3 bucket name for web deployment
   - `CLOUDFRONT_ID`: CloudFront distribution ID for web deployment

## Workflow Details

### Backend CI/CD (`backend-ci-cd.yml`)

This workflow handles the AWS CDK infrastructure:

- **Trigger**: Runs on push to `main` branch or manual trigger
- **Jobs**:
  - **Test**: Runs linting and unit tests
  - **Deploy to Dev**: Deploys to the development environment
  - **Deploy to Prod**: Deploys to the production environment (manual trigger only)

### Flutter CI/CD (`flutter-ci-cd.yml`)

This workflow handles the Flutter application:

- **Trigger**: Runs on push to `main` branch or manual trigger
- **Jobs**:
  - **Test**: Runs Flutter tests and builds the web app
  - **Integration Test**: Runs Flutter integration tests
  - **Deploy Web**: Deploys the web app to S3 and invalidates CloudFront
  - **Build Android**: Builds the Android APK

### Integration Tests (`integration-test.yml`)

This workflow runs end-to-end tests on the entire platform:

- **Trigger**: Runs on push to `main` branch, daily schedule, or manual trigger
- **Jobs**:
  - **E2E Test**: Runs end-to-end tests
  - **Device Simulation**: Tests device simulation
  - **UI Generation Test**: Tests UI generation from device configs

## Environment Setup

The CI/CD pipeline uses different environments for development and production:

- **Development**: Used for testing and development
- **Production**: Used for production deployment

Each environment has its own AWS resources and configuration.

## Scripts

The following scripts are used in the CI/CD pipeline:

- **`update-frontend-config.js`**: Updates the Flutter app configuration with values from AWS SSM Parameter Store
- **`setup-test-env.js`**: Sets up a test environment for integration tests

## Running Locally

You can run the CI/CD scripts locally for testing:

```bash
# Set up test environment
npm run setup:test

# Run tests
npm test
npm run test:e2e
npm run test:ui-generation
npm run test:device-simulation

# Deploy to development
npm run deploy:dev

# Deploy to production
npm run deploy:prod
```

## Deployment Process

1. Push changes to the `main` branch
2. GitHub Actions automatically runs tests
3. If tests pass, changes are deployed to the development environment
4. To deploy to production, manually trigger the workflow with environment=prod

## Monitoring

You can monitor the CI/CD pipeline in the GitHub Actions tab of your repository. Each workflow run shows the status of each job and any errors that occurred.