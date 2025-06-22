import { S3 } from 'aws-sdk';
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { 
  DeviceConfig,
  UiLayout,
  UiScreen,
  UiWidget,
  ComponentWidgetMap,
  UiGeneratorHandler 
} from './types';

const s3 = new S3();

// For testing purposes
const isTesting = process.env.NODE_ENV === 'test';
if (isTesting) {
  s3.putObject = () => ({
    promise: () => Promise.resolve({})
  }) as any;
}

/**
 * Maps device component types to UI widget types
 */
const componentToWidgetMap: { [key: string]: string } = {
  relay: 'toggle',
  sensor: 'gauge',
  camera: 'video',
  energyMeter: 'chart',
  thermostat: 'climate',
  // Add more mappings as needed
};

/**
 * Generates UI layout JSON based on device configuration
 */
async function generateUiLayout(config: DeviceConfig): Promise<UiLayout> {
  // Create main control screen
  const mainScreen: UiScreen = {
    id: 'main',
    title: config.metadata?.name || `Device ${config.deviceId}`,
    widgets: []
  };

  // Process each component and create corresponding widgets
  config.components.forEach(component => {
    const widgetType = componentToWidgetMap[component.type];
    if (!widgetType) {
      console.warn(`No widget mapping for component type: ${component.type}`);
      return;
    }

    const widget: UiWidget = {
      type: widgetType,
      componentId: component.id,
      properties: {
        title: component.name || `${component.type} ${component.id}`,
        ...component.config
      }
    };

    mainScreen.widgets.push(widget);
  });

  // Group similar components into separate screens if needed
  const screens = [mainScreen];

  return {
    version: '1.0',
    metadata: {
      deviceId: config.deviceId,
      lastUpdated: new Date().toISOString()
    },
    screens
  };
}

/**
 * Stores UI layout in S3
 */
async function storeUiLayout(userId: string, deviceId: string, layout: UiLayout): Promise<void> {
  const bucket = process.env.UI_BUCKET;
  if (!bucket) {
    throw new Error('UI_BUCKET environment variable not set');
  }

  const key = `users/${userId}/devices/${deviceId}/ui-layout.json`;
  
  await s3.putObject({
    Bucket: bucket,
    Key: key,
    Body: JSON.stringify(layout, null, 2),
    ContentType: 'application/json'
  }).promise();
}

/**
 * Main Lambda handler
 */
export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const deviceConfig: DeviceConfig = JSON.parse(event.body || '');
    const userId = event.requestContext.authorizer?.claims?.sub;

    if (!userId) {
      return {
        statusCode: 401,
        body: JSON.stringify({ error: 'Unauthorized - User ID not found' })
      };
    }
    
    // Validate required fields
    if (!deviceConfig || typeof deviceConfig !== 'object') {
      return {
        statusCode: 400,
        body: JSON.stringify({ 
          error: 'Invalid device configuration',
          message: 'Device configuration must be an object'
        })
      };
    }
    
    // Check all required fields exist and have correct types
    const validationErrors = [];
    
    if (!deviceConfig.deviceId || typeof deviceConfig.deviceId !== 'string') {
      validationErrors.push('deviceId (string)');
    }
    if (!deviceConfig.deviceType || typeof deviceConfig.deviceType !== 'string') {
      validationErrors.push('deviceType (string)');
    }
    if (!Array.isArray(deviceConfig.components)) {
      validationErrors.push('components (array)');
    }

    if (validationErrors.length > 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: 'Invalid device configuration',
          message: `Missing or invalid required fields: ${validationErrors.join(', ')}`
        })
      };
    }

    // Generate UI layout from device config
    const layout = await generateUiLayout(deviceConfig);

    // Store in S3
    await storeUiLayout(userId, deviceConfig.deviceId, layout);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'UI layout generated and stored successfully',
        deviceId: deviceConfig.deviceId,
        layout
      })
    };

  } catch (error) {
    console.error('Error processing device config:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'Failed to generate UI layout',
        message: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};