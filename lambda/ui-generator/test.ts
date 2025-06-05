import { handler } from './index';
import * as fs from 'fs';
import * as path from 'path';
import { S3 } from 'aws-sdk';

// Mock AWS SDK
jest.mock('aws-sdk', () => {
  return {
    S3: jest.fn(() => ({
      putObject: jest.fn().mockReturnValue({
        promise: () => Promise.resolve({})
      })
    }))
  };
});

async function runTest() {
  try {
    // Load test device configuration
    const deviceConfig = JSON.parse(
      fs.readFileSync(path.join(__dirname, 'test-device.json'), 'utf-8')
    );    // Set up test environment
    process.env.UI_BUCKET = 'test-ui-bucket';
    process.env.NODE_ENV = 'test';
    
    // Create mock API Gateway event
    const testEvent = {
      body: JSON.stringify(deviceConfig),
      requestContext: {
        authorizer: {
          claims: {
            sub: 'test-user-id'
          }
        }
      }
    };

    // Process the device configuration
    console.log('Testing UI generation for device:', deviceConfig.deviceId);
    const result = await handler(testEvent as any);
    
    // Validate response
    if (result.statusCode !== 200) {
      throw new Error(`Handler returned status code ${result.statusCode}`);
    }

    const response = JSON.parse(result.body);
    console.log('\nGenerated UI Layout:', JSON.stringify(response.layout, null, 2));

    // Validate layout structure
    validateLayout(response.layout);

    console.log('\n✅ Test passed successfully!');
    console.log('Generated UI layout for:', response.deviceId);
    
  } catch (error) {
    console.error('\n❌ Test failed:', error);
    process.exit(1);
  }
}

function validateLayout(layout: any) {
  // Validate version
  if (!layout.version) {
    throw new Error('Missing layout version');
  }

  // Validate metadata
  if (!layout.metadata?.deviceId) {
    throw new Error('Missing device ID in metadata');
  }

  // Validate screens
  if (!Array.isArray(layout.screens)) {
    throw new Error('Layout must contain screens array');
  }

  // Validate each screen
  layout.screens.forEach((screen: any, index: number) => {
    if (!screen.id) {
      throw new Error(`Screen ${index} missing ID`);
    }
    if (!screen.title) {
      throw new Error(`Screen ${index} missing title`);
    }
    if (!Array.isArray(screen.widgets)) {
      throw new Error(`Screen ${index} must contain widgets array`);
    }

    // Validate each widget
    screen.widgets.forEach((widget: any, widgetIndex: number) => {
      if (!widget.type) {
        throw new Error(`Widget ${widgetIndex} in screen ${screen.id} missing type`);
      }
      if (!widget.componentId) {
        throw new Error(`Widget ${widgetIndex} in screen ${screen.id} missing componentId`);
      }
      if (!widget.properties) {
        throw new Error(`Widget ${widgetIndex} in screen ${screen.id} missing properties`);
      }
    });
  });
}

// Run the test
runTest();