import * as cdk from 'aws-cdk-lib';
import { Stack, StackProps, RemovalPolicy } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import { SSM_CONFIG, getSSMPath } from '../utils/config';

interface StorageStackProps extends StackProps {
  envName: string;
}

export class StorageStack extends Stack {
  public readonly uiBucket: s3.Bucket;

  constructor(scope: Construct, id: string, props: StorageStackProps) {
    super(scope, id, props);

    const envName = props.envName;

    this.uiBucket = new s3.Bucket(this, 'UiPageBucket', {
      bucketName: `smart-home-ui-pages-${envName}-${this.account}`,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      publicReadAccess: false,
      cors: [{
        allowedMethods: [s3.HttpMethods.GET],
        allowedOrigins: ['*'],
        allowedHeaders: ['*']
      }]
    });

    // Store bucket name in SSM
    new ssm.StringParameter(this, 'UiBucketParam', {
      parameterName: getSSMPath(envName, SSM_CONFIG.KEYS.UI_BUCKET),
      stringValue: this.uiBucket.bucketName,
      description: 'S3 bucket for UI pages'
    });
  }
}