import * as cdk from 'aws-cdk-lib';
import * as appsync from 'aws-cdk-lib/aws-appsync';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import { Construct } from 'constructs';
import * as path from 'path';
import * as fs from 'fs';

export interface AppSyncStackProps extends cdk.StackProps {
  userPool: cognito.UserPool;
  lambdaStack: {
    uiJsonHandler: lambda.Function;
    batchGetDeviceUIs: lambda.Function;
  };
}

export class AppSyncStack extends cdk.Stack {
  public readonly api: appsync.GraphqlApi;

  constructor(scope: Construct, id: string, props: AppSyncStackProps) {
    super(scope, id, props);

    // Create the AppSync API
    this.api = new appsync.GraphqlApi(this, 'SmartHomeApi', {
      name: 'SmartHomeApi',
      schema: appsync.SchemaFile.fromAsset(path.join(__dirname, 'schema', 'schema.graphql')),
      authorizationConfig: {
        defaultAuthorization: {
          authorizationType: appsync.AuthorizationType.USER_POOL,
          userPoolConfig: {
            userPool: props.userPool,
          },
        },
        additionalAuthorizationModes: [
          {
            authorizationType: appsync.AuthorizationType.API_KEY,
            apiKeyConfig: {
              name: 'default',
              description: 'Default API Key for public access',
              expires: cdk.Expiration.after(cdk.Duration.days(365)),
            },
          },
        ],
      },
      xrayEnabled: true,
    });

    // Create Lambda data sources
    const uiJsonDataSource = this.api.addLambdaDataSource(
      'UiJsonDataSource',
      props.lambdaStack.uiJsonHandler
    );
    
    const batchUiJsonDataSource = this.api.addLambdaDataSource(
      'BatchUiJsonDataSource',
      props.lambdaStack.batchGetDeviceUIs
    );

    // Create resolvers
    uiJsonDataSource.createResolver({
      typeName: 'Query',
      fieldName: 'getDeviceUI',
      requestMappingTemplate: appsync.MappingTemplate.lambdaRequest(),
      responseMappingTemplate: appsync.MappingTemplate.lambdaResult(),
    });
    
    batchUiJsonDataSource.createResolver({
      typeName: 'Query',
      fieldName: 'batchGetDeviceUIs',
      requestMappingTemplate: appsync.MappingTemplate.lambdaRequest(),
      responseMappingTemplate: appsync.MappingTemplate.lambdaResult(),
    });

    // Store API URL in SSM Parameter Store
    new ssm.StringParameter(this, 'AppSyncApiUrl', {
      parameterName: '/smart-home/appsync/url',
      stringValue: this.api.graphqlUrl,
    });

    // Store API Key in SSM Parameter Store
    new ssm.StringParameter(this, 'AppSyncApiKey', {
      parameterName: '/smart-home/appsync/api-key',
      stringValue: this.api.apiKey || '',
    });

    // Output the API URL
    new cdk.CfnOutput(this, 'GraphQLApiUrl', {
      value: this.api.graphqlUrl,
    });

    // Output the API Key
    new cdk.CfnOutput(this, 'GraphQLApiKey', {
      value: this.api.apiKey || 'No API Key',
    });
  }
}