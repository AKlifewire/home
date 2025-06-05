import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as timestream from 'aws-cdk-lib/aws-timestream';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as cr from 'aws-cdk-lib/custom-resources';

export interface IoTStackProps extends cdk.StackProps {
  envName: string;
}

export class IoTStack extends cdk.Stack {
  public readonly iotEndpoint: string;
  public readonly provisioningTemplateName: string;
  public readonly devicePolicy: iot.CfnPolicy;

  constructor(scope: Construct, id: string, props: IoTStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';

    // Create IoT Registry
    const iotRegistry = new iot.CfnThing(this, 'IoTRegistry', {
      thingName: `SmartHomeRegistry-${envName}`,
    });

    // IoT Policy for your devices
    this.devicePolicy = new iot.CfnPolicy(this, 'DevicePolicy', {
      policyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Action: ['iot:Connect'],
            Resource: [`arn:aws:iot:\${this.region}:\${this.account}:client/\${iot:Connection.Thing.ThingName}`]
          },
          {
            Effect: 'Allow',
            Action: ['iot:Publish'],
            Resource: [
              `arn:aws:iot:\${this.region}:\${this.account}:topic/iot/status/\${iot:Connection.Thing.ThingName}/*`,
              `arn:aws:iot:\${this.region}:\${this.account}:topic/iot/telemetry/\${iot:Connection.Thing.ThingName}`,
              `arn:aws:iot:\${this.region}:\${this.account}:topic/$aws/things/\${iot:Connection.Thing.ThingName}/*`
            ]
          },
          {
            Effect: 'Allow',
            Action: ['iot:Subscribe'],
            Resource: [
              `arn:aws:iot:\${this.region}:\${this.account}:topicfilter/iot/control/\${iot:Connection.Thing.ThingName}/*`,
              `arn:aws:iot:\${this.region}:\${this.account}:topicfilter/$aws/things/\${iot:Connection.Thing.ThingName}/*`
            ]
          },
          {
            Effect: 'Allow',
            Action: ['iot:Receive'],
            Resource: [
              `arn:aws:iot:\${this.region}:\${this.account}:topic/iot/control/\${iot:Connection.Thing.ThingName}/*`,
              `arn:aws:iot:\${this.region}:\${this.account}:topic/$aws/things/\${iot:Connection.Thing.ThingName}/*`
            ]
          }
        ]
      },
      policyName: `SmartHomeIoTPolicy-${envName}`,
    });

    // Create Fleet Provisioning Template
    const provisioningTemplate = new iot.CfnProvisioningTemplate(this, 'FleetProvisioningTemplate', {
      templateName: `SmartHomeProvisioningTemplate-${envName}`,
      description: 'Template for provisioning new IoT devices',
      enabled: true,
      provisioningRoleArn: new iam.Role(this, 'ProvisioningRole', {
        assumedBy: new iam.ServicePrincipal('iot.amazonaws.com'),
        managedPolicies: [
          iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSIoTThingsRegistration'),
        ],
      }).roleArn,
      templateBody: JSON.stringify({
        Parameters: {
          ThingName: { Type: 'String' },
          DeviceLocation: { Type: 'String', Default: 'unknown' },
          DeviceType: { Type: 'String', Default: 'esp32' },
          UserId: { Type: 'String', Default: '' },
        },
        Resources: {
          thing: {
            Type: 'AWS::IoT::Thing',
            Properties: {
              ThingName: { Ref: 'ThingName' },
              AttributePayload: {
                location: { Ref: 'DeviceLocation' },
                deviceType: { Ref: 'DeviceType' },
                userId: { Ref: 'UserId' },
              },
            },
          },
          certificate: {
            Type: 'AWS::IoT::Certificate',
            Properties: {
              CertificateId: { Ref: 'AWS::IoT::Certificate::Id' },
              Status: 'ACTIVE',
            },
          },
          policy: {
            Type: 'AWS::IoT::Policy',
            Properties: {
              PolicyName: this.devicePolicy.policyName,
            },
          },
        },
      }),
    });

    // Create a function to generate certificates
    const createCertificateFunction = new lambda.Function(this, 'CreateCertificateFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        const AWS = require('aws-sdk');
        exports.handler = async () => {
          const iot = new AWS.Iot();
          const certData = await iot.createKeysAndCertificate({ setAsActive: true }).promise();
          await iot.attachPolicy({
            policyName: process.env.POLICY_NAME,
            target: certData.certificateArn
          }).promise();
          return {
            certificateId: certData.certificateId,
            certificateArn: certData.certificateArn,
            certificatePem: certData.certificatePem,
            privateKey: certData.keyPair.PrivateKey
          };
        };
      `),
      timeout: cdk.Duration.seconds(30),
      environment: {
        POLICY_NAME: this.devicePolicy.policyName!
      },
      role: new iam.Role(this, 'CreateCertificateRole', {
        assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
        managedPolicies: [
          iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
          iam.ManagedPolicy.fromAwsManagedPolicyName('AWSIoTFullAccess'),
        ],
      }),
    });

    // Create S3 bucket for device logs
    const logsBucket = new s3.Bucket(this, 'DeviceLogsBucket', {
      bucketName: `smart-home-device-logs-${envName}-${this.account}-${cdk.Names.uniqueId(this)}`.toLowerCase(),
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Create Timestream database for telemetry
    const timestreamDb = new timestream.CfnDatabase(this, 'TelemetryDatabase', {
      databaseName: `SmartHomeTelemetry${envName}`,
    });
    timestreamDb.applyRemovalPolicy(cdk.RemovalPolicy.DESTROY);

    const timestreamTable = new timestream.CfnTable(this, 'TelemetryTable', {
      databaseName: timestreamDb.ref,
      tableName: 'DeviceTelemetry',
      retentionProperties: {
        MemoryStoreRetentionPeriodInHours: 24,
        MagneticStoreRetentionPeriodInDays: 30,
      },
    });
    timestreamTable.applyRemovalPolicy(cdk.RemovalPolicy.DESTROY);
    timestreamTable.addDependsOn(timestreamDb);

    // Create DynamoDB table for device status
    const deviceStatusTable = new dynamodb.Table(this, 'DeviceStatusTable', {
      tableName: 'DeviceStatus',
      partitionKey: { name: 'deviceId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'statusType', type: dynamodb.AttributeType.STRING },
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Create IoT Rules
    const telemetryRule = new iot.CfnTopicRule(this, 'TelemetryRule', {
      ruleName: `SmartHomeTelemetry${envName}`,
      topicRulePayload: {
        sql: "SELECT * FROM 'iot/telemetry/+'",
        actions: [{
          timestream: {
            databaseName: timestreamDb.databaseName!,
            tableName: timestreamTable.tableName!,
            dimensions: [
              { name: 'deviceId', value: '${topic(3)}' },
              { name: 'deviceType', value: '${deviceType}' }
            ],
            roleArn: new iam.Role(this, 'TimestreamRole', {
              assumedBy: new iam.ServicePrincipal('iot.amazonaws.com'),
              managedPolicies: [
                iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonTimestreamFullAccess'),
              ],
            }).roleArn,
          }
        }],
        ruleDisabled: false
      }
    });

    // === Device Registration IoT Rule ===
    // Find the device-registration Lambda from LambdaStack (must be passed in props)
    const deviceRegistrationLambdaArn = cdk.Fn.importValue(`smart-home-${envName}-lambda-device-registration`);
    
    const deviceRegistrationRule = new iot.CfnTopicRule(this, 'DeviceRegistrationRule', {
      ruleName: `DeviceRegistration${envName}`,
      topicRulePayload: {
        sql: "SELECT * FROM 'devices/+/describe'",
        actions: [
          {
            lambda: {
              functionArn: deviceRegistrationLambdaArn
            }
          }
        ],
        ruleDisabled: false
      }
    });
    // Grant IoT permission to invoke the Lambda
    new lambda.CfnPermission(this, 'AllowIoTInvokeDeviceRegistration', {
      action: 'lambda:InvokeFunction',
      functionName: deviceRegistrationLambdaArn,
      principal: 'iot.amazonaws.com',
      sourceArn: deviceRegistrationRule.attrArn
    });

    // Get IoT endpoint using a custom resource (DescribeEndpoint)
    const iotEndpointProvider = new cr.AwsCustomResource(this, 'DescribeIoTEndpoint', {
      onUpdate: {
        service: 'Iot',
        action: 'describeEndpoint',
        parameters: { endpointType: 'iot:Data-ATS' },
        physicalResourceId: cr.PhysicalResourceId.of('IoTEndpoint'),
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE}),
    });
    this.iotEndpoint = iotEndpointProvider.getResponseField('endpointAddress');
    this.provisioningTemplateName = provisioningTemplate.templateName!;

    // Store IoT endpoint in SSM
    new ssm.StringParameter(this, 'IoTEndpointParam', {
      parameterName: `/iot/${envName}/endpoint`,
      stringValue: this.iotEndpoint,
      description: 'IoT endpoint for device connection',
    });

    // Export outputs
    new cdk.CfnOutput(this, 'IoTEndpoint', {
      value: this.iotEndpoint,
      description: 'IoT endpoint for device connection',
      exportName: `IoTEndpoint-${envName}`,
    });

    new cdk.CfnOutput(this, 'ProvisioningTemplateName', {
      value: this.provisioningTemplateName,
      description: 'Fleet provisioning template name',
      exportName: `ProvisioningTemplateName-${envName}`,
    });
  }
}