#!/bin/bash

echo "Starting backend redeployment and frontend connection..."

# Deploy the CDK stacks
echo "Deploying backend infrastructure..."
npx cdk deploy --all --require-approval never

# Get the SSM parameters needed for frontend configuration
echo "Retrieving configuration parameters..."
node get-ssm-params.js

# Update the frontend configuration
echo "Updating frontend configuration..."
node update-frontend-config.js

echo "Redeployment complete! Your backend has been redeployed and connected to the frontend."