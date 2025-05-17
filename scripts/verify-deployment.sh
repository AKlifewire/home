#!/bin/bash
# Comprehensive verification script for AK Smart Home Platform
# Run this before deploying to production

set -e  # Exit on any error

ENV_NAME=${1:-dev}
echo "🔍 Verifying $ENV_NAME environment deployment..."

# 1. Check AWS credentials
echo "✅ Checking AWS credentials..."
aws sts get-caller-identity

# 2. Verify CDK synth works without errors
echo "✅ Verifying CDK synthesis..."
npx cdk synth -c env=$ENV_NAME

# 3. Check for drift in deployed stacks
echo "✅ Checking for infrastructure drift..."
npx cdk diff -c env=$ENV_NAME

# 4. Verify all required stacks exist
echo "✅ Verifying stack existence..."
STACKS=(
  "AuthStack-$ENV_NAME"
  "LambdaStack-$ENV_NAME"
  "IoTStack-$ENV_NAME"
  "AppSyncStack-$ENV_NAME"
  "StorageStack-$ENV_NAME"
  "AmplifyHostingStack-$ENV_NAME"
)

for stack in "${STACKS[@]}"; do
  aws cloudformation describe-stacks --stack-name $stack --query "Stacks[0].StackName" || {
    echo "❌ Stack $stack not found!"
    exit 1
  }
  echo "✓ Stack $stack exists"
done

# 5. Verify Cognito resources
echo "✅ Verifying Cognito resources..."
USER_POOL_ID=$(aws ssm get-parameter --name "/auth/AuthStack-$ENV_NAME/userPoolId" --query "Parameter.Value" --output text || echo "NOT_FOUND")
if [ "$USER_POOL_ID" == "NOT_FOUND" ]; then
  echo "❌ User Pool ID not found in SSM!"
  exit 1
fi
echo "✓ User Pool ID: $USER_POOL_ID"

# 6. Verify AppSync API
echo "✅ Verifying AppSync API..."
GRAPHQL_URL=$(aws ssm get-parameter --name "/appsync/AppSyncStack-$ENV_NAME/api-url" --query "Parameter.Value" --output text || echo "NOT_FOUND")
if [ "$GRAPHQL_URL" == "NOT_FOUND" ]; then
  echo "❌ GraphQL API URL not found in SSM!"
  exit 1
fi
echo "✓ GraphQL API URL: $GRAPHQL_URL"

# 7. Verify Lambda functions
echo "✅ Verifying Lambda functions..."
LAMBDA_FUNCTIONS=(
  "get-ui-page"
  "control-device"
  "get-analytics"
)

for func in "${LAMBDA_FUNCTIONS[@]}"; do
  LAMBDA_NAME="SmartHomeApp-$ENV_NAME-lambda-$func"
  aws lambda get-function --function-name $LAMBDA_NAME --query "Configuration.FunctionName" || {
    echo "❌ Lambda function $LAMBDA_NAME not found!"
    exit 1
  }
  echo "✓ Lambda function $LAMBDA_NAME exists"
done

# 8. Verify S3 bucket
echo "✅ Verifying S3 bucket..."
S3_BUCKET="your-ui-pages-bucket-name-$ENV_NAME"
aws s3api head-bucket --bucket $S3_BUCKET || {
  echo "❌ S3 bucket $S3_BUCKET not found!"
  exit 1
}
echo "✓ S3 bucket $S3_BUCKET exists"

# 9. Verify Amplify app
echo "✅ Verifying Amplify app..."
AMPLIFY_APP_ID=$(aws cloudformation describe-stacks --stack-name "AmplifyHostingStack-$ENV_NAME" --query "Stacks[0].Outputs[?OutputKey=='AmplifyAppUrl-$ENV_NAME'].OutputValue" --output text || echo "NOT_FOUND")
if [ "$AMPLIFY_APP_ID" == "NOT_FOUND" ]; then
  echo "❌ Amplify App ID not found in CloudFormation outputs!"
  exit 1
fi
echo "✓ Amplify App ID: $AMPLIFY_APP_ID"

echo "✅ All verification checks passed for $ENV_NAME environment!"
echo "You can safely deploy to production."