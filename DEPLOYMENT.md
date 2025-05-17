# AK Smart Home Platform - Deployment Guide

## Pre-Deployment Verification

Before deploying to production, always verify your development environment first:

1. Run the verification script:
   ```
   cd scripts
   .\verify-deployment.bat dev
   ```

2. Check for any errors or warnings in the output.

3. Fix any issues before proceeding to production deployment.

## Safe Deployment Process

### Local Deployment

Use the safe deployment script which includes verification steps:

```
cd scripts
.\deploy-safe.bat dev    # For development environment
.\deploy-safe.bat prod   # For production environment
```

### GitHub Actions Deployment

#### Development Environment

The dev environment automatically deploys when changes are pushed to the `dev` branch.

You can also manually trigger a deployment:
1. Go to GitHub Actions
2. Select "Deploy Dev CDK Stacks" workflow
3. Click "Run workflow"
4. Enter "deploy" in the confirmation field
5. Click "Run workflow"

#### Production Environment

Production deployment requires manual confirmation:

1. Go to GitHub Actions
2. Select "Deploy Prod Stack" workflow
3. Click "Run workflow"
4. Enter "deploy-prod" in the confirmation field
5. Click "Run workflow"

## Environment-Specific Resources

All resources are created with environment-specific names to avoid collisions:

- Stack names: `StackName-${envName}`
- Resource names: `ResourceName-${envName}`
- Export names: `ExportName-${envName}`

## Troubleshooting

If deployment fails:

1. Check CloudFormation events in AWS Console
2. Look for specific error messages in the GitHub Actions logs
3. Verify that all required environment variables are set
4. Ensure AWS credentials have sufficient permissions
5. Check for resource name conflicts

Common issues:
- Missing Lambda asset folders
- Resource name collisions between environments
- Insufficient IAM permissions
- Missing or invalid SSM parameters

## Rollback Procedure

If you need to roll back a deployment:

1. Use CloudFormation to roll back to the previous stack version
2. Or deploy a specific previous commit:
   ```
   git checkout <previous-commit-hash>
   cd scripts
   .\deploy-safe.bat <env>
   ```