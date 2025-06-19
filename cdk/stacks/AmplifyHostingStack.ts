import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as amplify from '@aws-cdk/aws-amplify-alpha';
import * as codebuild from 'aws-cdk-lib/aws-codebuild';
<<<<<<< Updated upstream
=======
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ssm from 'aws-cdk-lib/aws-ssm';
>>>>>>> Stashed changes

interface AmplifyHostingStackProps extends cdk.StackProps {
  domainName: string;
  envName: string; // Add envName to props
}

export class AmplifyHostingStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AmplifyHostingStackProps) {
    super(scope, id, props);
    
    const envName = props.envName || 'dev';

<<<<<<< Updated upstream
    const sourceCodeProvider = new amplify.GitHubSourceCodeProvider({
      owner: 'AKlifewire',
      repository: 'akorede',
      oauthToken: cdk.SecretValue.secretsManager('GITHUB_TOKEN'), // Use your existing secret
    });

    // Make Amplify App name unique per environment
=======
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

    // Create Amplify app with GitHub integration and auth environment variables
>>>>>>> Stashed changes
    const amplifyApp = new amplify.App(this, `SmartHomeFrontendApp-${envName}`, {
      appName: `SmartHomeFrontendApp-${envName}`,
      sourceCodeProvider,
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
      autoBranchCreation: {
        patterns: ['main'],
        pullRequestPreview: true,
        environmentVariables: {
          NODE_ENV: 'production',
          ENV_NAME: envName,
        },
      },
      buildSpec: codebuild.BuildSpec.fromObject({
        version: '1.0',
<<<<<<< Updated upstream
        phases: {
          preBuild: {
            commands: ['npm ci'],
          },
          build: {
            commands: ['npm run build'],
          },
        },
        artifacts: {
          baseDirectory: 'build',
          files: ['**/*'],
        },
        cache: {
          paths: ['node_modules/**/*'],
        },
      }),
=======
        frontend: {
          phases: {
            preBuild: {
              commands: [
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
            files: [
              '**/*'
            ]
          },
          cache: {
            paths: [
              'flutter/**/*',
              '.pub-cache/**/*'
            ]
          }
        }
      })
>>>>>>> Stashed changes
    });

    // If you use branches or domains, also make them unique:
    amplifyApp.addBranch(`main-${envName}`); // auto-deploy main branch

<<<<<<< Updated upstream
    new cdk.CfnOutput(this, `AmplifyAppUrl-${envName}`, {
=======
    // Assign the role to the Amplify app
    const cfnApp = amplifyApp.node.defaultChild as cdk.aws_amplify.CfnApp;
    cfnApp.iamServiceRole = amplifyServiceRole.roleArn;

    // Create branches with environment-specific variables
    const mainBranch = amplifyApp.addBranch('main', {
      autoBuild: true,
      stage: 'PRODUCTION',
      environmentVariables: {
        ENV_NAME: 'prod',
        NODE_ENV: 'production',
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
      }
    });

    const devBranch = amplifyApp.addBranch('develop', {
      autoBuild: true,
      stage: 'DEVELOPMENT',
      environmentVariables: {
        ENV_NAME: 'dev',
        NODE_ENV: 'development',
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
      }
    });

    // Output the Amplify app ID and URL
    new cdk.CfnOutput(this, `AmplifyAppId${envName}`, {
>>>>>>> Stashed changes
      value: amplifyApp.appId,
      description: `Amplify App ID for frontend (${envName})`
    });

    new cdk.CfnOutput(this, `AmplifyDefaultDomain${envName}`, {
      value: amplifyApp.defaultDomain,
      description: `Default Amplify Domain (${envName})`
    });
<<<<<<< Updated upstream
=======

    new cdk.CfnOutput(this, `AmplifyConsoleUrl${envName}`, {
      value: `https://console.aws.amazon.com/amplify/home?region=${this.region}#/${amplifyApp.appId}`,
      description: `URL to the Amplify Console (${envName})`
    });

    new cdk.CfnOutput(this, `GitHubRepoUrl${envName}`, {
      value: `https://github.com/${githubOwner}/${repoName}`,
      description: `GitHub Repository URL (${envName})`
    });
>>>>>>> Stashed changes
  }
}