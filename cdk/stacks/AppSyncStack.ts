import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as appsync from 'aws-cdk-lib/aws-appsync';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as fs from 'fs';
import * as path from 'path';

export class AppSyncStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create mock Lambda functions for development
    // In production, these would be imported from SSM parameters
    const getUIPageFn = new lambda.Function(this, 'GetUIPageFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'get-ui-page.handler',
      code: lambda.Code.fromInline(`
        exports.handler = async (event) => {
          console.log('GetUIPage event:', JSON.stringify(event));
          return {
            success: true,
            data: { title: "Example UI Page" }
          };
        };
      `),
    });

    const controlDeviceFn = new lambda.Function(this, 'ControlDeviceFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'control-device.handler',
      code: lambda.Code.fromInline(`
        exports.handler = async (event) => {
          console.log('ControlDevice event:', JSON.stringify(event));
          return {
            success: true,
            message: "Command sent to device"
          };
        };
      `),
    });

    const getAnalyticsFn = new lambda.Function(this, 'GetAnalyticsFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'get-analytics.handler',
      code: lambda.Code.fromInline(`
        exports.handler = async (event) => {
          console.log('GetAnalytics event:', JSON.stringify(event));
          return {
            success: true,
            data: { metrics: [{ date: "2025-05-14", value: 42 }] }
          };
        };
      `),
    });

    // Store Lambda ARNs in SSM for other stacks to use with unique names
    new ssm.StringParameter(this, 'GetUIPageArnParam', {
      parameterName: `/lambda/${this.stackName}/get-ui-page-arn`,
      stringValue: getUIPageFn.functionArn,
      description: 'ARN for the GetUIPage Lambda function',
    });

    new ssm.StringParameter(this, 'ControlDeviceArnParam', {
      parameterName: `/lambda/${this.stackName}/control-device-arn`,
      stringValue: controlDeviceFn.functionArn,
      description: 'ARN for the ControlDevice Lambda function',
    });

    new ssm.StringParameter(this, 'GetAnalyticsArnParam', {
      parameterName: `/lambda/${this.stackName}/get-analytics-arn`,
      stringValue: getAnalyticsFn.functionArn,
      description: 'ARN for the GetAnalytics Lambda function',
    });

    // AppSync GraphQL API
    const api = new appsync.GraphqlApi(this, 'GraphqlApi', {
      name: 'AKSmartHomeAPI',
      schema: appsync.SchemaFile.fromAsset('cdk/schema.graphql/schema.graphql'),
      authorizationConfig: {
        defaultAuthorization: {
          authorizationType: appsync.AuthorizationType.API_KEY,
          apiKeyConfig: {
            expires: cdk.Expiration.after(cdk.Duration.days(365))
          }
        }
      }
    });

    // Lambda data sources
    const getUIPageSource = api.addLambdaDataSource('GetUIPageSource', getUIPageFn);
    const controlDeviceSource = api.addLambdaDataSource('ControlDeviceSource', controlDeviceFn);
    const getAnalyticsSource = api.addLambdaDataSource('GetAnalyticsSource', getAnalyticsFn);

    // Resolver bindings
    getUIPageSource.createResolver('GetUIPageResolver', {
      typeName: 'Query',
      fieldName: 'getUiPage',
    });

    controlDeviceSource.createResolver('ControlDeviceResolver', {
      typeName: 'Mutation',
      fieldName: 'controlDevice',
    });

    getAnalyticsSource.createResolver('GetAnalyticsResolver', {
      typeName: 'Query',
      fieldName: 'getAnalytics',
    });

    // Subscription resolver removed to fix deployment issues

    // Store API URL in SSM for other stacks to use
    new ssm.StringParameter(this, 'GraphQLApiUrlParam', {
      parameterName: `/appsync/${this.stackName}/api-url`,
      stringValue: api.graphqlUrl,
      description: 'URL for the AppSync GraphQL API',
    });

    // Export GraphQL API URL and key
    new cdk.CfnOutput(this, 'GraphQLApiUrl', {
      value: api.graphqlUrl,
      description: 'URL for the AppSync GraphQL API',
      exportName: `${this.stackName}-GraphQLApiUrl`,
    });

    new cdk.CfnOutput(this, 'GraphQLApiId', {
      value: api.apiId,
      description: 'ID of the AppSync GraphQL API',
      exportName: `${this.stackName}-GraphQLApiId`,
    });

    new cdk.CfnOutput(this, 'GraphQLApiKey', {
      value: api.apiKey || 'No API Key defined',
      description: 'API Key for the AppSync GraphQL API',
      exportName: `${this.stackName}-GraphQLApiKey`,
    });
  }
}