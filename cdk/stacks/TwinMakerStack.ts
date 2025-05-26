import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as path from 'path';
import { SSM_PATHS } from '../utils/param-paths';

interface TwinMakerStackProps extends cdk.StackProps {
  envName: string;
}

export class TwinMakerStack extends cdk.Stack {
  public readonly twinMakerRole: iam.Role;
  public readonly assetBucket: s3.Bucket;

  constructor(scope: Construct, id: string, props: TwinMakerStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';

    // Create S3 bucket for TwinMaker assets
    this.assetBucket = new s3.Bucket(this, 'TwinMakerAssetBucket', {
      bucketName: `smart-home-twinmaker-assets-${envName}-${this.account}`,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      versioned: true,
    });

    // Create IAM role for TwinMaker
    this.twinMakerRole = new iam.Role(this, 'TwinMakerRole', {
      assumedBy: new iam.ServicePrincipal('iottwinmaker.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonS3ReadOnlyAccess'),
      ],
    });

    // Add custom policy for TwinMaker operations
    this.twinMakerRole.addToPolicy(new iam.PolicyStatement({
      actions: [
        's3:GetObject',
        's3:PutObject',
        's3:ListBucket',
      ],
      resources: [
        this.assetBucket.bucketArn,
        `${this.assetBucket.bucketArn}/*`,
      ],
    }));

    // Create Lambda function for Matter protocol bridge
    const matterBridgeFunction = new lambda.Function(this, 'MatterBridgeFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'matter.bridgeHandler',
      timeout: cdk.Duration.seconds(30),
      environment: {
        STAGE: props.envName,
      },
      description: 'Bridges Matter protocol devices to AWS IoT',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME('SmartHomeApp', envName, 'matter-bridge'),
    });

    // Create Lambda function for Zigbee protocol bridge
    const zigbeeBridgeFunction = new lambda.Function(this, 'ZigbeeBridgeFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'zigbee.bridgeHandler',
      timeout: cdk.Duration.seconds(30),
      environment: {
        STAGE: props.envName,
      },
      description: 'Bridges Zigbee protocol devices to AWS IoT',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME('SmartHomeApp', envName, 'zigbee-bridge'),
    });

    // Create Lambda function for digital twin updates
    const digitalTwinUpdateFunction = new lambda.Function(this, 'DigitalTwinUpdateFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'twinmaker.updateTwin',
      timeout: cdk.Duration.seconds(30),
      environment: {
        STAGE: props.envName,
        ASSET_BUCKET: this.assetBucket.bucketName,
      },
      description: 'Updates digital twins based on device state changes',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME('SmartHomeApp', envName, 'digital-twin-update'),
    });

    // Grant the function access to the S3 bucket
    this.assetBucket.grantReadWrite(digitalTwinUpdateFunction);

    // Store in SSM for other stacks to use
    new ssm.StringParameter(this, 'TwinMakerAssetBucketParam', {
      parameterName: `/twinmaker/${envName}/asset-bucket`,
      stringValue: this.assetBucket.bucketName,
      description: 'S3 bucket for TwinMaker assets',
    });

    new ssm.StringParameter(this, 'TwinMakerRoleArnParam', {
      parameterName: `/twinmaker/${envName}/role-arn`,
      stringValue: this.twinMakerRole.roleArn,
      description: 'IAM role ARN for TwinMaker',
    });

    // Export outputs
    new cdk.CfnOutput(this, 'TwinMakerAssetBucketName', {
      value: this.assetBucket.bucketName,
      description: 'S3 bucket for TwinMaker assets',
      exportName: `TwinMakerAssetBucketName-${envName}`,
    });

    new cdk.CfnOutput(this, 'TwinMakerRoleArn', {
      value: this.twinMakerRole.roleArn,
      description: 'IAM role ARN for TwinMaker',
      exportName: `TwinMakerRoleArn-${envName}`,
    });

    new cdk.CfnOutput(this, 'MatterBridgeFunctionName', {
      value: matterBridgeFunction.functionName,
      description: 'Lambda function for Matter protocol bridge',
      exportName: `MatterBridgeFunctionName-${envName}`,
    });

    new cdk.CfnOutput(this, 'ZigbeeBridgeFunctionName', {
      value: zigbeeBridgeFunction.functionName,
      description: 'Lambda function for Zigbee protocol bridge',
      exportName: `ZigbeeBridgeFunctionName-${envName}`,
    });
  }
}