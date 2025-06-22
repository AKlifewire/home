import * as cdk from 'aws-cdk-lib';
import { AuthStack } from './stacks/AuthStack';
import { StorageStack } from './stacks/StorageStack';
import { IoTStack } from './stacks/IoTStack';
import { AppSyncStack } from './stacks/AppSyncStack';
import { AmplifyHostingStack } from './stacks/AmplifyHostingStack';
import { UiJsonStack } from './stacks/UiJsonStack';

const app = new cdk.App();

const env = { 
  account: process.env.CDK_DEFAULT_ACCOUNT, 
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1'
};

const envName = process.env.ENV_NAME || 'dev';
const appName = 'SmartHome';

const baseProps = {
  env,
  tags: {
    Environment: envName,
    Project: appName,
  },
};

// Layer 1: Independent stacks (no dependencies)
const amplifyStack = new AmplifyHostingStack(app, `${envName}-AmplifyHostingStack`, {
  ...baseProps,
  envName,
});

const authStack = new AuthStack(app, `${envName}-AuthStack`, {
  ...baseProps,
  appName,
  envName,
});

const storageStack = new StorageStack(app, `${envName}-StorageStack`, {
  ...baseProps,
  envName,
});

const iotStack = new IoTStack(app, `${envName}-IoTStack`, {
  ...baseProps,
  envName,
});

// Layer 2: Dependent stacks
const appSyncStack = new AppSyncStack(app, `${envName}-AppSyncStack`, {
  ...baseProps,
  envName,
});

const uiJsonStack = new UiJsonStack(app, `${envName}-UiJsonStack`, {
  ...baseProps,
  envName,
});

// Dependencies
appSyncStack.addDependency(authStack);
appSyncStack.addDependency(storageStack);
uiJsonStack.addDependency(amplifyStack);

app.synth();