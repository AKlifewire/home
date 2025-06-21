import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as amplify from '@aws-cdk/aws-amplify-alpha';
import * as codebuild from 'aws-cdk-lib/aws-codebuild';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ssm from 'aws-cdk-lib/aws-ssm';

interface AmplifyHostingStackProps extends cdk.StackProps {
  domainName: string;
  envName: string;
}

export class AmplifyHostingStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AmplifyHostingStackProps) {
    super(scope, id, props);
    
    const envName = props.envName || 'dev';

    // Get SSM parameters for auth settings
    const userPoolId = ssm.StringParameter.valueForStringParameter(
      this,
      `/auth/dev-AuthStack/userPoolId`
    );
    
    const userPoolClientId = ssm.StringParameter.valueForStringParameter(
      this,
      `/auth/dev-AuthStack/userPoolClientId`
    );
    
    const identityPoolId = ssm.StringParameter.valueForStringParameter(
      this,
      `/auth/dev-AuthStack/identityPoolId`
    );

    // Create Amplify app WITHOUT GitHub integration for manual deployment
    const amplifyApp = new amplify.App(this, `SmartHomeFrontendApp-${envName}`, {
      appName: `SmartHomeFrontendApp-${envName}`,
      environmentVariables: {
        NODE_ENV: 'production',
        ENV_NAME: envName,
        AMPLIFY_APPSYNC_URL: 'https://m3kglrtcvfhwfp4mngf6tzqcn4.appsync-api.us-east-1.amazonaws.com/graphql',
        AMPLIFY_API_KEY: 'da2-xg653fjtfvcpnen3l6bpfpoyca',
        AMPLIFY_REGION: 'us-east-1',
        AMPLIFY_UI_BUCKET: 'dev-uijsonstack-uijsonbucket3aa1eb43-8a81zgdjscba',
        USER_POOL_ID: userPoolId,
        USER_POOL_CLIENT_ID: userPoolClientId,
        IDENTITY_POOL_ID: identityPoolId,
        OAUTH_DOMAIN: `smart-home-iot-${envName}.auth.us-east-1.amazoncognito.com`,
        REDIRECT_SIGN_IN: 'https://main.d29b8yerucsuvm.amplifyapp.com/,http://localhost:3000/',
        REDIRECT_SIGN_OUT: 'https://main.d29b8yerucsuvm.amplifyapp.com/,http://localhost:3000/'
      },
      buildSpec: codebuild.BuildSpec.fromObject({
        version: '1.0',
        frontend: {
          phases: {
            preBuild: {
              commands: [
                'apt-get update && apt-get install -y xz-utils',
                'curl -sL https://github.com/flutter/flutter/archive/stable.tar.gz | tar xz',
                'mv flutter-stable flutter',
                'export PATH="$PATH:`pwd`/flutter/bin"',
                'flutter config --enable-web',
                'flutter pub get'
              ]
            },
            build: {
              commands: [
                'flutter build web --release'
              ]
            }
          },
          artifacts: {
            baseDirectory: 'build/web',
            files: ['**/*']
          },
          cache: {
            paths: [
              'flutter/**/*',
              '.pub-cache/**/*'
            ]
          }
        }
      })
    });

    // Create IAM role for Amplify
    const amplifyServiceRole = new iam.Role(this, `AmplifyServiceRole-${envName}`, {
      assumedBy: new iam.ServicePrincipal('amplify.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AdministratorAccess-Amplify')
      ]
    });

    // Assign the role to the Amplify app
    const cfnApp = amplifyApp.node.defaultChild as cdk.aws_amplify.CfnApp;
    cfnApp.iamServiceRole = amplifyServiceRole.roleArn;

    // Create main branch for manual deployment
    const mainBranch = amplifyApp.addBranch('main', {
      autoBuild: false,
      stage: 'PRODUCTION'
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