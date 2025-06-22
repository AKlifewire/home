import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as appsync from 'aws-cdk-lib/aws-appsync';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import { SSM_CONFIG, getSSMPath } from '../utils/config';

interface AppSyncStackProps extends cdk.StackProps {
  envName: string;
}

export class AppSyncStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AppSyncStackProps) {
    super(scope, id, props);

    const envName = props.envName;

    // Create mock Lambda functions
    const getUIPageFn = new lambda.Function(this, 'GetUIPageFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        exports.handler = async (event) => {
          return { success: true, data: { title: "Example UI Page" } };
        };
      `),
    });

    const controlDeviceFn = new lambda.Function(this, 'ControlDeviceFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        exports.handler = async (event) => {
          return { success: true, message: "Command sent to device" };
        };
      `),
    });

    // AppSync GraphQL API
    const api = new appsync.GraphqlApi(this, 'GraphqlApi', {
      name: 'AKSmartHomeAPI',
      definition: appsync.Definition.fromFile('cdk/schema.graphql/schema.graphql'),
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

    // Resolvers
    getUIPageSource.createResolver('GetUIPageResolver', {
      typeName: 'Query',
      fieldName: 'getUiPage',
    });

    controlDeviceSource.createResolver('ControlDeviceResolver', {
      typeName: 'Mutation',
      fieldName: 'controlDevice',
    });

    // Store API details in SSM
    new ssm.StringParameter(this, 'AppSyncUrlParam', {
      parameterName: getSSMPath(envName, SSM_CONFIG.KEYS.APPSYNC_URL),
      stringValue: api.graphqlUrl,
      description: 'AppSync GraphQL API URL'
    });

    new ssm.StringParameter(this, 'AppSyncApiKeyParam', {
      parameterName: getSSMPath(envName, SSM_CONFIG.KEYS.APPSYNC_API_KEY),
      stringValue: api.apiKey || '',
      description: 'AppSync API Key'
    });

    // Outputs
    new cdk.CfnOutput(this, 'GraphQLApiUrl', {
      value: api.graphqlUrl,
      description: 'URL for the AppSync GraphQL API'
    });

    new cdk.CfnOutput(this, 'GraphQLApiKey', {
      value: api.apiKey || 'No API Key defined',
      description: 'API Key for the AppSync GraphQL API'
    });
  }
}