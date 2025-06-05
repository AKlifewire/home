import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as path from 'path';

interface DeviceConfigToUiStackProps extends cdk.StackProps {
  envName: string;
  uiBucket: s3.Bucket;
  devicesTable?: dynamodb.Table;
}

export class DeviceConfigToUiStack extends cdk.Stack {
  public readonly deviceConfigToUiLambda: lambda.Function;

  constructor(scope: Construct, id: string, props: DeviceConfigToUiStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';

    // Create Lambda function to process device configs and generate UI JSON
    this.deviceConfigToUiLambda = new lambda.Function(this, 'DeviceConfigToUiLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'device-config-to-ui.handler',
      timeout: cdk.Duration.seconds(30),
      environment: {
        UI_BUCKET: props.uiBucket.bucketName,
        DEVICES_TABLE: props.devicesTable?.tableName || '',
      },
      description: 'Converts device configurations to UI JSON layouts',
      functionName: 'device-config-to-ui', // Using the exact name expected by the test script
    });

    // Grant Lambda permissions to write to S3 bucket
    props.uiBucket.grantReadWrite(this.deviceConfigToUiLambda);

    // Grant Lambda permissions to read from DynamoDB if table is provided
    if (props.devicesTable) {
      props.devicesTable.grantReadData(this.deviceConfigToUiLambda);
    }

    // Create IoT Rule to trigger Lambda when device publishes config
    const deviceConfigRule = new iot.CfnTopicRule(this, 'DeviceConfigRule', {
      ruleName: `DeviceConfigToUi${envName}`,
      topicRulePayload: {
        sql: "SELECT * FROM 'device/+/config'",
        actions: [
          {
            lambda: {
              functionArn: this.deviceConfigToUiLambda.functionArn
            }
          }
        ],
        ruleDisabled: false
      }
    });

    // Grant IoT permission to invoke the Lambda
    new lambda.CfnPermission(this, 'AllowIoTInvokeDeviceConfig', {
      action: 'lambda:InvokeFunction',
      functionName: this.deviceConfigToUiLambda.functionName,
      principal: 'iot.amazonaws.com',
      sourceArn: deviceConfigRule.attrArn
    });

    // Output the Lambda ARN
    new cdk.CfnOutput(this, 'DeviceConfigToUiLambdaArn', {
      value: this.deviceConfigToUiLambda.functionArn,
      description: 'Lambda function ARN for device config to UI JSON processing',
      exportName: `DeviceConfigToUiLambdaArn-${envName}`,
    });
  }
}