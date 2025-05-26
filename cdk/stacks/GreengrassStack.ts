import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as path from 'path';
import { SSM_PATHS } from '../utils/param-paths';

interface GreengrassStackProps extends cdk.StackProps {
  envName: string;
}

export class GreengrassStack extends cdk.Stack {
  public readonly componentBucket: s3.Bucket;

  constructor(scope: Construct, id: string, props: GreengrassStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';

    // Create S3 bucket for Greengrass components
    this.componentBucket = new s3.Bucket(this, 'ComponentBucket', {
      bucketName: `smart-home-greengrass-components-${envName}-${this.account}`,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      versioned: true,
    });

    // Create IAM role for Greengrass core devices
    const greengrassCoreRole = new iam.Role(this, 'GreengrassCoreRole', {
      assumedBy: new iam.ServicePrincipal('credentials.iot.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
      ],
    });

    // Add custom policy for Greengrass operations
    greengrassCoreRole.addToPolicy(new iam.PolicyStatement({
      actions: [
        'greengrass:*',
        'iot:*',
        's3:GetObject',
        'logs:CreateLogGroup',
        'logs:CreateLogStream',
        'logs:PutLogEvents',
        'logs:DescribeLogStreams',
      ],
      resources: ['*'],
    }));

    // Create Lambda function for local inference
    const localInferenceFunction = new lambda.Function(this, 'LocalInferenceFunction', {
      runtime: lambda.Runtime.PYTHON_3_9,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda/greengrass')),
      handler: 'local_inference.handler',
      timeout: cdk.Duration.seconds(30),
      environment: {
        STAGE: props.envName,
      },
      description: 'Performs local inference on IoT device data',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME('SmartHomeApp', envName, 'local-inference'),
    });

    // Create Lambda function for local automation
    const localAutomationFunction = new lambda.Function(this, 'LocalAutomationFunction', {
      runtime: lambda.Runtime.PYTHON_3_9,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda/greengrass')),
      handler: 'local_automation.handler',
      timeout: cdk.Duration.seconds(30),
      environment: {
        STAGE: props.envName,
      },
      description: 'Handles local automation rules for IoT devices',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME('SmartHomeApp', envName, 'local-automation'),
    });

    // Store in SSM for other stacks to use
    new ssm.StringParameter(this, 'ComponentBucketNameParam', {
      parameterName: `/greengrass/${envName}/component-bucket`,
      stringValue: this.componentBucket.bucketName,
      description: 'S3 bucket for Greengrass components',
    });

    new ssm.StringParameter(this, 'GreengrassCoreRoleArnParam', {
      parameterName: `/greengrass/${envName}/core-role-arn`,
      stringValue: greengrassCoreRole.roleArn,
      description: 'IAM role ARN for Greengrass core devices',
    });

    // Export outputs
    new cdk.CfnOutput(this, 'ComponentBucketName', {
      value: this.componentBucket.bucketName,
      description: 'S3 bucket for Greengrass components',
      exportName: `ComponentBucketName-${envName}`,
    });

    new cdk.CfnOutput(this, 'GreengrassCoreRoleArn', {
      value: greengrassCoreRole.roleArn,
      description: 'IAM role ARN for Greengrass core devices',
      exportName: `GreengrassCoreRoleArn-${envName}`,
    });

    new cdk.CfnOutput(this, 'LocalInferenceFunctionName', {
      value: localInferenceFunction.functionName,
      description: 'Lambda function for local inference',
      exportName: `LocalInferenceFunctionName-${envName}`,
    });

    new cdk.CfnOutput(this, 'LocalAutomationFunctionName', {
      value: localAutomationFunction.functionName,
      description: 'Lambda function for local automation',
      exportName: `LocalAutomationFunctionName-${envName}`,
    });
  }
}