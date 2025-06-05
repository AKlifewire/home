#!/bin/bash
# End-to-end test script for the dynamic UI system

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '#' | xargs)
else
  echo "⚠️ .env file not found. Please create one based on .env.example"
  exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "📦 Installing dependencies..."
  npm install aws-sdk uuid node-fetch
fi

# Run the validation script
echo "🚀 Running end-to-end test..."
node lambda/validate_backend_config.js