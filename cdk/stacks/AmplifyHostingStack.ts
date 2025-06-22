import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as amplify from '@aws-cdk/aws-amplify-alpha';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import { getSSMPath, SSM_CONFIG } from '../utils/config';

interface AmplifyHostingStackProps extends cdk.StackProps {
  envName: string;
}

export class AmplifyHostingStack extends cdk.Stack {
  public readonly amplifyDomain: string;
  
  constructor(scope: Construct, id: string, props: AmplifyHostingStackProps) {
    super(scope, id, props);
    
    const envName = props.envName || 'dev';

    // Create Amplify app for manual deployment
    const amplifyApp = new amplify.App(this, `SmartHomeFrontendApp-${envName}`, {
      appName: `SmartHomeFrontendApp-${envName}`,
      platform: amplify.Platform.WEB,
      environmentVariables: {
        NODE_ENV: 'production',
        ENV_NAME: envName
      }
    });

    // Create IAM role for Amplify
    const amplifyServiceRole = new iam.Role(this, `AmplifyServiceRole-${envName}`, {
      assumedBy: new iam.ServicePrincipal('amplify.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AdministratorAccess-Amplify')
      ]
    });

    // Assign role to Amplify app
    const cfnApp = amplifyApp.node.defaultChild as cdk.aws_amplify.CfnApp;
    cfnApp.iamServiceRole = amplifyServiceRole.roleArn;

    // Create main branch for manual deployment
    amplifyApp.addBranch('main', {
      autoBuild: false,
      stage: 'PRODUCTION'
    });

    this.amplifyDomain = `https://${amplifyApp.defaultDomain}`;

    // Store domain in SSM for other stacks to reference
    new ssm.StringParameter(this, `FrontendDomainParam-${envName}`, {
      parameterName: getSSMPath(envName, SSM_CONFIG.KEYS.FRONTEND_DOMAIN),
      stringValue: this.amplifyDomain,
      description: `Frontend domain for ${envName} environment`
    });

    // Store Amplify App ID in SSM
    new ssm.StringParameter(this, `AmplifyAppIdParam-${envName}`, {
      parameterName: getSSMPath(envName, SSM_CONFIG.KEYS.AMPLIFY_APP_ID),
      stringValue: amplifyApp.appId,
      description: `Amplify App ID for ${envName} environment`
    });

    // Outputs
    new cdk.CfnOutput(this, `AmplifyAppId${envName}`, {
      value: amplifyApp.appId,
      description: `Amplify App ID for frontend (${envName})`
    });

    new cdk.CfnOutput(this, `AmplifyDefaultDomain${envName}`, {
      value: amplifyApp.defaultDomain,
      description: `Default Amplify Domain (${envName})`
    });

    new cdk.CfnOutput(this, `AmplifyConsoleUrl${envName}`, {
      value: `https://console.aws.amazon.com/amplify/home?region=${this.region}#/${amplifyApp.appId}`,
      description: `URL to the Amplify Console (${envName})`
    });
  }
}