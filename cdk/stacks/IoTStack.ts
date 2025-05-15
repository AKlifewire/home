import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as iam from 'aws-cdk-lib/aws-iam';

export class IoTStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

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
      policyName: 'SmartHomeIoTPolicy',
    });

    // Example Topic Rule (Trigger Lambda or Bedrock AI)
    const topicRule = new iot.CfnTopicRule(this, 'AutomationTriggerRule', {
      topicRulePayload: {
        sql: "SELECT * FROM 'smart/home/+/status'",
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
      exportName: 'IoTTopicRuleName'
    });

    new cdk.CfnOutput(this, 'IoTPolicyName', {
      value: iotPolicy.policyName!,
      exportName: 'IoTPolicyName'
    });
  }
}