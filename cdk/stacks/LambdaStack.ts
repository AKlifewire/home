import { Stack, StackProps, Duration } from 'aws-cdk-lib';
import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { createLambdaSsmParameter } from '../utils/auto-ssm';

interface LambdaStackProps extends StackProps {
  app: string;
  envName: string;
}

export class LambdaStack extends Stack {
  public readonly lambdaFunctions: { [key: string]: lambda.Function } = {};

  constructor(scope: Construct, id: string, props: LambdaStackProps) {
    super(scope, id, props);

    const lambdaDir = './dist/lambdas'; // Adjusted to point to the compiled output

    // Assume the S3 bucket is imported or created in another stack
    const uiBucket = s3.Bucket.fromBucketName(this, 'UiPageBucket', 'your-ui-pages-bucket-name');

    const lambdaConfigs = [
      { name: 'get-ui-page', path: `${lambdaDir}/resolvers` },
      { name: 'control-device', path: `${lambdaDir}/resolvers` },
      { name: 'get-analytics', path: `${lambdaDir}/resolvers` },
      { name: 'rule-engine', path: `${lambdaDir}/automation` },
      { name: 'emergency', path: `${lambdaDir}/automation` },
      { name: 'schedule', path: `${lambdaDir}/automation` },
      { name: 'device-control', path: `${lambdaDir}/iot` },
      { name: 'stripe-webhook', path: `${lambdaDir}/stripe` },
    ];

    const lambdaRole = new iam.Role(this, 'LambdaExecutionRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMReadOnlyAccess'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AWSIoTDataAccess'),
      ],
    });

    const envName = props.envName || 'dev'; // Get from props or default

    lambdaConfigs.forEach(({ name, path }) => {
      const fn = new lambda.Function(this, `${name}Function`, {
        runtime: lambda.Runtime.NODEJS_18_X,
        code: lambda.Code.fromAsset(path),
        handler: 'index.handler',
        timeout: Duration.seconds(10),
        role: lambdaRole,
        environment: {
          STAGE: props.envName,
          UI_BUCKET: uiBucket.bucketName,
        },
        functionName: `SmartHomeApp-${envName}-lambda-${name}`,
      });

      uiBucket.grantRead(fn);
      this.lambdaFunctions[name] = fn;

      // Use the helper for SSM parameter
      createLambdaSsmParameter(this, props.app, envName, name, fn.functionName);
    });

    new lambda.Function(this, 'DeviceControlFunction', {
      functionName: `SmartHomeApp-${envName}-lambda-device-control-unique-${cdk.Stack.of(this).stackName}`,
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(`${lambdaDir}/iot`),
      handler: 'index.handler',
      timeout: Duration.seconds(10),
      role: lambdaRole,
      environment: {
        STAGE: props.envName,
        UI_BUCKET: uiBucket.bucketName,
      },
    });
  }
}