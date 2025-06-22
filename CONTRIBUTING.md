# Contributing to Smart Home IoT Platform

## Development Setup

### Prerequisites
- Node.js 18+
- AWS CLI configured with appropriate permissions
- Flutter SDK 3.0+
- CDK CLI: `npm install -g aws-cdk`

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/[username]/smart-home-iot-platform.git
   cd smart-home-iot-platform
   ```

2. **Install dependencies**
   ```bash
   npm install
   cd frontend && flutter pub get
   ```

3. **Deploy backend (development)**
   ```bash
   powershell -ExecutionPolicy Bypass -File "scripts\deploy-all-stacks.ps1" -EnvName "dev"
   ```

4. **Run frontend locally**
   ```bash
   cd frontend
   flutter run -d chrome
   ```

## Project Structure

- `cdk/` - AWS CDK infrastructure code
- `frontend/` - Flutter web application
- `lambda/` - Lambda function source code
- `scripts/` - Deployment and utility scripts
- `ui-json/` - UI layout templates

## Making Changes

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Test locally
4. Commit with conventional commits: `git commit -m "feat: add new feature"`
5. Push and create a pull request

## Commit Convention

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Test additions/changes
- `chore:` - Build process or auxiliary tool changes