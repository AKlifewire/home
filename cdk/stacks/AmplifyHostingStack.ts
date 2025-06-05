import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as amplify from '@aws-cdk/aws-amplify-alpha';
import * as codebuild from 'aws-cdk-lib/aws-codebuild';
import * as iam from 'aws-cdk-lib/aws-iam';

interface AmplifyHostingStackProps extends cdk.StackProps {
  domainName: string;
  envName: string;
}

export class AmplifyHostingStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AmplifyHostingStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';
    const githubOwner = 'AKlifewire';
    const repoName = 'frontend';

    // Create Amplify app with GitHub integration
    const amplifyApp = new amplify.App(this, `SmartHomeFrontendApp-${envName}`, {
      appName: `SmartHomeFrontendApp-${envName}`,
      environmentVariables: {
        NODE_ENV: 'production',
        ENV_NAME: envName,
      },
      sourceCodeProvider: new amplify.GitHubSourceCodeProvider({
        owner: githubOwner,
        repository: repoName,
        oauthToken: cdk.SecretValue.secretsManager('github-token')
      }),
      buildSpec: codebuild.BuildSpec.fromObjectToYaml({
        version: '1.0',
        frontend: {
          phases: {
            preBuild: {
              commands: [
                'flutter pub get',
                'flutter clean'
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
            paths: ['.dart_tool/**/*', '.pub-cache/**/*']
          }
        }
      }),
    });

    // Create a service role for Amplify
    const amplifyServiceRole = new iam.Role(this, 'AmplifyServiceRole', {
      assumedBy: new iam.ServicePrincipal('amplify.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AdministratorAccess-Amplify')
      ]
    });

    // Assign the role to the Amplify app
    const cfnApp = amplifyApp.node.defaultChild as cdk.aws_amplify.CfnApp;
    cfnApp.iamServiceRole = amplifyServiceRole.roleArn;

    // Create branches for development and production
    const mainBranch = amplifyApp.addBranch('main', {
      autoBuild: true,
      stage: 'PRODUCTION',
      environmentVariables: {
        ENV_NAME: 'prod',
      }
    });

    const devBranch = amplifyApp.addBranch('develop', {
      autoBuild: true,
      stage: 'DEVELOPMENT',
      environmentVariables: {
        ENV_NAME: 'dev',
      }
    });

    // Output the Amplify app ID and URL
    new cdk.CfnOutput(this, `AmplifyAppId-${envName}`, {
      value: amplifyApp.appId,
      description: `Amplify App ID for frontend (${envName})`,
      exportName: `AmplifyAppId-${envName}`,
    });

    new cdk.CfnOutput(this, `AmplifyDefaultDomain-${envName}`, {
      value: amplifyApp.defaultDomain,
      description: `Default Amplify Domain (${envName})`,
      exportName: `AmplifyDefaultDomain-${envName}`,
    });

    new cdk.CfnOutput(this, `AmplifyConsoleUrl-${envName}`, {
      value: `https://console.aws.amazon.com/amplify/home?region=${this.region}#/${amplifyApp.appId}`,
      description: `URL to the Amplify Console (${envName})`,
      exportName: `AmplifyConsoleUrl-${envName}`,
    });

    new cdk.CfnOutput(this, `GitHubRepoUrl-${envName}`, {
      value: `https://github.com/${githubOwner}/${repoName}`,
      description: `GitHub Repository URL (${envName})`,
      exportName: `GitHubRepoUrl-${envName}`,
    });
  }
}