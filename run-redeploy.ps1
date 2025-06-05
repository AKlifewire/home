Write-Host "Starting backend redeployment and frontend connection..."

# Deploy the CDK stacks
Write-Host "Deploying backend infrastructure..."
npx cdk deploy --all --require-approval never

# Get the SSM parameters needed for frontend configuration
Write-Host "Retrieving configuration parameters..."
node get-ssm-params.js

# Update the frontend configuration
Write-Host "Updating frontend configuration..."
node update-frontend-config.js

Write-Host "Redeployment complete! Your backend has been redeployed and connected to the frontend."