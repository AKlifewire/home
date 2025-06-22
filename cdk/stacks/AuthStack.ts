import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import { SSM_CONFIG, getSSMPath } from '../utils/config';

interface AuthStackProps extends cdk.StackProps {
  appName: string;
  envName: string;
}

export class AuthStack extends cdk.Stack {
  public readonly userPool: cognito.UserPool;
  public readonly userPoolId: string;

  constructor(scope: Construct, id: string, props: AuthStackProps) {
    super(scope, id, props);

    const envName = props.envName;

    // Create User Pool
    this.userPool = new cognito.UserPool(this, 'UserPool', {
      userPoolName: `${props.appName}-${envName}`,
      selfSignUpEnabled: true,
      signInAliases: {
        email: true,
        username: true
      },
      autoVerify: {
        email: true
      },
      standardAttributes: {
        email: {
          required: true,
          mutable: true
        }
      }
    });

    // Create User Pool Domain
    new cognito.UserPoolDomain(this, 'UserPoolDomain', {
      userPool: this.userPool,
      cognitoDomain: {
        domainPrefix: `smart-home-iot-${envName}`
      }
    });

    // Create User Pool Client with callback URLs (will be updated later)
    const userPoolClient = new cognito.UserPoolClient(this, 'UserPoolClient', {
      userPool: this.userPool,
      generateSecret: false,
      oAuth: {
        callbackUrls: ['http://localhost:3000', 'https://example.com'],
        logoutUrls: ['http://localhost:3000', 'https://example.com'],
        flows: {
          authorizationCodeGrant: true
        },
        scopes: [
          cognito.OAuthScope.EMAIL,
          cognito.OAuthScope.OPENID,
          cognito.OAuthScope.PROFILE
        ]
      }
    });

    // Create Identity Pool
    const identityPool = new cognito.CfnIdentityPool(this, 'IdentityPool', {
      allowUnauthenticatedIdentities: false,
      cognitoIdentityProviders: [{
        clientId: userPoolClient.userPoolClientId,
        providerName: this.userPool.userPoolProviderName
      }]
    });

    this.userPoolId = this.userPool.userPoolId;

    // Store in SSM for other stacks
    new ssm.StringParameter(this, 'UserPoolIdParam', {
      parameterName: getSSMPath(envName, SSM_CONFIG.KEYS.USER_POOL_ID),
      stringValue: this.userPool.userPoolId,
      description: 'Cognito User Pool ID'
    });

    new ssm.StringParameter(this, 'UserPoolClientIdParam', {
      parameterName: getSSMPath(envName, SSM_CONFIG.KEYS.USER_POOL_CLIENT_ID),
      stringValue: userPoolClient.userPoolClientId,
      description: 'Cognito User Pool Client ID'
    });

    new ssm.StringParameter(this, 'IdentityPoolIdParam', {
      parameterName: getSSMPath(envName, SSM_CONFIG.KEYS.IDENTITY_POOL_ID),
      stringValue: identityPool.ref,
      description: 'Cognito Identity Pool ID'
    });

    // Outputs
    new cdk.CfnOutput(this, 'UserPoolId', {
      value: this.userPool.userPoolId,
      description: 'The ID of the Cognito User Pool'
    });

    new cdk.CfnOutput(this, 'UserPoolClientId', {
      value: userPoolClient.userPoolClientId,
      description: 'The ID of the Cognito User Pool Client'
    });

    new cdk.CfnOutput(this, 'IdentityPoolId', {
      value: identityPool.ref,
      description: 'The ID of the Cognito Identity Pool'
    });
  }
}