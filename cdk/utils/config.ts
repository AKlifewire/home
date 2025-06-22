// Centralized SSM parameter paths and configuration
export const SSM_CONFIG = {
  // Environment-aware parameter paths
  getPath: (env: string, key: string) => `/SmartHome/${env}/${key}`,
  
  // Parameter keys
  KEYS: {
    // Auth
    USER_POOL_ID: 'USER_POOL_ID',
    USER_POOL_CLIENT_ID: 'USER_POOL_CLIENT_ID',
    IDENTITY_POOL_ID: 'IDENTITY_POOL_ID',
    
    // Frontend
    FRONTEND_DOMAIN: 'FRONTEND_DOMAIN',
    AMPLIFY_APP_ID: 'AMPLIFY_APP_ID',
    
    // API
    APPSYNC_URL: 'APPSYNC_URL',
    APPSYNC_API_KEY: 'APPSYNC_API_KEY',
    
    // IoT
    IOT_ENDPOINT: 'IOT_ENDPOINT',
    
    // Storage
    UI_BUCKET: 'UI_BUCKET',
    DEVICES_TABLE: 'DEVICES_TABLE'
  }
};

// Helper functions
export const getSSMPath = (env: string, key: string) => SSM_CONFIG.getPath(env, key);
export const getAuthPath = (env: string) => ({
  userPoolId: getSSMPath(env, SSM_CONFIG.KEYS.USER_POOL_ID),
  userPoolClientId: getSSMPath(env, SSM_CONFIG.KEYS.USER_POOL_CLIENT_ID),
  identityPoolId: getSSMPath(env, SSM_CONFIG.KEYS.IDENTITY_POOL_ID)
});