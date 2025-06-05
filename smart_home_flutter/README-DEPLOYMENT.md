# Smart Home Flutter App Deployment Guide

This guide explains how to deploy the Smart Home Flutter app to AWS Amplify Hosting.

## Prerequisites

1. AWS Account with appropriate permissions
2. GitHub repository with the Flutter app code
3. AWS Amplify Hosting app created via CDK (AmplifyHostingStack)

## GitHub Secrets Setup

The following secrets need to be configured in your GitHub repository:

- `AWS_ACCESS_KEY_ID`: AWS access key with permissions to deploy to Amplify
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `AWS_REGION`: AWS region where your Amplify app is deployed (e.g., us-east-1)
- `AMPLIFY_APP_ID`: ID of your Amplify app (from CDK output)
- `USER_POOL_ID`: Cognito User Pool ID
- `USER_POOL_CLIENT_ID`: Cognito User Pool Client ID
- `IDENTITY_POOL_ID`: Cognito Identity Pool ID
- `API_ENDPOINT`: AppSync GraphQL API endpoint

## Deployment Process

The deployment process is automated using GitHub Actions:

1. When code is pushed to the `main` branch, the workflow is triggered
2. Tests are run to ensure code quality
3. The Flutter web app is built with production configuration
4. The build is deployed to AWS Amplify Hosting

## Manual Deployment

To trigger a deployment manually:

1. Go to the "Actions" tab in your GitHub repository
2. Select the "Flutter Web Build and Deploy to Amplify" workflow
3. Click "Run workflow" and select the branch to deploy

## Verifying Deployment

After deployment:

1. Check the GitHub Actions logs for any errors
2. Visit the Amplify Console to see deployment status
3. Test the deployed app at the Amplify-provided URL

## Troubleshooting

If deployment fails:

1. Check GitHub Actions logs for specific errors
2. Verify that all required secrets are correctly configured
3. Ensure the Amplify app ID is correct
4. Check that the AWS credentials have sufficient permissions

## Authentication Testing

To verify that authentication is working correctly:

1. Try to sign up a new user
2. Confirm the user with the verification code
3. Sign in with the new user credentials
4. Test password reset functionality
5. Verify that protected resources are accessible after login

## API Integration Testing

To verify API integration:

1. Sign in to the app
2. Check that device data is loaded correctly
3. Test device control functionality
4. Verify that real-time updates work via subscriptions