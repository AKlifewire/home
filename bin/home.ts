#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { HomeStack } from '../lib/home-stack';
import { AuthStack } from '../cdk/stacks/AuthStack';
import { StorageStack } from '../cdk/stacks/StorageStack';
import { LambdaStack } from '../cdk/stacks/LambdaStack';
import { IoTStack } from '../cdk/stacks/IoTStack';
import { AppSyncStack } from '../cdk/stacks/AppSyncStack';
import { AmplifyHostingStack } from '../cdk/stacks/AmplifyHostingStack';

const app = new cdk.App();
const envName = app.node.tryGetContext('env') || 'dev';

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION,
};

new HomeStack(app, `HomeStack-${envName}`, { env });
new AuthStack(app, `AuthStack-${envName}`, { appName: 'SmartHomeApp', envName, env });
new StorageStack(app, `StorageStack-${envName}`, { env });
new LambdaStack(app, `LambdaStack-${envName}`, {
  app: 'SmartHomeApp',
  envName, // pass envName to the stack
  env,
});
new IoTStack(app, `IoTStack-${envName}`, { envName, env });
new AppSyncStack(app, `AppSyncStack-${envName}`, { env });
new AmplifyHostingStack(app, `AmplifyHostingStack-${envName}`, { domainName: 'your-domain.com', envName, env });