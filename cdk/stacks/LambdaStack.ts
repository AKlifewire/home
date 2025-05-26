import { Stack, StackProps, Duration } from 'aws-cdk-lib';
import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as path from 'path';
import { createLambdaSsmParameter } from '../utils/auto-ssm';
import { SSM_PATHS } from '../utils/param-paths';

interface LambdaStackProps extends StackProps {
  app: string;
  envName: string;
  userPoolId: string;
  identityPoolId: string;
  iotEndpoint: string;
  storageBucket: s3.IBucket;
  otaBucket?: s3.IBucket;
  logsBucket?: s3.IBucket;
}

export class LambdaStack extends Stack {
  public readonly lambdaFunctions: { [key: string]: lambda.Function } = {};

  constructor(scope: Construct, id: string, props: LambdaStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';
    const lambdaDir = './lambda'; // Point to the lambda directory

    // Create DynamoDB tables for device management
    const devicesTable = new dynamodb.Table(this, 'DevicesTable', {
      tableName: `SmartHomeDevices-${envName}`,
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Add GSI for querying devices by userId
    devicesTable.addGlobalSecondaryIndex({
      indexName: 'UserDevicesIndex',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    // Create DynamoDB table for device status
    const deviceStatusTable = new dynamodb.Table(this, 'DeviceStatusTable', {
      tableName: `SmartHomeDeviceStatus-${envName}`,
      partitionKey: { name: 'deviceId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'statusType', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      timeToLiveAttribute: 'ttl',
    });

    // Create Lambda execution role with permissions
    const lambdaRole = new iam.Role(this, 'LambdaExecutionRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMReadOnlyAccess'),
      ],
    });

    // Add permissions to the role
    lambdaRole.addToPolicy(new iam.PolicyStatement({
      actions: [
        'iot:Publish',
        'iot:Connect',
        'iot:Subscribe',
        'iot:Receive',
        'iot:DescribeThing',
        'iot:ListThings',
        'iot:UpdateThing',
        'iot:CreateThing',
        'iot:DeleteThing',
      ],
      resources: ['*'],
    }));

    lambdaRole.addToPolicy(new iam.PolicyStatement({
      actions: [
        'dynamodb:GetItem',
        'dynamodb:PutItem',
        'dynamodb:UpdateItem',
        'dynamodb:DeleteItem',
        'dynamodb:Query',
        'dynamodb:Scan',
      ],
      resources: [
        devicesTable.tableArn,
        deviceStatusTable.tableArn,
        `${devicesTable.tableArn}/index/*`,
      ],
    }));

    // Define Lambda functions
    const lambdaConfigs = [
      { name: 'get-ui-page', handler: 'ui-page.handler', description: 'Retrieves UI configuration for devices' },
      { name: 'get-my-devices', handler: 'devices.getDevices', description: 'Lists devices for a user' },
      { name: 'get-device-state', handler: 'devices.getDeviceState', description: 'Gets current state of a device' },
      { name: 'control-relay', handler: 'control.relayControl', description: 'Controls device relays via MQTT' },
      { name: 'register-device', handler: 'devices.registerDevice', description: 'Links a device to a user' },
      { name: 'remove-device', handler: 'devices.removeDevice', description: 'Removes a device from a user' },
      { name: 'device-registration', handler: 'iot.deviceRegistration', description: 'Processes new device registrations' },
      { name: 'get-analytics', handler: 'analytics.getAnalytics', description: 'Retrieves device analytics data' },
      { name: 'get-ui-json', handler: 'ui-json-handler.getUiJson', description: 'Retrieves UI JSON configurations from S3' },
    ];

    // Create Lambda functions
    lambdaConfigs.forEach(({ name, handler, description }) => {
      const [handlerFile, handlerMethod] = handler.split('.');
      
      const fn = new lambda.Function(this, `${name}Function`, {
        runtime: lambda.Runtime.NODEJS_18_X,
        code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
        handler: `${handlerFile}.${handlerMethod}`,
        timeout: Duration.seconds(30),
        role: lambdaRole,
        environment: {
          STAGE: props.envName,
          UI_BUCKET: props.storageBucket.bucketName,
          DEVICES_TABLE: devicesTable.tableName,
          DEVICE_STATUS_TABLE: deviceStatusTable.tableName,
          IOT_ENDPOINT: props.iotEndpoint,
          USER_POOL_ID: props.userPoolId,
          IDENTITY_POOL_ID: props.identityPoolId,
          OTA_BUCKET: props.otaBucket?.bucketName || props.storageBucket.bucketName,
          LOGS_BUCKET: props.logsBucket?.bucketName || '',
        },
        description,
        functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME(props.app, envName, name),
      });

      // Grant S3 read access to the function
      props.storageBucket.grantRead(fn);
      
      // Grant OTA bucket access if provided
      if (props.otaBucket) {
        props.otaBucket.grantRead(fn);
      }
      
      // Grant logs bucket access if provided
      if (props.logsBucket) {
        props.logsBucket.grantWrite(fn);
      }
      
      // Store function reference
      this.lambdaFunctions[name] = fn;
      
      // Create SSM parameter for the function
      createLambdaSsmParameter(this, props.app, envName, name, fn.functionName);
    });

    // Create a Lambda function for automation rules
    const automationFunction = new lambda.Function(this, 'AutomationFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'automation.processRules',
      timeout: Duration.seconds(60),
      role: lambdaRole,
      environment: {
        STAGE: props.envName,
        DEVICES_TABLE: devicesTable.tableName,
        DEVICE_STATUS_TABLE: deviceStatusTable.tableName,
        IOT_ENDPOINT: props.iotEndpoint,
      },
      description: 'Processes automation rules for devices',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME(props.app, envName, 'automation'),
    });

    this.lambdaFunctions['automation'] = automationFunction;
    createLambdaSsmParameter(this, props.app, envName, 'automation', automationFunction.functionName);

    // Create a Lambda function for OTA updates
    const otaUpdateFunction = new lambda.Function(this, 'OTAUpdateFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'ota.processUpdate',
      timeout: Duration.seconds(60),
      role: lambdaRole,
      environment: {
        STAGE: props.envName,
        DEVICES_TABLE: devicesTable.tableName,
        FIRMWARE_BUCKET: props.otaBucket?.bucketName || props.storageBucket.bucketName,
        IOT_ENDPOINT: props.iotEndpoint,
      },
      description: 'Processes OTA firmware updates for devices',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME(props.app, envName, 'ota-update'),
    });

    // Grant OTA bucket access
    if (props.otaBucket) {
      props.otaBucket.grantReadWrite(otaUpdateFunction);
    } else {
      props.storageBucket.grantReadWrite(otaUpdateFunction);
    }

    this.lambdaFunctions['ota-update'] = otaUpdateFunction;
    createLambdaSsmParameter(this, props.app, envName, 'ota-update', otaUpdateFunction.functionName);

    // Export table names
    new cdk.CfnOutput(this, 'DevicesTableName', {
      value: devicesTable.tableName,
      description: 'DynamoDB table for device management',
      exportName: `DevicesTableName-${envName}`,
    });

    new cdk.CfnOutput(this, 'DeviceStatusTableName', {
      value: deviceStatusTable.tableName,
      description: 'DynamoDB table for device status',
      exportName: `DeviceStatusTableName-${envName}`,
    });
  }
}