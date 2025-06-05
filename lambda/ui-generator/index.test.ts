import { handler } from './index';
import * as fs from 'fs';
import * as path from 'path';
import { APIGatewayProxyEvent } from 'aws-lambda';
import { DeviceConfig, UiLayout, UiScreen, UiWidget } from './types';

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

describe('UI Generator Lambda', () => {
  // Mock environment variables
  beforeAll(() => {
    process.env.UI_BUCKET = 'test-ui-bucket';
    process.env.NODE_ENV = 'test';
  });
  // Load test device configurations
  const testDeviceConfig: DeviceConfig = JSON.parse(
    fs.readFileSync(path.join(__dirname, 'test-device.json'), 'utf-8')
  );

  const createTestEvent = (deviceConfig: DeviceConfig): APIGatewayProxyEvent => ({
    body: JSON.stringify(deviceConfig),
    requestContext: {
      authorizer: {
        claims: {
          sub: 'test-user-id'
        }
      }
    }
  } as any);
  function validateLayout(layout: UiLayout) {
    // Validate version
    expect(layout.version).toBeDefined();
    expect(typeof layout.version).toBe('string');

    // Validate metadata
    expect(layout.metadata).toBeDefined();
    expect(layout.metadata.deviceId).toBeDefined();
    expect(layout.metadata.lastUpdated).toBeDefined();

    // Validate screens
    expect(Array.isArray(layout.screens)).toBe(true);
    expect(layout.screens.length).toBeGreaterThan(0);

    // Validate each screen
    layout.screens.forEach((screen: UiScreen) => {
      expect(screen.id).toBeDefined();
      expect(screen.title).toBeDefined();
      expect(Array.isArray(screen.widgets)).toBe(true);

      // Validate each widget
      screen.widgets.forEach((widget: UiWidget) => {
        expect(widget.type).toBeDefined();
        expect(widget.componentId).toBeDefined();
        expect(widget.properties).toBeDefined();
      });
    });
  }

  test('generates valid UI layout for multi-function device', async () => {
    const event = createTestEvent(testDeviceConfig);
    const result = await handler(event);

    // Validate response
    expect(result.statusCode).toBe(200);
    const response = JSON.parse(result.body);
    expect(response.message).toBe('UI layout generated and stored successfully');
    expect(response.deviceId).toBe(testDeviceConfig.deviceId);
    expect(response.layout).toBeDefined();

    validateLayout(response.layout);
  });

  test('handles missing user ID', async () => {
    const event = createTestEvent(testDeviceConfig);
    delete event.requestContext.authorizer;

    const result = await handler(event);
    expect(result.statusCode).toBe(401);
    const response = JSON.parse(result.body);
    expect(response.error).toBe('Unauthorized - User ID not found');
  });  test('handles invalid device configuration', async () => {
    const config = { ...testDeviceConfig };
    const invalidConfig = {
      deviceType: config.deviceType,
      components: config.components,
      metadata: config.metadata
    } as DeviceConfig;

    const event = createTestEvent(invalidConfig);
    const result = await handler(event);

    expect(result.statusCode).toBe(400);
    const response = JSON.parse(result.body);
    expect(response.error).toBeDefined();
    expect(response.message).toContain('Missing required fields');
  });

  test('validates widget mapping for each component type', async () => {
    const event = createTestEvent(testDeviceConfig);
    const result = await handler(event);
    const response = JSON.parse(result.body);
    const layout = response.layout;

    // Check that each component has a corresponding widget
    const components = testDeviceConfig.components;    const widgets = layout.screens[0].widgets;

    components.forEach(component => {
      const matchingWidget = widgets.find((widget: UiWidget) => widget.componentId === component.id);
      expect(matchingWidget).toBeDefined();
      
      // Verify widget type matches component type mapping
      switch (component.type) {
        case 'relay':
          expect(matchingWidget.type).toBe('toggle');
          break;
        case 'sensor':
          expect(matchingWidget.type).toBe('gauge');
          break;
        case 'camera':
          expect(matchingWidget.type).toBe('video');
          break;
        case 'energyMeter':
          expect(matchingWidget.type).toBe('chart');
          break;
      }
    });
  });
});
