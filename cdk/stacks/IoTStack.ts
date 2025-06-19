import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as iam from 'aws-cdk-lib/aws-iam';

export interface IoTStackProps extends cdk.StackProps {
  envName: string;
  deviceRegistrationLambda: lambda.Function;
}

export class IoTStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: IoTStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';

    // IoT Policy for your devices
    const iotPolicy = new iot.CfnPolicy(this, 'DevicePolicy', {
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
            Resource: ['*']
          }
        ]
      },
      policyName: `SmartHomeIoTPolicy-${envName}`, // Make policy name unique
    });

<<<<<<< Updated upstream
    // Example Topic Rule (Trigger Lambda or Bedrock AI)
    const topicRule = new iot.CfnTopicRule(this, 'AutomationTriggerRule', {
      topicRulePayload: {
        sql: `SELECT * FROM 'smart/home/${envName}/+/status'`, // Optionally add envName to topic
        actions: [
          {
            lambda: {
              functionArn: 'arn:aws:lambda:your-region:account-id:function:AutomationHandler'
            }
          }
        ],
        ruleDisabled: false
      }
    });

    // Export outputs for use in other stacks (like AIStack)
    new cdk.CfnOutput(this, 'IoTTopicRuleName', {
      value: topicRule.ref,
      exportName: `IoTTopicRuleName-${envName}` // Make export name unique
    });

    new cdk.CfnOutput(this, 'IoTPolicyName', {
      value: iotPolicy.policyName!,
      exportName: `IoTPolicyName-${envName}` // Make export name unique
=======
    // Create IoT Rule to invoke device registration Lambda
    const deviceRegistrationRule = new iot.CfnTopicRule(this, 'DeviceRegistrationRule', {
      ruleName: `DeviceRegistration${envName}`,
      topicRulePayload: {
        sql: "SELECT * FROM 'devices/+/describe'",
        actions: [
          {
            lambda: {
              functionArn: props.deviceRegistrationLambda.functionArn
            }
          }
        ],
        ruleDisabled: false
      }
    });

    // Grant IoT permission to invoke the Lambda
    new lambda.CfnPermission(this, 'AllowIoTInvokeDeviceRegistration', {
      action: 'lambda:InvokeFunction',
      functionName: props.deviceRegistrationLambda.functionArn,
      principal: 'iot.amazonaws.com',
      sourceArn: deviceRegistrationRule.attrArn
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
          UserId: { Type: 'String', Default: '' }
        },
        Resources: {
          thing: {
            Type: 'AWS::IoT::Thing',
            Properties: {
              ThingName: { Ref: 'ThingName' },
              AttributePayload: {
                location: { Ref: 'DeviceLocation' },
                deviceType: { Ref: 'DeviceType' },
                userId: { Ref: 'UserId' }
              }
            }
          },
          certificate: {
            Type: 'AWS::IoT::Certificate',
            Properties: {
              CertificateId: { Ref: 'AWS::IoT::Certificate::Id' },
              Status: 'ACTIVE'
            }
          },
          policy: {
            Type: 'AWS::IoT::Policy',
            Properties: {
              PolicyName: 'SmartHomeIoTPolicy-dev'
            }
          }
        }
      })
    });

    // Get IoT endpoint using custom resource
    const iotEndpointProvider = new cr.AwsCustomResource(this, 'IotEndpointProvider', {
      onUpdate: {
        service: 'Iot',
        action: 'describeEndpoint',
        parameters: {
          endpointType: 'iot:Data-ATS'
        },
        physicalResourceId: cr.PhysicalResourceId.of('IoTEndpoint')
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE
      })
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
>>>>>>> Stashed changes
    });
  }
}