import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as appsync from 'aws-cdk-lib/aws-appsync';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as fs from 'fs';
import * as path from 'path';

interface AppSyncStackProps extends cdk.StackProps {
  userPool: cognito.UserPool;
  lambdaFunctions: { [key: string]: lambda.Function };
}

export class AppSyncStack extends cdk.Stack {
  public readonly graphqlEndpoint: string;
  public readonly graphqlApiId: string;
  public readonly api: appsync.CfnGraphQLApi;

  constructor(scope: Construct, id: string, props: AppSyncStackProps) {
    super(scope, id, props);

    // Read schema from file
    const schemaPath = path.join(__dirname, 'schema', 'schema.graphql');
    const schemaString = fs.readFileSync(schemaPath, 'utf8');

    // Create AppSync API with Cognito user pool auth
    this.api = new appsync.CfnGraphQLApi(this, 'GraphqlApi', {
      name: 'SmartHomeAPI',
      authenticationType: 'AMAZON_COGNITO_USER_POOLS',
      userPoolConfig: {
        userPoolId: props.userPool.userPoolId,
        awsRegion: this.region,
        defaultAction: 'ALLOW',
      },
      additionalAuthenticationProviders: [
        {
          authenticationType: 'API_KEY',
        }
      ],
      xrayEnabled: true,
    });

    // Create API Key for testing
    const apiKey = new appsync.CfnApiKey(this, 'ApiKey', {
      apiId: this.api.attrApiId,
      description: 'API Key for testing',
      expires: Math.floor(Date.now() / 1000) + 365 * 24 * 60 * 60, // 1 year
    });

    // Create Schema
    const schema = new appsync.CfnGraphQLSchema(this, 'GraphQLSchema', {
      apiId: this.api.attrApiId,
      definition: schemaString,
    });

    // Create Lambda Data Sources and Resolvers
    const dataSources: { [key: string]: appsync.CfnDataSource } = {};
    const resolvers: { [key: string]: appsync.CfnResolver } = {};

    // Create IAM role for AppSync to invoke Lambda
    const appSyncLambdaRole = new iam.Role(this, 'AppSyncLambdaRole', {
      assumedBy: new iam.ServicePrincipal('appsync.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaRole'),
      ],
    });

    // Map of resolvers to Lambda functions
    const resolverMappings = [
      { typeName: 'Query', fieldName: 'getUiPage', lambdaName: 'get-ui-page' },
      { typeName: 'Query', fieldName: 'getMyDevices', lambdaName: 'get-my-devices' },
      { typeName: 'Query', fieldName: 'getDeviceState', lambdaName: 'get-device-state' },
      { typeName: 'Query', fieldName: 'getAnalytics', lambdaName: 'get-analytics' },
      { typeName: 'Query', fieldName: 'getUiJson', lambdaName: 'get-ui-json' },
      { typeName: 'Mutation', fieldName: 'controlRelay', lambdaName: 'control-relay' },
      { typeName: 'Mutation', fieldName: 'registerDevice', lambdaName: 'register-device' },
      { typeName: 'Mutation', fieldName: 'removeDevice', lambdaName: 'remove-device' },
    ];

    // Create data sources and resolvers
    resolverMappings.forEach(({ typeName, fieldName, lambdaName }) => {
      const lambdaFunction = props.lambdaFunctions[lambdaName];
      
      if (!lambdaFunction) {
        throw new Error(`Lambda function ${lambdaName} not found in props.lambdaFunctions`);
      }

      // Create data source
      const dataSource = new appsync.CfnDataSource(this, `${lambdaName}DataSource`, {
        apiId: this.api.attrApiId,
        name: `${lambdaName.replace(/-/g, '_')}DataSource`,
        type: 'AWS_LAMBDA',
        lambdaConfig: {
          lambdaFunctionArn: lambdaFunction.functionArn,
        },
        serviceRoleArn: appSyncLambdaRole.roleArn,
      });
      
      dataSource.addDependency(schema);
      dataSources[lambdaName] = dataSource;

      // Grant AppSync permission to invoke the Lambda function
      lambdaFunction.grantInvoke(appSyncLambdaRole);

      // Create resolver
      const resolver = new appsync.CfnResolver(this, `${lambdaName}Resolver`, {
        apiId: this.api.attrApiId,
        typeName,
        fieldName,
        dataSourceName: dataSource.name,
      });
      
      resolver.addDependency(dataSource);
      resolvers[`${typeName}.${fieldName}`] = resolver;
    });

    // Create None data source for local resolvers
    const noneDataSource = new appsync.CfnDataSource(this, 'NoneDataSource', {
      apiId: this.api.attrApiId,
      name: 'NoneDataSource',
      type: 'NONE',
    });

    // Create subscription resolvers
    const subscriptionResolvers = [
      { typeName: 'Subscription', fieldName: 'onDeviceUpdate' },
      { typeName: 'Subscription', fieldName: 'onDeviceAdded' },
    ];

    subscriptionResolvers.forEach(({ typeName, fieldName }) => {
      const resolver = new appsync.CfnResolver(this, `${fieldName}Resolver`, {
        apiId: this.api.attrApiId,
        typeName,
        fieldName,
        dataSourceName: noneDataSource.name,
        requestMappingTemplate: `{
          "version": "2018-05-29",
          "payload": {}
        }`,
        responseMappingTemplate: "$util.toJson($context.result)",
      });
      
      resolver.addDependency(noneDataSource);
    });

    // Store API URL in SSM for other stacks to use
    new ssm.StringParameter(this, 'GraphQLApiUrlParam', {
      parameterName: `/appsync/${this.stackName}/api-url`,
      stringValue: `https://${this.api.attrGraphQlUrl}`,
      description: 'URL for the AppSync GraphQL API',
    });

    // Export GraphQL API URL and key
    new cdk.CfnOutput(this, 'GraphQLApiUrl', {
      value: `https://${this.api.attrGraphQlUrl}`,
      description: 'URL for the AppSync GraphQL API',
      exportName: `${this.stackName}-GraphQLApiUrl`,
    });

    new cdk.CfnOutput(this, 'GraphQLApiId', {
      value: this.api.attrApiId,
      description: 'ID of the AppSync GraphQL API',
      exportName: `${this.stackName}-GraphQLApiId`,
    });

    new cdk.CfnOutput(this, 'ApiKeyOutput', {
      value: apiKey.attrApiKey || 'No API Key defined',
      description: 'API Key for the AppSync GraphQL API',
      exportName: `${this.stackName}-GraphQLApiKey`,
    });
    
    // Expose for other stacks
    this.graphqlEndpoint = `https://${this.api.attrGraphQlUrl}`;
    this.graphqlApiId = this.api.attrApiId;
  }
}