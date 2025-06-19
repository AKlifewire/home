<<<<<<< Updated upstream
// Entry point for CDK stack deployment
=======
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
import { SSM_PATHS } from './utils/param-paths';

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
const gitHubToken = cdk.SecretValue.secretsManager('github-token');

// Base stack props
const baseProps = {
  env,
  tags: {
    Environment: envName,
    Project: appName,
  },
};

// 1. Auth Stack - No dependencies
const authStack = new AuthStack(app, `${envName}-AuthStack`, {
  ...baseProps,
  appName,
  envName,
});

// 2. Storage Stack - No dependencies
const storageStack = new StorageStack(app, `${envName}-StorageStack`, {
  ...baseProps,
  environment: envName,
});

// 3. Device Registration Stack - Depends on Auth and Storage
const deviceRegistrationStack = new DeviceRegistrationStack(app, `${envName}-DeviceRegistrationStack`, {
  ...baseProps,
  envName,
  userPool: authStack.userPool,
  devicesTable: storageStack.devicesTable,
});

// 4. IoT Stack - Depends on Device Registration
const iotStack = new IoTStack(app, `${envName}-IoTStack`, {
  ...baseProps,
  envName,
  deviceRegistrationLambda: deviceRegistrationStack.deviceRegistrationLambda,
});

// 5. UI JSON Stack - Depends on Storage
const uiJsonStack = new UiJsonStack(app, `${envName}-UiJsonStack`, {
  ...baseProps,
  envName,
  devicesTable: storageStack.devicesTable,
});

// 6. AppSync Stack - Depends on Auth and UI JSON
const appSyncStack = new AppSyncStack(app, `${envName}-AppSyncStack`, {
  ...baseProps,
  userPool: authStack.userPool,
  lambdaStack: {
    uiJsonHandler: uiJsonStack.uiJsonLambda,
    batchGetDeviceUIs: uiJsonStack.uiJsonLambda,
  },
});

// 7. Payment Stack - Depends on Auth
const paymentStack = new PaymentStack(app, `${envName}-PaymentStack`, {
  ...baseProps,
  envName,
  userPoolId: authStack.userPoolId,
});

// 8. TwinMaker Stack - Depends on IoT
const twinMakerStack = new TwinMakerStack(app, `${envName}-TwinMakerStack`, {
  ...baseProps,
  envName,
});

// 9. Greengrass Stack - Depends on IoT
const greengrassStack = new GreengrassStack(app, `${envName}-GreengrassStack`, {
  ...baseProps,
  envName,
});

// 10. Analytics Stack - Depends on IoT
const analyticsStack = new AnalyticsStack(app, `${envName}-AnalyticsStack`, {
  ...baseProps,
  envName,
});

// 11. Amplify Hosting Stack - Frontend hosting
const amplifyStack = new AmplifyHostingStack(app, `${envName}-AmplifyHostingStack`, {
  ...baseProps,
  envName,
  domainName,
});

// Add explicit dependencies
deviceRegistrationStack.addDependency(authStack);
deviceRegistrationStack.addDependency(storageStack);
iotStack.addDependency(deviceRegistrationStack);
uiJsonStack.addDependency(storageStack);
paymentStack.addDependency(authStack);
appSyncStack.addDependency(authStack);
appSyncStack.addDependency(uiJsonStack);
twinMakerStack.addDependency(iotStack);
greengrassStack.addDependency(iotStack);
analyticsStack.addDependency(iotStack);

app.synth();
>>>>>>> Stashed changes
