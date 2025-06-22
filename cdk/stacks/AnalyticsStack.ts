import * as cdk from 'aws-cdk-lib';
import * as kinesis from 'aws-cdk-lib/aws-kinesis';
import * as kinesisanalytics from 'aws-cdk-lib/aws-kinesisanalytics';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as firehose from 'aws-cdk-lib/aws-kinesisfirehose';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface AnalyticsStackProps extends cdk.StackProps {
  envName: string;
}

export class AnalyticsStack extends cdk.Stack {
  public readonly deviceStream: kinesis.Stream;
  public readonly analyticsBucket: s3.Bucket;

  constructor(scope: Construct, id: string, props: AnalyticsStackProps) {
    super(scope, id, props);

    // Kinesis Stream for device telemetry
    this.deviceStream = new kinesis.Stream(this, 'DeviceTelemetryStream', {
      streamName: `SmartHome-${props.envName}-DeviceTelemetry`,
      shardCount: 2,
      retentionPeriod: cdk.Duration.days(7)
    });

    // S3 bucket for analytics data
    this.analyticsBucket = new s3.Bucket(this, 'AnalyticsBucket', {
      bucketName: `smarthome-${props.envName}-analytics-${this.account}`,
      versioned: true,
      lifecycleRules: [{
        id: 'DeleteOldData',
        expiration: cdk.Duration.days(365),
        transitions: [{
          storageClass: s3.StorageClass.INFREQUENT_ACCESS,
          transitionAfter: cdk.Duration.days(30)
        }, {
          storageClass: s3.StorageClass.GLACIER,
          transitionAfter: cdk.Duration.days(90)
        }]
      }]
    });

    // Firehose delivery stream
    const firehoseRole = new iam.Role(this, 'FirehoseRole', {
      assumedBy: new iam.ServicePrincipal('firehose.amazonaws.com'),
      inlinePolicies: {
        S3Policy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              actions: ['s3:PutObject', 's3:GetObject', 's3:ListBucket'],
              resources: [this.analyticsBucket.bucketArn, `${this.analyticsBucket.bucketArn}/*`]
            })
          ]
        })
      }
    });

    const deliveryStream = new firehose.CfnDeliveryStream(this, 'DeviceDataFirehose', {
      deliveryStreamName: `SmartHome-${props.envName}-DeviceData`,
      deliveryStreamType: 'KinesisStreamAsSource',
      kinesisStreamSourceConfiguration: {
        kinesisStreamArn: this.deviceStream.streamArn,
        roleArn: firehoseRole.roleArn
      },
      s3DestinationConfiguration: {
        bucketArn: this.analyticsBucket.bucketArn,
        prefix: 'device-data/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/',
        errorOutputPrefix: 'errors/',
        roleArn: firehoseRole.roleArn,
        bufferingHints: {
          sizeInMBs: 5,
          intervalInSeconds: 300
        },
        compressionFormat: 'GZIP'
      }
    });

    // Grant Firehose access to Kinesis
    this.deviceStream.grantRead(firehoseRole);

    new cdk.CfnOutput(this, 'DeviceStreamName', {
      value: this.deviceStream.streamName,
      description: 'Kinesis stream for device telemetry'
    });

    new cdk.CfnOutput(this, 'AnalyticsBucketName', {
      value: this.analyticsBucket.bucketName,
      description: 'S3 bucket for analytics data'
    });
  }
}