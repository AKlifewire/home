import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as path from 'path';

interface DeviceRegistrationStackProps extends cdk.StackProps {
  envName: string;
  userPool: cognito.UserPool;
  devicesTable: dynamodb.Table;
}

export class DeviceRegistrationStack extends cdk.Stack {
  public readonly deviceRegistrationLambda: lambda.Function;
  public readonly deviceRegistrationApi: apigateway.RestApi;

  constructor(scope: Construct, id: string, props: DeviceRegistrationStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';

    // Create IoT policy for devices
    const iotPolicy = new iot.CfnPolicy(this, 'DeviceIoTPolicy', {
      policyName: `device-policy-${envName}`,
      policyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Action: [
              'iot:Connect',
              'iot:Publish',
              'iot:Subscribe',
              'iot:Receive'
            ],
            Resource: [
              `arn:aws:iot:${this.region}:${this.account}:client/\${iot:ClientId}`,
              `arn:aws:iot:${this.region}:${this.account}:topic/device/\${iot:ClientId}/*`,
              `arn:aws:iot:${this.region}:${this.account}:topic/device/\${iot:ClientId}`,
              `arn:aws:iot:${this.region}:${this.account}:topicfilter/device/\${iot:ClientId}/*`
            ]
          }
        ]
      }
    });

    // Get IoT endpoint
    const iotEndpoint = new iot.CfnDomainConfiguration(this, 'IoTDomainConfig', {
      domainConfigurationName: `device-domain-${envName}`,
      domainName: `iot-${envName}.${this.node.tryGetContext('domainName') || 'example.com'}`,
      serviceType: 'DATA'
    });

    // Create Lambda function for device registration
    this.deviceRegistrationLambda = new lambda.Function(this, 'DeviceRegistrationLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'device-registration-handler.handler',
      timeout: cdk.Duration.seconds(30),
      environment: {
        DEVICES_TABLE: props.devicesTable.tableName,
        IOT_POLICY_NAME: iotPolicy.policyName,
        IOT_ENDPOINT: iotEndpoint.attrDomainName
      },
      description: 'Handles device registration and certificate provisioning',
      functionName: `device-registration-${envName}`
    });

    // Grant Lambda permissions to access DynamoDB
    props.devicesTable.grantReadWriteData(this.deviceRegistrationLambda);

    // Grant Lambda permissions to manage IoT things and certificates
    this.deviceRegistrationLambda.addToRolePolicy(new iam.PolicyStatement({
      actions: [
        'iot:CreateThing',
        'iot:DescribeThing',
        'iot:CreateKeysAndCertificate',
        'iot:AttachPolicy',
        'iot:AttachThingPrincipal'
      ],
      resources: ['*']
    }));

    // Create API Gateway
    this.deviceRegistrationApi = new apigateway.RestApi(this, 'DeviceRegistrationApi', {
      restApiName: `device-registration-api-${envName}`,
      description: 'API for device registration',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS
      }
    });

    // Create Cognito authorizer
    const authorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'DeviceApiAuthorizer', {
      cognitoUserPools: [props.userPool]
    });

    // Create API resources and methods
    const devicesResource = this.deviceRegistrationApi.root.addResource('devices');
    
    // POST /devices - Register a new device
    devicesResource.addMethod('POST', new apigateway.LambdaIntegration(this.deviceRegistrationLambda), {
      authorizer,
      authorizationType: apigateway.AuthorizationType.COGNITO
    });

    // Output the API URL
    new cdk.CfnOutput(this, 'DeviceRegistrationApiUrl', {
      value: this.deviceRegistrationApi.url,
      description: 'URL for device registration API',
      exportName: `DeviceRegistrationApiUrl-${envName}`
    });
  }
}