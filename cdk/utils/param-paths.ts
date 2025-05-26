/**
 * Central registry for SSM parameter paths
 * This ensures consistent parameter naming across stacks
 */

export const SSM_PATHS = {
  // Auth parameters
  AUTH: {
    USER_POOL_ID: (env: string) => `/${env}/auth/userPoolId`,
    USER_POOL_CLIENT_ID: (env: string) => `/${env}/auth/userPoolClientId`,
    IDENTITY_POOL_ID: (env: string) => `/${env}/auth/identityPoolId`,
  },
  
  // API parameters
  API: {
    GRAPHQL_ENDPOINT: (env: string) => `/${env}/api/graphqlEndpoint`,
    GRAPHQL_API_ID: (env: string) => `/${env}/api/graphqlApiId`,
  },
  
  // UI parameters
  UI: {
    S3_BUCKET_NAME: (env: string) => `/${env}/ui/s3BucketName`,
    S3_BUCKET_URL: (env: string) => `/${env}/ui/s3BucketUrl`,
    S3_BUCKET_DOMAIN: (env: string) => `/${env}/ui/s3BucketRegionalDomainName`,
  },
  
  // IoT parameters
  IOT: {
    ENDPOINT: (env: string) => `/${env}/iot/endpoint`,
    PROVISIONING_TEMPLATE: (env: string) => `/${env}/iot/provisioningTemplateName`,
    POLICY_NAME: (env: string) => `/${env}/iot/policyName`,
  },
  
  // OTA parameters
  OTA: {
    BUCKET_NAME: (env: string) => `/${env}/ota/bucketName`,
    BUCKET_URL: (env: string) => `/${env}/ota/bucketUrl`,
  },
  
  // Logs parameters
  LOGS: {
    BUCKET_NAME: (env: string) => `/${env}/logs/bucketName`,
  },
  
  // Analytics parameters
  ANALYTICS: {
    TIMESTREAM_DATABASE: (env: string) => `/${env}/analytics/timestreamDatabase`,
    TIMESTREAM_TABLE: (env: string) => `/${env}/analytics/timestreamTable`,
  },
  
  // Payment parameters
  PAYMENT: {
    STRIPE_SECRET_KEY: (env: string) => `/${env}/payment/stripeSecretKey`,
    STRIPE_WEBHOOK_SECRET: (env: string) => `/${env}/payment/stripeWebhookSecret`,
  },
  
  // Monitoring parameters
  MONITORING: {
    ALARM_TOPIC_ARN: (env: string) => `/${env}/monitoring/alarmTopicArn`,
  },
  
  // Lambda function names
  LAMBDA: {
    FUNCTION_NAME: (app: string, env: string, name: string) => `${app}-${env}-lambda-${name}`,
  }
};