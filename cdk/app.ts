import * as cdk from 'aws-cdk-lib';
import { AuthStack } from './stacks/AuthStack';
import { StorageStack } from './stacks/StorageStack';
import { IoTStack } from './stacks/IoTStack';
import { AppSyncStack } from './stacks/AppSyncStack';
import { AmplifyHostingStack } from './stacks/AmplifyHostingStack';
import { UiJsonStack } from './stacks/UiJsonStack';
import { SecurityStack } from './stacks/SecurityStack';
import { MonitoringStack } from './stacks/MonitoringStack';
import { WebSocketStack } from './stacks/WebSocketStack';
import { AnalyticsStack } from './stacks/AnalyticsStack';

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

// Enterprise stacks
const securityStack = new SecurityStack(app, `${envName}-SecurityStack`, {
  ...baseProps,
  envName,
});

const monitoringStack = new MonitoringStack(app, `${envName}-MonitoringStack`, {
  ...baseProps,
  envName,
  alertEmail: 'admin@yourdomain.com',
});

const webSocketStack = new WebSocketStack(app, `${envName}-WebSocketStack`, {
  ...baseProps,
  envName,
});

const analyticsStack = new AnalyticsStack(app, `${envName}-AnalyticsStack`, {
  ...baseProps,
  envName,
});

// Dependencies
appSyncStack.addDependency(authStack);
appSyncStack.addDependency(storageStack);
uiJsonStack.addDependency(amplifyStack);
monitoringStack.addDependency(appSyncStack);
webSocketStack.addDependency(authStack);
analyticsStack.addDependency(iotStack);

app.synth();