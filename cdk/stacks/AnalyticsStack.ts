import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as timestream from 'aws-cdk-lib/aws-timestream';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as path from 'path';

interface AnalyticsStackProps extends cdk.StackProps {
  envName: string;
}

export class AnalyticsStack extends cdk.Stack {
  public readonly timestreamDatabase: timestream.CfnDatabase;
  public readonly timestreamTable: timestream.CfnTable;

  constructor(scope: Construct, id: string, props: AnalyticsStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';

    // Create Timestream database for analytics
    this.timestreamDatabase = new timestream.CfnDatabase(this, 'AnalyticsDatabase', {
      databaseName: `SmartHomeAnalytics${envName}`,
    });

    // Create Timestream table for device metrics
    this.timestreamTable = new timestream.CfnTable(this, 'DeviceMetricsTable', {
      databaseName: this.timestreamDatabase.databaseName!,
      tableName: 'DeviceMetrics',
      retentionProperties: {
        MemoryStoreRetentionPeriodInHours: '24',
        MagneticStoreRetentionPeriodInDays: '90',
      },
    });
    this.timestreamTable.addDependency(this.timestreamDatabase);

    // Create IAM role for Lambda to access Timestream
    const analyticsLambdaRole = new iam.Role(this, 'AnalyticsLambdaRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Add Timestream permissions
    analyticsLambdaRole.addToPolicy(new iam.PolicyStatement({
      actions: [
        'timestream:DescribeDatabase',
        'timestream:DescribeTable',
        'timestream:WriteRecords',
        'timestream:Select',
        'timestream:ListMeasures',
      ],
      resources: [
        `arn:aws:timestream:${this.region}:${this.account}:database/${this.timestreamDatabase.databaseName}`,
        `arn:aws:timestream:${this.region}:${this.account}:database/${this.timestreamDatabase.databaseName}/table/${this.timestreamTable.tableName}`,
      ],
    }));

    // Create Lambda function for anomaly detection
    const anomalyDetectionFunction = new lambda.Function(this, 'AnomalyDetectionFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'analytics.detectAnomalies',
      timeout: cdk.Duration.seconds(60),
      role: analyticsLambdaRole,
      environment: {
        TIMESTREAM_DATABASE: this.timestreamDatabase.databaseName!,
        TIMESTREAM_TABLE: this.timestreamTable.tableName!,
        STAGE: envName,
      },
      description: 'Detects anomalies in device metrics',
      functionName: `SmartHomeApp-${envName}-lambda-anomaly-detection`,
    });

    // Create Lambda function for generating insights
    const insightsFunction = new lambda.Function(this, 'InsightsFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'analytics.generateInsights',
      timeout: cdk.Duration.seconds(60),
      role: analyticsLambdaRole,
      environment: {
        TIMESTREAM_DATABASE: this.timestreamDatabase.databaseName!,
        TIMESTREAM_TABLE: this.timestreamTable.tableName!,
        STAGE: envName,
      },
      description: 'Generates insights from device metrics',
      functionName: `SmartHomeApp-${envName}-lambda-insights`,
    });

    // Schedule anomaly detection to run every hour
    const anomalyDetectionRule = new events.Rule(this, 'AnomalyDetectionRule', {
      schedule: events.Schedule.rate(cdk.Duration.hours(1)),
      description: 'Trigger anomaly detection every hour',
    });

    anomalyDetectionRule.addTarget(new targets.LambdaFunction(anomalyDetectionFunction));

    // Schedule insights generation to run daily
    const insightsRule = new events.Rule(this, 'InsightsRule', {
      schedule: events.Schedule.rate(cdk.Duration.days(1)),
      description: 'Generate insights daily',
    });

    insightsRule.addTarget(new targets.LambdaFunction(insightsFunction));

    // Store database and table names in SSM
    new ssm.StringParameter(this, 'TimestreamDatabaseParam', {
      parameterName: `/analytics/${envName}/timestream-database`,
      stringValue: this.timestreamDatabase.databaseName!,
      description: 'Timestream database for analytics',
    });

    new ssm.StringParameter(this, 'TimestreamTableParam', {
      parameterName: `/analytics/${envName}/timestream-table`,
      stringValue: this.timestreamTable.tableName!,
      description: 'Timestream table for device metrics',
    });

    // Export outputs
    new cdk.CfnOutput(this, 'TimestreamDatabaseName', {
      value: this.timestreamDatabase.databaseName!,
      description: 'Timestream database for analytics',
      exportName: `TimestreamDatabaseName-${envName}`,
    });

    new cdk.CfnOutput(this, 'TimestreamTableName', {
      value: this.timestreamTable.tableName!,
      description: 'Timestream table for device metrics',
      exportName: `TimestreamTableName-${envName}`,
    });
  }
}