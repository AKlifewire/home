enum Environment {
  dev,
  prod,
}

class EnvConfig {
  static Environment currentEnv = Environment.dev;
  
  // API endpoints
  static String get apiEndpoint {
    switch (currentEnv) {
      case Environment.dev:
        return 'https://dev-api.example.com/graphql';
      case Environment.prod:
        return 'https://api.example.com/graphql';
    }
  }
  
  // MQTT configuration
  static String get mqttBroker {
    switch (currentEnv) {
      case Environment.dev:
        return 'dev-mqtt.example.com';
      case Environment.prod:
        return 'mqtt.example.com';
    }
  }
  
  static int get mqttPort {
    return 8883; // Same for both environments
  }
  
  // Feature flags
  static bool get enableDebugLogging {
    switch (currentEnv) {
      case Environment.dev:
        return true;
      case Environment.prod:
        return false;
    }
  }
  
  // Initialize environment from string
  static void initFromString(String envName) {
    switch (envName.toLowerCase()) {
      case 'prod':
      case 'production':
        currentEnv = Environment.prod;
        break;
      case 'dev':
      case 'development':
      default:
        currentEnv = Environment.dev;
        break;
    }
  }
}