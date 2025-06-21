import * as cdk from 'aws-cdk-lib';
import { AuthStack } from './stacks/AuthStack';
import { StorageStack } from './stacks/StorageStack';
import { IoTStack } from './stacks/IoTStack';
import { UiJsonStack } from './stacks/UiJsonStack';
import { PaymentStack } from './stacks/PaymentStack';
import { TwinMakerStack } from './stacks/TwinMakerStack';
import { GreengrassStack } from './stacks/GreengrassStack';
import { AnalyticsStack } from './stacks/AnalyticsStack';
import { AppSyncStack } from './stacks/AppSyncStack';
import { AmplifyHostingStack } from './stacks/AmplifyHostingStack';
import { DeviceRegistrationStack } from './stacks/DeviceRegistrationStack';

const app = new cdk.App();

// Environment configuration
const env = { 
  account: process.env.CDK_DEFAULT_ACCOUNT, 
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1'
};

// Stack configuration
const appName = 'SmartHome';
const envName = process.env.ENV_NAME || 'dev';
const domainName = process.env.DOMAIN_NAME || 'smarthome.example.com';

// Base stack props
const baseProps = {
  env,
  tags: {
    Environment: envName,
    Project: appName,
  },
};

// 1. Auth Stack
const authStack = new AuthStack(app, `${envName}-AuthStack`, {
  ...baseProps,
  appName,
  envName,
});

// 2. Storage Stack
const storageStack = new StorageStack(app, `${envName}-StorageStack`, {
  ...baseProps,
  envName,
});

// 3. Device Registration Stack
const deviceRegistrationStack = new DeviceRegistrationStack(app, `${envName}-DeviceRegistrationStack`, {
  ...baseProps,
  envName,
  userPool: authStack.userPool,
  devicesTable: storageStack.devicesTable,
});

// 4. IoT Stack
const iotStack = new IoTStack(app, `${envName}-IoTStack`, {
  ...baseProps,
  envName,
});

// 5. UI JSON Stack
const uiJsonStack = new UiJsonStack(app, `${envName}-UiJsonStack`, {
  ...baseProps,
  envName,
  devicesTable: storageStack.devicesTable,
});

// 6. AppSync Stack
const appSyncStack = new AppSyncStack(app, `${envName}-AppSyncStack`, {
  ...baseProps,
  userPool: authStack.userPool,
  lambdaStack: {
    uiJsonHandler: uiJsonStack.uiJsonLambda,
    batchGetDeviceUIs: uiJsonStack.uiJsonLambda,
  },
});

// 7. Payment Stack
const paymentStack = new PaymentStack(app, `${envName}-PaymentStack`, {
  ...baseProps,
  envName,
  userPoolId: authStack.userPoolId,
});

// 8. TwinMaker Stack
const twinMakerStack = new TwinMakerStack(app, `${envName}-TwinMakerStack`, {
  ...baseProps,
  envName,
});

// 9. Greengrass Stack
const greengrassStack = new GreengrassStack(app, `${envName}-GreengrassStack`, {
  ...baseProps,
  envName,
});

// 10. Analytics Stack
const analyticsStack = new AnalyticsStack(app, `${envName}-AnalyticsStack`, {
  ...baseProps,
  envName,
});

// 11. Amplify Hosting Stack
const amplifyStack = new AmplifyHostingStack(app, `${envName}-AmplifyHostingStack`, {
  ...baseProps,
  envName,
  domainName,
});

app.synth();