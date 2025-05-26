import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as appsync from 'aws-cdk-lib/aws-appsync';
import * as path from 'path';

interface UiJsonStackProps extends cdk.StackProps {
  envName: string;
  api?: appsync.GraphqlApi;
  devicesTable?: dynamodb.Table;
}

export class UiJsonStack extends cdk.Stack {
  public readonly uiJsonBucket: s3.Bucket;
  public readonly uiJsonLambda: lambda.Function;

  constructor(scope: Construct, id: string, props: UiJsonStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';
    const accountId = this.account.substring(0, 8); // Use part of account ID for uniqueness

    // Create S3 bucket for UI JSON files with proper CORS configuration
    this.uiJsonBucket = new s3.Bucket(this, 'UiJsonBucket', {
      // Using a generic name without account ID to avoid conflicts
      // bucketName: `smart-home-ui-json-${envName}-${accountId}`,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      cors: [
        {
          allowedMethods: [
            s3.HttpMethods.GET,
            s3.HttpMethods.PUT,
            s3.HttpMethods.POST,
            s3.HttpMethods.HEAD,
          ],
          allowedOrigins: ['*'], // In production, restrict to your domains
          allowedHeaders: ['*'],
          exposedHeaders: ['ETag', 'x-amz-meta-custom-header'],
        },
      ],
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ACLS,
      publicReadAccess: false,
    });

    // Create Lambda function to handle UI JSON operations
    this.uiJsonLambda = new lambda.Function(this, 'UiJsonLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'ui-json-handler.getUiJson',
      timeout: cdk.Duration.seconds(30),
      environment: {
        UI_BUCKET: this.uiJsonBucket.bucketName,
        DEVICES_TABLE: props.devicesTable?.tableName || '',
      },
      description: 'Retrieves UI JSON configurations from S3',
      functionName: `SmartHome-${envName}-get-ui-json`,
    });

    // Create Lambda function for generating UI JSON
    const generateUiJsonLambda = new lambda.Function(this, 'GenerateUiJsonLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'ui-json-handler.generateUiJson',
      timeout: cdk.Duration.seconds(30),
      environment: {
        UI_BUCKET: this.uiJsonBucket.bucketName,
        DEVICES_TABLE: props.devicesTable?.tableName || '',
      },
      description: 'Generates and stores UI JSON configurations in S3',
      functionName: `SmartHome-${envName}-generate-ui-json`,
    });

    // Create Lambda function for clearing UI cache
    const clearUiCacheLambda = new lambda.Function(this, 'ClearUiCacheLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'ui-json-handler.clearUiCache',
      timeout: cdk.Duration.seconds(10),
      environment: {
        UI_BUCKET: this.uiJsonBucket.bucketName,
      },
      description: 'Clears UI JSON configuration cache',
      functionName: `SmartHome-${envName}-clear-ui-cache`,
    });

    // Grant Lambda read/write access to the S3 bucket
    this.uiJsonBucket.grantRead(this.uiJsonLambda);
    this.uiJsonBucket.grantReadWrite(generateUiJsonLambda);
    this.uiJsonBucket.grantRead(clearUiCacheLambda);

    // Grant access to DynamoDB if table is provided
    if (props.devicesTable) {
      props.devicesTable.grantReadData(this.uiJsonLambda);
      props.devicesTable.grantReadData(generateUiJsonLambda);
    }

    // Deploy UI JSON files to S3
    new s3deploy.BucketDeployment(this, 'DeployUiJson', {
      sources: [s3deploy.Source.asset(path.join(__dirname, '../../ui-json'))],
      destinationBucket: this.uiJsonBucket,
    });

    // Add AppSync resolvers if API is provided
    if (props.api) {
      // Add resolver for getUiJson
      const getUiJsonDS = props.api.addLambdaDataSource(
        'GetUiJsonDataSource',
        this.uiJsonLambda
      );

      getUiJsonDS.createResolver('GetUiJsonResolver', {
        typeName: 'Query',
        fieldName: 'getUiJson',
        requestMappingTemplate: appsync.MappingTemplate.lambdaRequest(),
        responseMappingTemplate: appsync.MappingTemplate.lambdaResult(),
      });

      // Add resolver for generateUiJson
      const generateUiJsonDS = props.api.addLambdaDataSource(
        'GenerateUiJsonDataSource',
        generateUiJsonLambda
      );

      generateUiJsonDS.createResolver('GenerateUiJsonResolver', {
        typeName: 'Mutation',
        fieldName: 'generateUiJson',
        requestMappingTemplate: appsync.MappingTemplate.lambdaRequest(),
        responseMappingTemplate: appsync.MappingTemplate.lambdaResult(),
      });

      // Add resolver for clearUiCache
      const clearUiCacheDS = props.api.addLambdaDataSource(
        'ClearUiCacheDataSource',
        clearUiCacheLambda
      );

      clearUiCacheDS.createResolver('ClearUiCacheResolver', {
        typeName: 'Mutation',
        fieldName: 'clearUiCache',
        requestMappingTemplate: appsync.MappingTemplate.lambdaRequest(),
        responseMappingTemplate: appsync.MappingTemplate.lambdaResult(),
      });
    }

    // Store bucket name in SSM for other stacks to use
    new ssm.StringParameter(this, 'UiJsonBucketNameParam', {
      parameterName: `/smart-home/${envName}/ui-json-bucket-name`,
      stringValue: this.uiJsonBucket.bucketName,
      description: 'S3 bucket for UI JSON files',
    });

    // Store Lambda ARNs in SSM
    new ssm.StringParameter(this, 'UiJsonLambdaArnParam', {
      parameterName: `/smart-home/${envName}/ui-json-lambda-arn`,
      stringValue: this.uiJsonLambda.functionArn,
      description: 'Lambda function ARN for UI JSON retrieval',
    });

    new ssm.StringParameter(this, 'GenerateUiJsonLambdaArnParam', {
      parameterName: `/smart-home/${envName}/generate-ui-json-lambda-arn`,
      stringValue: generateUiJsonLambda.functionArn,
      description: 'Lambda function ARN for UI JSON generation',
    });

    // Export outputs
    new cdk.CfnOutput(this, 'UiJsonBucketName', {
      value: this.uiJsonBucket.bucketName,
      description: 'S3 bucket for UI JSON files',
      exportName: `UiJsonBucketName-${envName}`,
    });

    new cdk.CfnOutput(this, 'UiJsonLambdaArn', {
      value: this.uiJsonLambda.functionArn,
      description: 'Lambda function ARN for UI JSON retrieval',
      exportName: `UiJsonLambdaArn-${envName}`,
    });

    new cdk.CfnOutput(this, 'GenerateUiJsonLambdaArn', {
      value: generateUiJsonLambda.functionArn,
      description: 'Lambda function ARN for UI JSON generation',
      exportName: `GenerateUiJsonLambdaArn-${envName}`,
    });
  }
}