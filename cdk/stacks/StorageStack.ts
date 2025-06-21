import * as cdk from 'aws-cdk-lib';
import { Stack, StackProps, RemovalPolicy } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';

interface StorageStackProps extends StackProps {
  envName?: string;
}

export class StorageStack extends Stack {
  public readonly uiBucket: s3.Bucket;

  constructor(scope: Construct, id: string, props?: StorageStackProps) {
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
  }
}