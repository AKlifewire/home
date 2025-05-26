import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cw_actions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as path from 'path';
import { SSM_PATHS } from '../utils/param-paths';

interface MonitoringStackProps extends cdk.StackProps {
  envName: string;
  adminEmail?: string;
}

export class MonitoringStack extends cdk.Stack {
  public readonly alarmTopic: sns.Topic;

  constructor(scope: Construct, id: string, props: MonitoringStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';
    const adminEmail = props.adminEmail || 'admin@example.com';

    // Create SNS topic for alarms
    this.alarmTopic = new sns.Topic(this, 'AlarmTopic', {
      topicName: `SmartHomeAlarms-${envName}`,
      displayName: `Smart Home Alarms (${envName})`,
    });

    // Add email subscription
    this.alarmTopic.addSubscription(new subscriptions.EmailSubscription(adminEmail));

    // Create IoT Device Defender security profile
    const securityProfile = new iot.CfnSecurityProfile(this, 'IoTSecurityProfile', {
      securityProfileName: `SmartHomeSecurityProfile-${envName}`,
      securityProfileDescription: 'Security profile for Smart Home IoT devices',
      behaviors: [
        {
          name: 'MessageSizeLimit',
          metric: 'aws:message-byte-size',
          criteria: {
            comparisonOperator: 'greater-than',
            value: {
              count: '10240', // 10KB limit - using string as required by the API
            },
            consecutiveDatapointsToAlarm: 1,
            consecutiveDatapointsToClear: 1,
          },
        },
        {
          name: 'MessageRateLimit',
          metric: 'aws:num-messages-received',
          criteria: {
            comparisonOperator: 'greater-than',
            value: {
              count: '100', // 100 messages per minute limit - using string as required by the API
            },
            durationSeconds: 60,
            consecutiveDatapointsToAlarm: 1,
            consecutiveDatapointsToClear: 1,
          },
        },
        {
          name: 'ConnectionAttempts',
          metric: 'aws:num-connection-attempts',
          criteria: {
            comparisonOperator: 'greater-than',
            value: {
              count: '10', // 10 connection attempts per minute limit - using string as required by the API
            },
            durationSeconds: 60,
            consecutiveDatapointsToAlarm: 1,
            consecutiveDatapointsToClear: 1,
          },
        },
      ],
      alertTargets: {
        'SNS': {
          alertTargetArn: this.alarmTopic.topicArn,
          roleArn: new iam.Role(this, 'IoTAlertRole', {
            assumedBy: new iam.ServicePrincipal('iot.amazonaws.com'),
            managedPolicies: [
              iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AmazonIoTDeviceDefenderPublishFindingsToSNSMitigationAction'),
            ],
          }).roleArn,
        },
      },
    });

    // Create Lambda function for processing alerts
    const alertProcessorFunction = new lambda.Function(this, 'AlertProcessorFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'monitoring.processAlert',
      timeout: cdk.Duration.seconds(30),
      environment: {
        STAGE: props.envName,
        ALARM_TOPIC_ARN: this.alarmTopic.topicArn,
      },
      description: 'Processes IoT alerts and takes action',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME('SmartHomeApp', envName, 'alert-processor'),
    });

    // Allow the Lambda to publish to SNS
    this.alarmTopic.grantPublish(alertProcessorFunction);

    // Create CloudWatch alarms for Lambda errors
    const lambdaErrorsMetric = new cloudwatch.Metric({
      namespace: 'AWS/Lambda',
      metricName: 'Errors',
      dimensionsMap: {
        FunctionName: alertProcessorFunction.functionName,
      },
      statistic: 'Sum',
      period: cdk.Duration.minutes(1),
    });

    const lambdaErrorsAlarm = new cloudwatch.Alarm(this, 'LambdaErrorsAlarm', {
      metric: lambdaErrorsMetric,
      threshold: 1,
      evaluationPeriods: 1,
      alarmDescription: `Alert when ${alertProcessorFunction.functionName} has errors`,
      alarmName: `${alertProcessorFunction.functionName}-Errors-${envName}`,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });

    lambdaErrorsAlarm.addAlarmAction(new cw_actions.SnsAction(this.alarmTopic));

    // Create CloudWatch dashboard
    const dashboard = new cloudwatch.Dashboard(this, 'SmartHomeDashboard', {
      dashboardName: `SmartHome-${envName}-Dashboard`,
    });

    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'Lambda Errors',
        left: [lambdaErrorsMetric],
        width: 12,
      }),
      new cloudwatch.GraphWidget({
        title: 'IoT Messages',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/IoT',
            metricName: 'PublishIn.Success',
            statistic: 'Sum',
            period: cdk.Duration.minutes(1),
          }),
        ],
        width: 12,
      })
    );

    // Store in SSM for other stacks to use
    new ssm.StringParameter(this, 'AlarmTopicArnParam', {
      parameterName: SSM_PATHS.MONITORING.ALARM_TOPIC_ARN(envName),
      stringValue: this.alarmTopic.topicArn,
      description: 'SNS topic ARN for alarms',
    });

    // Export outputs
    new cdk.CfnOutput(this, 'AlarmTopicArn', {
      value: this.alarmTopic.topicArn,
      description: 'SNS topic ARN for alarms',
      exportName: `AlarmTopicArn-${envName}`,
    });

    new cdk.CfnOutput(this, 'SecurityProfileName', {
      value: securityProfile.securityProfileName!,
      description: 'IoT Device Defender security profile name',
      exportName: `SecurityProfileName-${envName}`,
    });

    new cdk.CfnOutput(this, 'DashboardName', {
      value: dashboard.dashboardName,
      description: 'CloudWatch dashboard name',
      exportName: `DashboardName-${envName}`,
    });
  }
}