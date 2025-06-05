# Amplify Hosting Setup Instructions

## Overview
The AmplifyHostingStack is configured to connect to a separate GitHub repository containing your Flutter application. This allows for automatic deployments when you push changes to your Flutter app repository.

## Prerequisites
1. Create a GitHub repository for your Flutter app (if not already created)
2. Store your GitHub personal access token in AWS Secrets Manager:
   ```
   aws secretsmanager create-secret --name github-token --secret-string "your-github-token"
   ```

## Configuration Steps
1. Update the AmplifyHostingStack.ts file with your GitHub information:
   ```typescript
   sourceCodeProvider: new amplify.GitHubSourceCodeProvider({
     owner: 'your-github-username', // Replace with your GitHub username
     repository: 'smart-home-flutter', // Replace with your Flutter repo name
     oauthToken: cdk.SecretValue.secretsManager('github-token')
   }),
   ```

2. Deploy the updated AmplifyHostingStack:
   ```
   npx cdk deploy dev-AmplifyHostingStack
   ```

3. After deployment, go to the Amplify Console URL (available in the stack outputs) to verify the connection.

## Workflow
1. Push changes to the `develop` branch of your Flutter repository to deploy to the development environment
2. Push changes to the `main` branch of your Flutter repository to deploy to the production environment
3. Amplify will automatically build and deploy your Flutter web app

## Troubleshooting
- If the build fails, check the build logs in the Amplify Console
- Ensure your Flutter repository has the correct structure expected by the build specification
- Verify that the GitHub token has the necessary permissions