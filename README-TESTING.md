# Smart Home IoT Platform - E2E Testing Guide

## 🧪 Comprehensive Testing Suite

This testing suite provides complete end-to-end validation of your Smart Home IoT Platform from authentication to device control.

## 🚀 Quick Start

### Run All Production Tests
```bash
# Run complete test suite
powershell -ExecutionPolicy Bypass -File "run-production-tests.ps1"

# Run for specific environment
powershell -ExecutionPolicy Bypass -File "run-production-tests.ps1" -EnvName "prod"

# Skip frontend tests (faster)
powershell -ExecutionPolicy Bypass -File "run-production-tests.ps1" -SkipFrontend
```

## 📋 Test Categories

### 1. **Backend API Integration Tests**
- ✅ AppSync GraphQL API connectivity
- ✅ Lambda function accessibility
- ✅ Device registration API
- ✅ UI layout generation API
- ✅ IoT Core connectivity

### 2. **Full E2E Integration Tests**
- ✅ User authentication flow (Cognito)
- ✅ Device registration via IoT Core
- ✅ UI layout generation via Lambda
- ✅ Device control simulation
- ✅ Frontend accessibility

### 3. **Frontend E2E Tests** (Optional)
- ✅ Login flow automation
- ✅ Dashboard navigation
- ✅ Device interaction
- ✅ Responsive design
- ✅ Performance testing

## 🔧 Individual Test Execution

### Backend API Tests
```bash
cd tests
node api-integration.test.js
```

### Full E2E Tests
```bash
cd tests
node e2e-integration.test.js
```

### Frontend Tests (requires browser)
```bash
cd tests
node frontend-e2e.test.js
```

## 📊 Test Coverage

| Component | Test Type | Coverage |
|-----------|-----------|----------|
| Authentication | E2E | ✅ Signup, Login, Token validation |
| Device Management | Integration | ✅ Registration, IoT Thing creation |
| UI Generation | API | ✅ Dynamic layout creation |
| Device Control | Simulation | ✅ MQTT command simulation |
| Frontend | E2E | ✅ User flows, responsiveness |
| Performance | Load | ✅ Page load times, API response |

## 🛠️ Prerequisites

### Required Tools
- **Node.js** 16+ 
- **AWS CLI** configured with appropriate permissions
- **PowerShell** 5.1+ (Windows) or **Bash** (Linux/Mac)

### AWS Permissions Required
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "cognito-idp:*",
        "iot:*",
        "lambda:InvokeFunction",
        "lambda:GetFunction"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🎯 Test Scenarios

### Authentication Flow
1. Create test user in Cognito
2. Set permanent password
3. Authenticate and get tokens
4. Validate token structure

### Device Registration
1. Create IoT Thing
2. Register device via API
3. Validate device in DynamoDB
4. Test device queries

### UI Generation
1. Request UI layout for device type
2. Validate JSON schema
3. Test dynamic component generation
4. Verify responsive layouts

### Device Control
1. Simulate MQTT commands
2. Test state updates
3. Validate real-time sync
4. Check error handling

### Frontend Integration
1. Load application
2. Test login flow
3. Navigate dashboard
4. Interact with devices
5. Test responsive design

## 📈 Performance Benchmarks

| Metric | Target | Measured |
|--------|--------|----------|
| Page Load Time | < 3s | Measured during test |
| API Response Time | < 500ms | Measured during test |
| Authentication Time | < 2s | Measured during test |
| Device Registration | < 1s | Measured during test |

## 🔍 Troubleshooting

### Common Issues

**AWS CLI Not Configured**
```bash
aws configure
# Enter your AWS credentials
```

**Missing Dependencies**
```bash
cd tests
npm install
```

**Permission Denied**
```bash
# Windows
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass
powershell -ExecutionPolicy Bypass -File "run-production-tests.ps1"
```

**Frontend Tests Failing**
- Ensure your Amplify app is deployed and accessible
- Check if the domain is correct in SSM parameters
- Verify CORS settings are properly configured

### Debug Mode
```bash
# Run with verbose output
powershell -ExecutionPolicy Bypass -File "run-production-tests.ps1" -Verbose
```

## 📝 Test Reports

Tests generate detailed console output with:
- ✅ **Pass/Fail status** for each test
- 📊 **Performance metrics**
- 🔍 **Detailed error messages**
- 📈 **Summary statistics**

## 🚀 CI/CD Integration

### GitHub Actions Example
```yaml
name: E2E Tests
on: [push, pull_request]
jobs:
  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - name: Run E2E Tests
        run: |
          cd tests
          npm install
          node e2e-integration.test.js
```

## 🎉 Success Criteria

Your Smart Home IoT Platform is **production-ready** when:
- ✅ All authentication flows work
- ✅ Device registration completes successfully
- ✅ UI layouts generate correctly
- ✅ Frontend loads and responds properly
- ✅ Performance meets benchmarks
- ✅ No critical errors in logs

Run the tests regularly to ensure your platform maintains production quality! 🚀