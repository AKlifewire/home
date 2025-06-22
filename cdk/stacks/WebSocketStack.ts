import * as cdk from 'aws-cdk-lib';
import * as apigatewayv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as iam from 'aws-cdk-lib/aws-iam';
import { WebSocketLambdaIntegration } from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import { Construct } from 'constructs';

export interface WebSocketStackProps extends cdk.StackProps {
  envName: string;
}

export class WebSocketStack extends cdk.Stack {
  public readonly webSocketApi: apigatewayv2.WebSocketApi;
  public readonly connectionsTable: dynamodb.Table;

  constructor(scope: Construct, id: string, props: WebSocketStackProps) {
    super(scope, id, props);

    // DynamoDB table for WebSocket connections
    this.connectionsTable = new dynamodb.Table(this, 'WebSocketConnections', {
      tableName: `SmartHome-${props.envName}-Connections`,
      partitionKey: { name: 'connectionId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY
    });

    // Lambda functions for WebSocket
    const connectLambda = new lambda.Function(this, 'ConnectFunction', {
      functionName: `SmartHome-${props.envName}-websocket-connect`,
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        const AWS = require('aws-sdk');
        const ddb = new AWS.DynamoDB.DocumentClient();
        
        exports.handler = async (event) => {
          const connectionId = event.requestContext.connectionId;
          
          await ddb.put({
            TableName: process.env.CONNECTIONS_TABLE,
            Item: {
              connectionId,
              timestamp: Date.now()
            }
          }).promise();
          
          return { statusCode: 200 };
        };
      `),
      environment: {
        CONNECTIONS_TABLE: this.connectionsTable.tableName
      }
    });

    const disconnectLambda = new lambda.Function(this, 'DisconnectFunction', {
      functionName: `SmartHome-${props.envName}-websocket-disconnect`,
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        const AWS = require('aws-sdk');
        const ddb = new AWS.DynamoDB.DocumentClient();
        
        exports.handler = async (event) => {
          const connectionId = event.requestContext.connectionId;
          
          await ddb.delete({
            TableName: process.env.CONNECTIONS_TABLE,
            Key: { connectionId }
          }).promise();
          
          return { statusCode: 200 };
        };
      `),
      environment: {
        CONNECTIONS_TABLE: this.connectionsTable.tableName
      }
    });

    const messageHandler = new lambda.Function(this, 'MessageHandler', {
      functionName: `SmartHome-${props.envName}-websocket-message`,
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        const AWS = require('aws-sdk');
        const apiGateway = new AWS.ApiGatewayManagementApi({
          endpoint: process.env.WEBSOCKET_ENDPOINT
        });
        
        exports.handler = async (event) => {
          const { connectionId } = event.requestContext;
          const message = JSON.parse(event.body);
          
          // Echo message back
          await apiGateway.postToConnection({
            ConnectionId: connectionId,
            Data: JSON.stringify({
              type: 'response',
              data: message
            })
          }).promise();
          
          return { statusCode: 200 };
        };
      `)
    });

    // Grant permissions
    this.connectionsTable.grantReadWriteData(connectLambda);
    this.connectionsTable.grantReadWriteData(disconnectLambda);

    // WebSocket API
    this.webSocketApi = new apigatewayv2.WebSocketApi(this, 'DeviceWebSocket', {
      apiName: `SmartHome-${props.envName}-WebSocket`,
      connectRouteOptions: {
        integration: new WebSocketLambdaIntegration('ConnectIntegration', connectLambda)
      },
      disconnectRouteOptions: {
        integration: new WebSocketLambdaIntegration('DisconnectIntegration', disconnectLambda)
      },
      defaultRouteOptions: {
        integration: new WebSocketLambdaIntegration('MessageIntegration', messageHandler)
      }
    });

    const stage = new apigatewayv2.WebSocketStage(this, 'WebSocketStage', {
      webSocketApi: this.webSocketApi,
      stageName: props.envName,
      autoDeploy: true
    });

    // Grant API Gateway permissions to invoke Lambda
    messageHandler.addEnvironment('WEBSOCKET_ENDPOINT', `https://${this.webSocketApi.apiId}.execute-api.${this.region}.amazonaws.com/${props.envName}`);

    messageHandler.addToRolePolicy(new iam.PolicyStatement({
      actions: ['execute-api:ManageConnections'],
      resources: [`arn:aws:execute-api:${this.region}:${this.account}:${this.webSocketApi.apiId}/*`]
    }));

    new cdk.CfnOutput(this, 'WebSocketUrl', {
      value: `wss://${this.webSocketApi.apiId}.execute-api.${this.region}.amazonaws.com/${props.envName}`,
      description: 'WebSocket API URL'
    });
  }
}