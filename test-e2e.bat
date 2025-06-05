@echo off
REM End-to-end test script for the dynamic UI system (Windows version)

REM Check if .env file exists
if not exist .env (
  echo Warning: .env file not found. Please create one based on .env.example
  exit /b 1
)

REM Set the IoT endpoint directly
set IOT_ENDPOINT=a360bvzvgaaupj-ats.iot.us-east-1.amazonaws.com

REM Load environment variables
for /f "tokens=*" %%a in (.env) do (
  set %%a
)

REM Install dependencies if needed
if not exist node_modules (
  echo Installing dependencies...
  npm install aws-sdk uuid node-fetch
)

REM Run the validation script
echo Running end-to-end test...
node lambda\validate_backend_config.js