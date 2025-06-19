import { Stack, StackProps, Duration, CfnOutput } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as ssm from 'aws-cdk-lib/aws-ssm';

interface AuthStackProps extends StackProps {
  appName: string;
  envName: string;
}

export class AuthStack extends Stack {
  public readonly userPool: cognito.UserPool;
  public readonly userPoolClient: cognito.UserPoolClient;
  public readonly identityPool: cognito.CfnIdentityPool;

  constructor(scope: Construct, id: string, props: AuthStackProps) {
    super(scope, id, props);

    const userPool = new cognito.UserPool(this, 'UserPool', {
      userPoolName: `${props.appName}-${props.envName}-userpool`,
      selfSignUpEnabled: true,
      signInAliases: { email: true },
      autoVerify: { email: true },
      passwordPolicy: {
        minLength: 8,
        requireDigits: true,
        requireLowercase: true,
        requireUppercase: false,
        requireSymbols: false,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
    });

    // Create a domain for the user pool
    const userPoolDomain = userPool.addDomain('CognitoDomain', {
      cognitoDomain: {
        domainPrefix: `smart-home-iot-${props.envName}`,
      },
    });

    // Create user pool client with OAuth settings
    const userPoolClient = new cognito.UserPoolClient(this, 'UserPoolClient', {
      userPool,
      generateSecret: false,
      authFlows: {
        userPassword: true,
        userSrp: true,
      },
      oAuth: {
        flows: {
          authorizationCodeGrant: true,
          implicitCodeGrant: true,
        },
        scopes: [
          cognito.OAuthScope.PHONE,
          cognito.OAuthScope.EMAIL,
          cognito.OAuthScope.OPENID,
          cognito.OAuthScope.PROFILE,
          cognito.OAuthScope.COGNITO_ADMIN,
        ],
        callbackUrls: [
          'http://localhost:3000/',
          'https://main.d29b8yerucsuvm.amplifyapp.com/',
        ],
        logoutUrls: [
          'http://localhost:3000/',
          'https://main.d29b8yerucsuvm.amplifyapp.com/',
        ],
      },
      supportedIdentityProviders: [
        cognito.UserPoolClientIdentityProvider.COGNITO,
      ],
    });

    const identityPool = new cognito.CfnIdentityPool(this, 'IdentityPool', {
      allowUnauthenticatedIdentities: false,
      cognitoIdentityProviders: [
        {
          clientId: userPoolClient.userPoolClientId,
          providerName: userPool.userPoolProviderName,
        },
      ],
    });

    // Store in SSM for other stacks to use - with unique names to avoid conflicts
    new ssm.StringParameter(this, 'UserPoolIdParam', {
      parameterName: `/auth/${this.stackName}/userPoolId`,
      stringValue: userPool.userPoolId,
      description: 'User Pool ID for Smart Home App',
    });

    new ssm.StringParameter(this, 'UserPoolClientIdParam', {
      parameterName: `/auth/${this.stackName}/userPoolClientId`,
      stringValue: userPoolClient.userPoolClientId,
      description: 'User Pool Client ID for Smart Home App',
    });

    new ssm.StringParameter(this, 'IdentityPoolIdParam', {
      parameterName: `/auth/${this.stackName}/identityPoolId`,
      stringValue: identityPool.ref,
      description: 'Identity Pool ID for Smart Home App',
    });

    // Outputs for downstream usage
    new CfnOutput(this, 'UserPoolId', {
      value: userPool.userPoolId,
      description: 'The ID of the Cognito User Pool',
      exportName: `${this.stackName}-UserPoolId`,
    });

    new CfnOutput(this, 'UserPoolClientId', {
      value: userPoolClient.userPoolClientId,
      description: 'The ID of the Cognito User Pool Client',
      exportName: `${this.stackName}-UserPoolClientId`,
    });

    new CfnOutput(this, 'IdentityPoolId', {
      value: identityPool.ref,
      description: 'The ID of the Cognito Identity Pool',
      exportName: `${this.stackName}-IdentityPoolId`,
    });

    // Expose for other stacks
    this.userPool = userPool;
    this.userPoolClient = userPoolClient;
    this.identityPool = identityPool;
  }
}