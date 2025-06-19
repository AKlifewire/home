import * as cdk from 'aws-cdk-lib';
import { Stack, StackProps, RemovalPolicy } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
<<<<<<< Updated upstream
=======
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { SSM_PATHS } from '../utils/param-paths';
>>>>>>> Stashed changes

interface StorageStackProps extends StackProps {
  environment?: string;
}

export class StorageStack extends Stack {
  public readonly uiBucket: s3.Bucket;
<<<<<<< Updated upstream

  constructor(scope: Construct, id: string, props?: StackProps & { envName?: string }) {
    super(scope, id, props);

    const envName = props?.envName || 'dev'; // Get from props or default

    this.uiBucket = new s3.Bucket(this, 'UiPageBucket', {
      bucketName: `smart-home-ui-pages-${envName}-${this.account}`, // Make bucket name unique per environment
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      publicReadAccess: false,
    });

    new s3deploy.BucketDeployment(this, 'UploadUiPages', {
      destinationBucket: this.uiBucket,
      sources: [s3deploy.Source.asset('./ui-pages')],
    });
=======
  public readonly otaBucket: s3.Bucket;
  public readonly logsBucket: s3.Bucket;
  public readonly devicesTable: dynamodb.Table;

  constructor(scope: Construct, id: string, props?: StorageStackProps) {
    super(scope, id, props);

    const envName = props?.environment || 'dev';
    const accountId = this.account.substring(0, 8);    // Create UI Pages Bucket
    this.uiBucket = new s3.Bucket(this, 'UiPageBucket', {
      removalPolicy: RemovalPolicy.RETAIN,
      versioned: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      cors: [
        {
          allowedMethods: [s3.HttpMethods.GET],
          allowedOrigins: ['*'],
          allowedHeaders: ['*'],
        },
      ],
      enforceSSL: true,
    });    // Create OTA Firmware Bucket
    this.otaBucket = new s3.Bucket(this, 'OtaFirmwareBucket', {
      removalPolicy: RemovalPolicy.RETAIN,
      versioned: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      enforceSSL: true,
    });    // Create Device Logs Bucket
    this.logsBucket = new s3.Bucket(this, 'DeviceLogsBucket', {
      removalPolicy: RemovalPolicy.RETAIN,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      enforceSSL: true,
      lifecycleRules: [
        {
          expiration: cdk.Duration.days(90),
          transitions: [
            {
              storageClass: s3.StorageClass.INFREQUENT_ACCESS,
              transitionAfter: cdk.Duration.days(30)
            },
            {
              storageClass: s3.StorageClass.INTELLIGENT_TIERING,
              transitionAfter: cdk.Duration.days(60)
            }
          ]
        },
      ],
    });    // Create DynamoDB table for device configurations
    this.devicesTable = new dynamodb.Table(this, 'DevicesTable', {
      tableName: `SmartHomeDevices-${envName}`,
      partitionKey: { name: 'deviceId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'type', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: RemovalPolicy.RETAIN,
      pointInTimeRecovery: true,
      encryption: dynamodb.TableEncryption.AWS_MANAGED,
      timeToLiveAttribute: 'ttl',
      stream: dynamodb.StreamViewType.NEW_AND_OLD_IMAGES,
    });

    // Add GSIs for querying devices
    this.devicesTable.addGlobalSecondaryIndex({
      indexName: 'UserDevicesIndex',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'deviceId', type: dynamodb.AttributeType.STRING },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    this.devicesTable.addGlobalSecondaryIndex({
      indexName: 'DeviceTypeIndex',
      partitionKey: { name: 'type', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'deviceId', type: dynamodb.AttributeType.STRING },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    // Store bucket info in SSM Parameter Store
    new cdk.aws_ssm.StringParameter(this, 'UiBucketNameParam', {
      parameterName: SSM_PATHS.UI.S3_BUCKET_NAME(envName),
      stringValue: this.uiBucket.bucketName,
      description: 'S3 bucket for UI pages',
    });

    new cdk.aws_ssm.StringParameter(this, 'OtaBucketNameParam', {
      parameterName: SSM_PATHS.OTA.BUCKET_NAME(envName),
      stringValue: this.otaBucket.bucketName,
      description: 'S3 bucket for OTA firmware',
    });

    new cdk.aws_ssm.StringParameter(this, 'LogsBucketNameParam', {
      parameterName: SSM_PATHS.LOGS.BUCKET_NAME(envName),
      stringValue: this.logsBucket.bucketName,
      description: 'S3 bucket for device logs',
    });

    // Store table name in SSM Parameter Store
    new cdk.aws_ssm.StringParameter(this, 'DevicesTableNameParam', {
      parameterName: `/smart-home/${envName}/devices-table`,
      stringValue: this.devicesTable.tableName,
      description: 'DynamoDB table for device configurations',
    });

    // Export outputs
    new cdk.CfnOutput(this, 'UiBucketName', {
      value: this.uiBucket.bucketName,
      description: 'S3 bucket for UI pages',
      exportName: `UiBucketName-${envName}`,
    });

    new cdk.CfnOutput(this, 'OtaBucketName', {
      value: this.otaBucket.bucketName,
      description: 'S3 bucket for OTA firmware',
      exportName: `OtaBucketName-${envName}`,
    });

    new cdk.CfnOutput(this, 'LogsBucketName', {
      value: this.logsBucket.bucketName,
      description: 'S3 bucket for device logs',
      exportName: `LogsBucketName-${envName}`,
    });

    new cdk.CfnOutput(this, 'DevicesTableName', {
      value: this.devicesTable.tableName,
      description: 'DynamoDB table for device configurations',
      exportName: `DevicesTableName-${envName}`,
    });
>>>>>>> Stashed changes
  }
}