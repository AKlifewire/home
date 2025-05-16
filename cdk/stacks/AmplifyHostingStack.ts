import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as amplify from '@aws-cdk/aws-amplify-alpha';
import * as codebuild from 'aws-cdk-lib/aws-codebuild';

interface AmplifyHostingStackProps extends cdk.StackProps {
  domainName: string;
}

export class AmplifyHostingStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AmplifyHostingStackProps) {
    super(scope, id, props);

    const sourceCodeProvider = new amplify.GitHubSourceCodeProvider({
      owner: 'AKlifewire',
      repository: 'akorede',
      oauthToken: cdk.SecretValue.secretsManager('GITHUB_TOKEN'), // Use your existing secret
    });

    const amplifyApp = new amplify.App(this, 'SmartHomeFrontendApp', {
      sourceCodeProvider,
      environmentVariables: {
        NODE_ENV: 'production',
      },
      autoBranchCreation: {
        patterns: ['main'],
        pullRequestPreview: true,
        environmentVariables: {
          NODE_ENV: 'production',
        },
      },
      buildSpec: codebuild.BuildSpec.fromObject({
        version: '1.0',
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
    });

    amplifyApp.addBranch('main'); // auto-deploy main branch

    new cdk.CfnOutput(this, 'AmplifyAppUrl', {
      value: amplifyApp.appId,
      description: 'Amplify App ID for frontend',
      exportName: 'AmplifyAppId',
    });

    new cdk.CfnOutput(this, 'AmplifyDefaultDomain', {
      value: amplifyApp.defaultDomain,
      description: 'Default Amplify Domain',
      exportName: 'AmplifyDefaultDomain',
    });
  }
}