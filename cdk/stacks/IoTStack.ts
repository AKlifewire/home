import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import { SSM_CONFIG, getSSMPath } from '../utils/config';

export interface IoTStackProps extends cdk.StackProps {
  envName: string;
}

export class IoTStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: IoTStackProps) {
    super(scope, id, props);

    const envName = props.envName;

    // Create IoT Topic Rule
    const topicRule = new iot.CfnTopicRule(this, 'AutomationTriggerRule', {
      topicRulePayload: {
        sql: `SELECT * FROM 'smart/home/${envName}/+/status'`,
        actions: [
          {
            lambda: {
              functionArn: 'arn:aws:lambda:us-east-1:879381241768:function:AutomationHandler'
            }
          }
        ],
        ruleDisabled: false
      }
    });

    // Store IoT endpoint in SSM
    new ssm.StringParameter(this, 'IoTEndpointParam', {
      parameterName: getSSMPath(envName, SSM_CONFIG.KEYS.IOT_ENDPOINT),
      stringValue: `${this.account}.iot.${this.region}.amazonaws.com`,
      description: 'IoT endpoint for device connections'
    });

    // Outputs
    new cdk.CfnOutput(this, 'IoTTopicRuleName', {
      value: topicRule.ref,
      exportName: `IoTTopicRuleName-${envName}`
    });

    new cdk.CfnOutput(this, 'IoTEndpoint', {
      value: `${this.account}.iot.${this.region}.amazonaws.com`,
      description: 'IoT endpoint for device connections'
    });
  }
}