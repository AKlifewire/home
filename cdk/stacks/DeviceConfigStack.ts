import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as path from 'path';

interface DeviceConfigStackProps extends cdk.StackProps {
  envName: string;
  uiJsonBucket: s3.Bucket;
  devicesTable?: cdk.aws_dynamodb.Table;
}

export class DeviceConfigStack extends cdk.Stack {
  public readonly deviceConfigLambda: lambda.Function;

  constructor(scope: Construct, id: string, props: DeviceConfigStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';

    // Create Lambda function to process device configs
    this.deviceConfigLambda = new lambda.Function(this, 'DeviceConfigToUiLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'device-config-to-ui.handler',
      timeout: cdk.Duration.seconds(30),
      environment: {
        UI_BUCKET: props.uiJsonBucket.bucketName,
        DEVICES_TABLE: props.devicesTable?.tableName || '',
      },
      description: 'Converts device configs to UI layouts',
      functionName: `SmartHome-${envName}-device-config-to-ui`,
    });

    // Grant Lambda permissions to write to S3 bucket
    props.uiJsonBucket.grantReadWrite(this.deviceConfigLambda);

    // Grant Lambda permissions to write to DynamoDB if table is provided
    if (props.devicesTable) {
      props.devicesTable.grantReadWriteData(this.deviceConfigLambda);
    }

    // Create IoT Rule to trigger Lambda when device publishes config
    const deviceConfigRule = new iot.CfnTopicRule(this, 'DeviceConfigRule', {
      ruleName: `DeviceConfigToUi${envName}`,
      topicRulePayload: {
        sql: "SELECT * FROM 'device/+/config'",
        actions: [
          {
            lambda: {
              functionArn: this.deviceConfigLambda.functionArn
            }
          }
        ],
        ruleDisabled: false
      }
    });

    // Grant IoT permission to invoke the Lambda
    new lambda.CfnPermission(this, 'AllowIoTInvokeDeviceConfig', {
      action: 'lambda:InvokeFunction',
      functionName: this.deviceConfigLambda.functionName,
      principal: 'iot.amazonaws.com',
      sourceArn: deviceConfigRule.attrArn
    });

    // Output the Lambda ARN
    new cdk.CfnOutput(this, 'DeviceConfigLambdaArn', {
      value: this.deviceConfigLambda.functionArn,
      description: 'Lambda function ARN for device config processing',
      exportName: `DeviceConfigLambdaArn-${envName}`,
    });
  }
}