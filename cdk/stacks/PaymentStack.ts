import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as path from 'path';
import { SSM_PATHS } from '../utils/param-paths';

interface PaymentStackProps extends cdk.StackProps {
  envName: string;
  userPoolId: string;
}

export class PaymentStack extends cdk.Stack {
  public readonly paymentApi: apigateway.RestApi;
  public readonly stripeWebhookUrl: string;

  constructor(scope: Construct, id: string, props: PaymentStackProps) {
    super(scope, id, props);

    const envName = props.envName || 'dev';

    // Create DynamoDB table for subscriptions
    const subscriptionsTable = new dynamodb.Table(this, 'SubscriptionsTable', {
      tableName: `SmartHomeSubscriptions-${envName}`,
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'subscriptionId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Create DynamoDB table for payment history
    const paymentsTable = new dynamodb.Table(this, 'PaymentsTable', {
      tableName: `SmartHomePayments-${envName}`,
      partitionKey: { name: 'paymentId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Add GSI for querying payments by userId
    paymentsTable.addGlobalSecondaryIndex({
      indexName: 'UserPaymentsIndex',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.STRING },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    // Create Lambda execution role with permissions
    const paymentLambdaRole = new iam.Role(this, 'PaymentLambdaRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMReadOnlyAccess'),
      ],
    });

    // Add permissions to the role
    paymentLambdaRole.addToPolicy(new iam.PolicyStatement({
      actions: [
        'dynamodb:GetItem',
        'dynamodb:PutItem',
        'dynamodb:UpdateItem',
        'dynamodb:DeleteItem',
        'dynamodb:Query',
        'dynamodb:Scan',
      ],
      resources: [
        subscriptionsTable.tableArn,
        paymentsTable.tableArn,
        `${paymentsTable.tableArn}/index/*`,
      ],
    }));

    // Create Lambda functions for payment processing
    const createSubscriptionFunction = new lambda.Function(this, 'CreateSubscriptionFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'payment.createSubscription',
      timeout: cdk.Duration.seconds(30),
      role: paymentLambdaRole,
      environment: {
        STAGE: props.envName,
        SUBSCRIPTIONS_TABLE: subscriptionsTable.tableName,
        PAYMENTS_TABLE: paymentsTable.tableName,
        USER_POOL_ID: props.userPoolId,
        STRIPE_SECRET_KEY_PARAM: SSM_PATHS.PAYMENT.STRIPE_SECRET_KEY(envName),
      },
      description: 'Creates a new subscription in Stripe',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME('SmartHomeApp', envName, 'create-subscription'),
    });

    const cancelSubscriptionFunction = new lambda.Function(this, 'CancelSubscriptionFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'payment.cancelSubscription',
      timeout: cdk.Duration.seconds(30),
      role: paymentLambdaRole,
      environment: {
        STAGE: props.envName,
        SUBSCRIPTIONS_TABLE: subscriptionsTable.tableName,
        STRIPE_SECRET_KEY_PARAM: SSM_PATHS.PAYMENT.STRIPE_SECRET_KEY(envName),
      },
      description: 'Cancels an existing subscription in Stripe',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME('SmartHomeApp', envName, 'cancel-subscription'),
    });

    const stripeWebhookFunction = new lambda.Function(this, 'StripeWebhookFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'payment.webhookHandler',
      timeout: cdk.Duration.seconds(30),
      role: paymentLambdaRole,
      environment: {
        STAGE: props.envName,
        SUBSCRIPTIONS_TABLE: subscriptionsTable.tableName,
        PAYMENTS_TABLE: paymentsTable.tableName,
        STRIPE_SECRET_KEY_PARAM: SSM_PATHS.PAYMENT.STRIPE_SECRET_KEY(envName),
        STRIPE_WEBHOOK_SECRET_PARAM: SSM_PATHS.PAYMENT.STRIPE_WEBHOOK_SECRET(envName),
      },
      description: 'Handles Stripe webhook events',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME('SmartHomeApp', envName, 'stripe-webhook'),
    });

    const getSubscriptionFunction = new lambda.Function(this, 'GetSubscriptionFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda')),
      handler: 'payment.getSubscription',
      timeout: cdk.Duration.seconds(30),
      role: paymentLambdaRole,
      environment: {
        STAGE: props.envName,
        SUBSCRIPTIONS_TABLE: subscriptionsTable.tableName,
        STRIPE_SECRET_KEY_PARAM: SSM_PATHS.PAYMENT.STRIPE_SECRET_KEY(envName),
      },
      description: 'Gets subscription details',
      functionName: SSM_PATHS.LAMBDA.FUNCTION_NAME('SmartHomeApp', envName, 'get-subscription'),
    });

    // Create API Gateway for payment endpoints
    this.paymentApi = new apigateway.RestApi(this, 'PaymentApi', {
      restApiName: `SmartHomePaymentApi-${envName}`,
      description: 'API for payment processing',
      deployOptions: {
        stageName: envName,
        tracingEnabled: true,
      },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
      },
    });

    // Create API resources and methods
    const subscriptionsResource = this.paymentApi.root.addResource('subscriptions');
    const subscriptionResource = subscriptionsResource.addResource('{subscriptionId}');
    const webhooksResource = this.paymentApi.root.addResource('webhooks');
    const stripeResource = webhooksResource.addResource('stripe');

    // POST /subscriptions - Create subscription
    subscriptionsResource.addMethod('POST', new apigateway.LambdaIntegration(createSubscriptionFunction));

    // GET /subscriptions/{subscriptionId} - Get subscription
    subscriptionResource.addMethod('GET', new apigateway.LambdaIntegration(getSubscriptionFunction));

    // DELETE /subscriptions/{subscriptionId} - Cancel subscription
    subscriptionResource.addMethod('DELETE', new apigateway.LambdaIntegration(cancelSubscriptionFunction));

    // POST /webhooks/stripe - Stripe webhook handler
    stripeResource.addMethod('POST', new apigateway.LambdaIntegration(stripeWebhookFunction));

    // Store webhook URL for Stripe configuration
    this.stripeWebhookUrl = `${this.paymentApi.url}webhooks/stripe`;

    // Store in SSM for other stacks to use
    new ssm.StringParameter(this, 'StripeWebhookUrlParam', {
      parameterName: `/payment/${envName}/stripe-webhook-url`,
      stringValue: this.stripeWebhookUrl,
      description: 'Stripe webhook URL',
    });

    // Export outputs
    new cdk.CfnOutput(this, 'PaymentApiUrl', {
      value: this.paymentApi.url,
      description: 'URL for the Payment API',
      exportName: `PaymentApiUrl-${envName}`,
    });

    new cdk.CfnOutput(this, 'StripeWebhookUrl', {
      value: this.stripeWebhookUrl,
      description: 'URL for Stripe webhooks',
      exportName: `StripeWebhookUrl-${envName}`,
    });

    new cdk.CfnOutput(this, 'SubscriptionsTableName', {
      value: subscriptionsTable.tableName,
      description: 'DynamoDB table for subscriptions',
      exportName: `SubscriptionsTableName-${envName}`,
    });

    new cdk.CfnOutput(this, 'PaymentsTableName', {
      value: paymentsTable.tableName,
      description: 'DynamoDB table for payment history',
      exportName: `PaymentsTableName-${envName}`,
    });
  }
}