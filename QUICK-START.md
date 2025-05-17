# AK Smart Home Platform - Quick Start Guide

## Development Environment Setup

1. **Clone the repository**
   ```
   git clone https://github.com/AKlifewire/home.git
   cd home
   ```

2. **Install dependencies**
   ```
   npm install
   ```

3. **Create Lambda asset folders**
   ```
   mkdir -p dist/lambdas/resolvers
   mkdir -p dist/lambdas/automation
   mkdir -p dist/lambdas/iot
   mkdir -p dist/lambdas/stripe
   ```

4. **Create placeholder Lambda files**
   ```
   echo "// placeholder" > dist/lambdas/resolvers/index.js
   echo "// placeholder" > dist/lambdas/automation/index.js
   echo "// placeholder" > dist/lambdas/iot/index.js
   echo "// placeholder" > dist/lambdas/stripe/index.js
   ```

## Quick Deployment

### Option 1: Using the deployment scripts

For development environment:
```
cd scripts
.\deploy-dev.bat
```

For a safer deployment with verification:
```
cd scripts
.\deploy-safe.bat dev
```

### Option 2: Manual CDK commands

From the project root directory:
```
# Synthesize CloudFormation template
npx cdk synth -c env=dev

# Deploy all stacks
npx cdk deploy --all --require-approval never -c env=dev
```

## Troubleshooting

### Common Issues

1. **CDK synthesis fails with "--app is required"**
   - Make sure you're running the command from the project root directory (where cdk.json is located)
   - The scripts in the scripts folder need to navigate to the parent directory first

2. **Missing Lambda asset folders**
   - Run the folder creation commands listed above
   - Or use the deploy-dev.bat script which creates these folders automatically

3. **Resource name collisions**
   - Make sure you're using the environment parameter: `-c env=dev` or `-c env=prod`
   - Check that all resources in your stacks use the envName parameter

4. **AWS credentials issues**
   - Run `aws configure` to set up your credentials
   - Verify with `aws sts get-caller-identity`

## Next Steps

After successful deployment:
1. Check the AWS Console to verify all resources were created
2. Test the Amplify Hosting URL
3. Connect your Flutter app to the backend
4. Test authentication and device control