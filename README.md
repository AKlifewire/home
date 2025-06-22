# Smart Home IoT Platform

A full-stack IoT platform for managing smart home devices with real-time control and dynamic UI generation.

## 🏗️ Architecture

- **Backend**: AWS CDK with 9 serverless stacks
- **Frontend**: Flutter web application
- **Database**: DynamoDB for device data
- **Real-time**: IoT Core with MQTT
- **API**: AppSync GraphQL
- **Auth**: Cognito User Pools
- **Hosting**: Amplify Hosting

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- AWS CLI configured
- Flutter SDK
- CDK CLI

### Backend Deployment
```bash
# Install dependencies
npm install

# Deploy all stacks
powershell -ExecutionPolicy Bypass -File "scripts\deploy-all-stacks.ps1" -EnvName "dev"
```

### Frontend Deployment
```bash
# Build and deploy frontend
powershell -ExecutionPolicy Bypass -File "scripts\build-flutter-with-ssm.ps1" -EnvName "dev"

# Upload frontend-dev.zip to Amplify Console
```

## 📦 Project Structure

```
├── cdk/                    # CDK infrastructure code
│   ├── stacks/            # CDK stack definitions
│   └── utils/             # Shared utilities
├── frontend/              # Flutter web application
│   ├── lib/               # Dart source code
│   └── web/               # Web assets
├── lambda/                # Lambda function code
├── scripts/               # Deployment scripts
└── ui-json/               # UI layout templates
```

## 🔧 Key Features

- **Dynamic UI Generation**: Automatic UI creation based on device types
- **Real-time Control**: MQTT-based device communication
- **User Management**: Secure authentication with Cognito
- **Scalable Architecture**: Serverless AWS infrastructure
- **Multi-platform**: Web and mobile support

## 🌐 Live Demo

Access your deployed platform at: `https://[your-amplify-domain].amplifyapp.com`

## 📚 Documentation

- [Deployment Guide](PLATFORM_LAUNCH_GUIDE.md)
- [Architecture Overview](DEPLOYMENT.md)
- [Quick Start](QUICK-START.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.