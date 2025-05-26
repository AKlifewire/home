import * as cdk from 'aws-cdk-lib';
import { Stack, StackProps, RemovalPolicy } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import { SSM_PATHS } from '../utils/param-paths';

export class StorageStack extends Stack {
  public readonly uiBucket: s3.Bucket;
  public readonly otaBucket: s3.Bucket;
  public readonly logsBucket: s3.Bucket;
  public readonly bucket: s3.IBucket; // Main bucket reference for backward compatibility

  constructor(scope: Construct, id: string, props?: StackProps & { environment?: string }) {
    super(scope, id, props);

    const envName = props?.environment || 'dev'; // Get from props or default
    
    // Remove timestamp to avoid bucket recreation on each deployment
    const accountId = this.account.substring(0, 8); // Use part of account ID for uniqueness

    // UI Pages Bucket
    this.uiBucket = new s3.Bucket(this, 'UiPageBucket', {
      // Using a generic name without account ID to avoid conflicts
      // bucketName: `smart-home-ui-pages-${envName}-${accountId}`,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      publicReadAccess: false,
      cors: [
        {
          allowedMethods: [s3.HttpMethods.GET],
          allowedOrigins: ['*'],
          allowedHeaders: ['*'],
        },
      ],
    });

    // OTA Firmware Bucket
    this.otaBucket = new s3.Bucket(this, 'OtaFirmwareBucket', {
      // Using a generic name without account ID to avoid conflicts
      // bucketName: `smart-home-ota-firmware-${envName}-${accountId}`,
      removalPolicy: RemovalPolicy.RETAIN,
      versioned: true,
      publicReadAccess: false,
    });

    // Device Logs Bucket
    this.logsBucket = new s3.Bucket(this, 'DeviceLogsBucket', {
      // Using a generic name without account ID to avoid conflicts
      // bucketName: `smart-home-device-logs-${envName}-${accountId}`,
      removalPolicy: RemovalPolicy.RETAIN,
      lifecycleRules: [
        {
          id: 'ExpireOldLogs',
          enabled: true,
          expiration: cdk.Duration.days(90),
        },
      ],
    });

    // Deploy UI pages to the UI bucket - commented out as ui-pages directory doesn't exist
    /*
    new s3deploy.BucketDeployment(this, 'UploadUiPages', {
      destinationBucket: this.uiBucket,
      sources: [s3deploy.Source.asset('./ui-pages')],
    });
    */
    
    // Store in SSM for other stacks to use
    new cdk.aws_ssm.StringParameter(this, 'UiBucketNameParam', {
      parameterName: SSM_PATHS.UI.S3_BUCKET_NAME(envName),
      stringValue: this.uiBucket.bucketName,
      description: 'S3 bucket for UI pages',
    });

    new cdk.aws_ssm.StringParameter(this, 'UiBucketUrlParam', {
      parameterName: SSM_PATHS.UI.S3_BUCKET_URL(envName),
      stringValue: `https://${this.uiBucket.bucketName}.s3.${this.region}.amazonaws.com`,
      description: 'S3 bucket URL for UI pages',
    });

    new cdk.aws_ssm.StringParameter(this, 'OtaBucketNameParam', {
      parameterName: SSM_PATHS.OTA.BUCKET_NAME(envName),
      stringValue: this.otaBucket.bucketName,
      description: 'S3 bucket for OTA firmware',
    });

    new cdk.aws_ssm.StringParameter(this, 'OtaBucketUrlParam', {
      parameterName: SSM_PATHS.OTA.BUCKET_URL(envName),
      stringValue: `https://${this.otaBucket.bucketName}.s3.${this.region}.amazonaws.com`,
      description: 'S3 bucket URL for OTA firmware',
    });

    new cdk.aws_ssm.StringParameter(this, 'LogsBucketNameParam', {
      parameterName: SSM_PATHS.LOGS.BUCKET_NAME(envName),
      stringValue: this.logsBucket.bucketName,
      description: 'S3 bucket for device logs',
    });

    // Export outputs
    new cdk.CfnOutput(this, 'UiBucketName', {
      value: this.uiBucket.bucketName,
      description: 'S3 bucket for UI pages',
      exportName: `UiBucketName-${envName}`,
    });

    new cdk.CfnOutput(this, 'UiBucketUrl', {
      value: `https://${this.uiBucket.bucketName}.s3.${this.region}.amazonaws.com`,
      description: 'S3 bucket URL for UI pages',
      exportName: `UiBucketUrl-${envName}`,
    });

    new cdk.CfnOutput(this, 'OtaBucketName', {
      value: this.otaBucket.bucketName,
      description: 'S3 bucket for OTA firmware',
      exportName: `OtaBucketName-${envName}`,
    });

    new cdk.CfnOutput(this, 'OtaBucketUrl', {
      value: `https://${this.otaBucket.bucketName}.s3.${this.region}.amazonaws.com`,
      description: 'S3 bucket URL for OTA firmware',
      exportName: `OtaBucketUrl-${envName}`,
    });

    new cdk.CfnOutput(this, 'LogsBucketName', {
      value: this.logsBucket.bucketName,
      description: 'S3 bucket for device logs',
      exportName: `LogsBucketName-${envName}`,
    });
    
    // Expose for other stacks (for backward compatibility)
    this.bucket = this.uiBucket;
  }
}