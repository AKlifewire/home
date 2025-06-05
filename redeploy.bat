@echo off
echo Starting backend redeployment and frontend connection...

REM Deploy the CDK stacks
echo Deploying backend infrastructure...
call npx cdk deploy --all --require-approval never

REM Get the SSM parameters needed for frontend configuration
echo Retrieving configuration parameters...
call node get-ssm-params.js

REM Update the frontend configuration
echo Updating frontend configuration...
call node update-frontend-config.js

echo Redeployment complete! Your backend has been redeployed and connected to the frontend.