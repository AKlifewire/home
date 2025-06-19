// AWS Configuration constants

class Configuration {
  // AWS IoT Core endpoint
  static const String iotEndpoint = 'a3rbulpildf8ig-ats.iot.us-east-1.amazonaws.com';
  
  // AWS Region
  static const String region = 'us-east-1';
  
  // API endpoint
  static const String apiEndpoint = 'https://7jp1vhved6.execute-api.us-east-1.amazonaws.com/prod';
  
  // GraphQL endpoint
  static const String graphqlEndpoint = 'https://m3kglrtcvfhwfp4mngf6tzqcn4.appsync-api.us-east-1.amazonaws.com/graphql';
  
  // GraphQL API key
  static const String graphqlApiKey = 'da2-xg653fjtfvcpnen3l6bpfpoyca';
  
  // S3 buckets
  static const String uiJsonBucket = 'dev-uijsonstack-uijsonbucket3aa1eb43-8a81zgdjsba';
  static const String uiPageBucket = 'dev-storagestack-upagebucketacd75cdc-dinnt9v6qbt';
  
  // DynamoDB tables
  static const String devicesTable = 'SmartHomeDevices-dev';
}