#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { HomeStack } from '../lib/home-stack';
import { AuthStack } from '../cdk/stacks/AuthStack';
import { StorageStack } from '../cdk/stacks/StorageStack';
import { LambdaStack } from '../cdk/stacks/LambdaStack';

const app = new cdk.App();
new HomeStack(app, 'HomeStack', {
  /* If you don't specify 'env', this stack will be environment-agnostic.
   * Account/Region-dependent features and context lookups will not work,
   * but a single synthesized template can be deployed anywhere. */

  /* Uncomment the next line to specialize this stack for the AWS Account
   * and Region that are implied by the current CLI configuration. */
  // env: { account: process.env.CDK_DEFAULT_ACCOUNT, region: process.env.CDK_DEFAULT_REGION },

  /* Uncomment the next line if you know exactly what Account and Region you
   * want to deploy the stack to. */
  // env: { account: '123456789012', region: 'us-east-1' },

  /* For more information, see https://docs.aws.amazon.com/cdk/latest/guide/environments.html */
});

new AuthStack(app, 'AuthStack', {
  appName: 'SmartHomeApp',
  envName: 'dev',
});

new StorageStack(app, 'StorageStack');

new LambdaStack(app, 'LambdaStack', {
  app: 'SmartHomeApp',      // or your app name
  envName: 'dev',           // or your environment name
});