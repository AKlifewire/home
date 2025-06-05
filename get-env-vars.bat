@echo off
REM Script to extract environment variables from deployed AWS stack

REM Check if stack name is provided as argument
if "%1"=="" (
  set STACK_NAME=dev
) else (
  set STACK_NAME=%1
)

echo Extracting environment variables from stack: %STACK_NAME%
node get-env-vars.js

echo Done! Check the .env file for the extracted variables.