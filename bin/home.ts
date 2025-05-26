#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { AuthStack } from '../cdk/stacks/AuthStack';
import { StorageStack } from '../cdk/stacks/StorageStack';
import { LambdaStack } from '../cdk/stacks/LambdaStack';
import { IoTStack } from '../cdk/stacks/IoTStack';
import { AppSyncStack } from '../cdk/stacks/AppSyncStack';
import { AmplifyHostingStack } from '../cdk/stacks/AmplifyHostingStack';
import { SSMParameterStack } from '../cdk/stacks/SSMParameterStack';
import { AnalyticsStack } from '../cdk/stacks/AnalyticsStack';
import { PaymentStack } from '../cdk/stacks/PaymentStack';
import { MonitoringStack } from '../cdk/stacks/MonitoringStack';
import { GreengrassStack } from '../cdk/stacks/GreengrassStack';
import { TwinMakerStack } from '../cdk/stacks/TwinMakerStack';

const app = new cdk.App();
const envName = app.node.tryGetContext('env') || 'dev';
const appName = 'SmartHomeApp';
const adminEmail = app.node.tryGetContext('adminEmail') || 'admin@example.com';

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION,
};

// Create stacks in the correct order
const ssmParameterStack = new SSMParameterStack(app, `${envName}-SSMParameterStack`, {
  environment: envName,
  env,
});

const authStack = new AuthStack(app, `${envName}-AuthStack`, { 
  appName, 
  envName, 
  env 
});

const storageStack = new StorageStack(app, `${envName}-StorageStack`, { 
  environment: envName, 
  env 
});

const iotStack = new IoTStack(app, `${envName}-IoTStack`, { 
  envName, 
  env 
});

const analyticsStack = new AnalyticsStack(app, `${envName}-AnalyticsStack`, { 
  envName, 
  env 
});

const monitoringStack = new MonitoringStack(app, `${envName}-MonitoringStack`, {
  envName,
  adminEmail,
  env,
});

const lambdaStack = new LambdaStack(app, `${envName}-LambdaStack`, {
  app: appName,
  envName,
  userPoolId: authStack.userPoolId,
  identityPoolId: authStack.identityPoolId,
  iotEndpoint: iotStack.iotEndpoint,
  storageBucket: storageStack.uiBucket,
  otaBucket: storageStack.otaBucket,
  logsBucket: storageStack.logsBucket,
  env,
});

const appSyncStack = new AppSyncStack(app, `${envName}-AppSyncStack`, {
  userPool: authStack.userPool,
  lambdaFunctions: lambdaStack.lambdaFunctions,
  env,
});

const paymentStack = new PaymentStack(app, `${envName}-PaymentStack`, {
  envName,
  userPoolId: authStack.userPoolId,
  env,
});

const greengrassStack = new GreengrassStack(app, `${envName}-GreengrassStack`, {
  envName,
  env,
});

const twinMakerStack = new TwinMakerStack(app, `${envName}-TwinMakerStack`, {
  envName,
  env,
});

const amplifyStack = new AmplifyHostingStack(app, `${envName}-AmplifyHostingStack`, {
  domainName: `${appName.toLowerCase()}.com`,
  envName,
  env,
});

// Update SSM Parameter Stack with all outputs
ssmParameterStack.addParameters({
  // Auth Parameters
  userPoolId: authStack.userPoolId,
  userPoolClientId: authStack.userPoolClientId,
  identityPoolId: authStack.identityPoolId,
  
  // API Parameters
  graphqlEndpoint: appSyncStack.graphqlEndpoint,
  graphqlApiId: appSyncStack.graphqlApiId,
  
  // Storage Parameters
  s3Bucket: storageStack.uiBucket,
  otaBucket: storageStack.otaBucket,
  logsBucket: storageStack.logsBucket,
  
  // IoT Parameters
  iotEndpoint: iotStack.iotEndpoint,
  iotProvisioningTemplateName: iotStack.provisioningTemplateName,
  iotPolicyName: iotStack.devicePolicy.policyName,
  
  // Analytics Parameters
  timestreamDatabase: analyticsStack.timestreamDatabase.databaseName!,
  timestreamTable: analyticsStack.timestreamTable.tableName!,
  
  // Monitoring Parameters
  alarmTopicArn: monitoringStack.alarmTopic.topicArn,
});

// Add dependencies to ensure proper deployment order
lambdaStack.addDependency(authStack);
lambdaStack.addDependency(iotStack);
lambdaStack.addDependency(storageStack);

appSyncStack.addDependency(lambdaStack);
appSyncStack.addDependency(authStack);

analyticsStack.addDependency(iotStack);

paymentStack.addDependency(authStack);

monitoringStack.addDependency(iotStack);
monitoringStack.addDependency(analyticsStack);

greengrassStack.addDependency(iotStack);

twinMakerStack.addDependency(iotStack);

ssmParameterStack.addDependency(authStack);
ssmParameterStack.addDependency(appSyncStack);
ssmParameterStack.addDependency(storageStack);
ssmParameterStack.addDependency(iotStack);
ssmParameterStack.addDependency(analyticsStack);
ssmParameterStack.addDependency(monitoringStack);
ssmParameterStack.addDependency(paymentStack);
ssmParameterStack.addDependency(greengrassStack);
ssmParameterStack.addDependency(twinMakerStack);

amplifyStack.addDependency(appSyncStack);