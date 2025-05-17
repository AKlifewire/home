# Deployment Issues and Solutions

## Common Issues

### 1. S3 Bucket Name Collision

**Issue:** The error `your-ui-pages-bucket-name-dev already exists in stack` occurs when the same bucket name is used across environments.

**Solution:** 
- Updated `StorageStack.ts` to use a unique bucket name per environment:
  ```typescript
  bucketName: `smart-home-ui-pages-${envName}-${this.account}`
  ```
- This ensures each environment has its own bucket with a unique name that includes:
  - The environment name (dev/prod)
  - The AWS account ID

### 2. Failed Stack Cleanup

**Issue:** When a stack deployment fails, it remains in ROLLBACK_COMPLETE state and blocks future deployments.

**Solution:**
- Created an improved deployment script that:
  - Checks for stacks in ROLLBACK_COMPLETE state
  - Deletes these failed stacks before attempting deployment
  - Waits for deletion to complete

### 3. CDK Synthesis Path Issues

**Issue:** Running CDK commands from subdirectories fails with `--app is required`.

**Solution:**
- Updated deployment scripts to always change to the project root directory first:
  ```batch
  cd ..
  ```
- This ensures CDK can find the `cdk.json` file

## Environment-Specific Resources

All resources should have environment-specific names to avoid collisions:

1. **Stack Names**: `StackName-${envName}`
2. **Resource Names**: Include the environment name in all resource names
3. **S3 Buckets**: Must have globally unique names
4. **Export Names**: Must be unique within an AWS account

## Best Practices

1. **Always run verification first**:
   ```
   npx cdk synth -c env=prod
   npx cdk diff -c env=prod
   ```

2. **Clean up failed deployments**:
   ```
   aws cloudformation delete-stack --stack-name FailedStack-prod
   ```

3. **Use the improved deployment scripts**:
   ```
   cd scripts
   .\deploy-prod.bat
   ```

4. **Check CloudFormation console** for detailed error messages if deployment fails