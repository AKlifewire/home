#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { AmplifyHostingStack } from './cdk/stacks/AmplifyHostingStack';

const app = new cdk.App();
const envName = 'dev';

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
};

// Deploy only the AmplifyHostingStack
new AmplifyHostingStack(app, `dev-AmplifyHostingStack`, { 
  domainName: 'your-domain.com', 
  envName, 
  env 
});

app.synth();