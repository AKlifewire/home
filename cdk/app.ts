#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { AuthStack } from './stacks/AuthStack';
import { StorageStack } from './stacks/StorageStack';
import { AppSyncStack } from './stacks/AppSyncStack';
import { SSMParameterStack } from './stacks/SSMParameterStack';
import { IoTStack } from './stacks/IoTStack';
import { LambdaStack } from './stacks/LambdaStack';
import { AmplifyHostingStack } from './stacks/AmplifyHostingStack';
import { AnalyticsStack } from './stacks/AnalyticsStack';
import { PaymentStack } from './stacks/PaymentStack';
import { MonitoringStack } from './stacks/MonitoringStack';
import { GreengrassStack } from './stacks/GreengrassStack';
import { TwinMakerStack } from './stacks/TwinMakerStack';
import { UiJsonStack } from './stacks/UiJsonStack';

const app = new cdk.App();

// Define environment
const environment = app.node.tryGetContext('environment') || 'dev';
const appName = app.node.tryGetContext('appName') || 'smart-home';
const adminEmail = app.node.tryGetContext('adminEmail') || 'admin@example.com';

// Define AWS environment
const env = { 
  account: process.env.CDK_DEFAULT_ACCOUNT, 
  region: process.env.CDK_DEFAULT_REGION 
};

// Create stacks in the correct order
const ssmParameterStack = new SSMParameterStack(app, `${environment}-SSMParameterStack`, {
  environment,
  env,
});

const authStack = new AuthStack(app, `${environment}-AuthStack`, { 
  appName, 
  envName: environment, 
  env 
});

const storageStack = new StorageStack(app, `${environment}-StorageStack`, { 
  environment, 
  env 
});

const iotStack = new IoTStack(app, `${environment}-IoTStack`, { 
  envName: environment, 
  env 
});

const analyticsStack = new AnalyticsStack(app, `${environment}-AnalyticsStack`, { 
  envName: environment, 
  env 
});

const uiJsonStack = new UiJsonStack(app, `${environment}-UiJsonStack`, {
  envName: environment,
  env,
});

const monitoringStack = new MonitoringStack(app, `${environment}-MonitoringStack`, {
  envName: environment,
  adminEmail,
  env,
});

const lambdaStack = new LambdaStack(app, `${environment}-LambdaStack`, {
  app: appName,
  envName: environment,
  userPoolId: authStack.userPoolId,
  identityPoolId: authStack.identityPoolId,
  iotEndpoint: iotStack.iotEndpoint,
  storageBucket: storageStack.uiBucket,
  otaBucket: storageStack.otaBucket,
  logsBucket: storageStack.logsBucket,
  env,
});

const appSyncStack = new AppSyncStack(app, `${environment}-AppSyncStack`, {
  userPool: authStack.userPool,
  lambdaFunctions: lambdaStack.lambdaFunctions,
  env,
});

const paymentStack = new PaymentStack(app, `${environment}-PaymentStack`, {
  envName: environment,
  userPoolId: authStack.userPoolId,
  env,
});

const greengrassStack = new GreengrassStack(app, `${environment}-GreengrassStack`, {
  envName: environment,
  env,
});

const twinMakerStack = new TwinMakerStack(app, `${environment}-TwinMakerStack`, {
  envName: environment,
  env,
});

const amplifyStack = new AmplifyHostingStack(app, `${environment}-AmplifyHostingStack`, {
  domainName: `${appName.toLowerCase()}.com`,
  envName: environment,
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
  
  // UI JSON Parameters
  uiJsonBucket: uiJsonStack.uiJsonBucket.bucketName,
  uiJsonLambdaArn: uiJsonStack.uiJsonLambda.functionArn,
  
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
lambdaStack.addDependency(uiJsonStack);

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
ssmParameterStack.addDependency(uiJsonStack);

amplifyStack.addDependency(appSyncStack);
amplifyStack.addDependency(uiJsonStack);

app.synth();