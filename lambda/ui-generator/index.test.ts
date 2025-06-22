import { handler } from './index';
import { DeviceConfig } from './types';

// Mock AWS SDK
jest.mock('aws-sdk', () => {
  return {
    S3: jest.fn().mockImplementation(() => ({
      putObject: jest.fn().mockReturnValue({
        promise: jest.fn().mockResolvedValue({})
      })
    }))
  };
});

describe('UI Generator Lambda', () => {
  const mockEvent = {
    body: JSON.stringify({
      deviceId: 'test-device-001',
      deviceType: 'energyMeter',
      components: [
        {
          type: 'energyMeter',
          id: 'em1',
          name: 'Main Meter',
          capabilities: ['voltage', 'current', 'power'],
          config: {
            phases: 3,
            maxVoltage: 240,
            maxCurrent: 100
          }
        }
      ],
      metadata: {
        name: 'Test Energy Meter',
        location: 'Main Panel'
      }
    }),
    requestContext: {
      authorizer: {
        claims: {
          sub: 'user123'
        }
      }
    }
  };

  beforeEach(() => {
    process.env.UI_BUCKET = 'test-ui-bucket';
    process.env.NODE_ENV = 'test';
  });

  test('generates UI layout from device config', async () => {
    const result = await handler(mockEvent as any);
    
    expect(result.statusCode).toBe(200);
    
    const response = JSON.parse(result.body);
    expect(response.message).toContain('generated and stored successfully');
    expect(response.deviceId).toBe('test-device-001');
    expect(response.layout).toBeDefined();
    expect(response.layout.version).toBe('1.0');
    expect(response.layout.metadata.deviceId).toBe('test-device-001');
    expect(response.layout.screens).toBeInstanceOf(Array);
    expect(response.layout.screens.length).toBeGreaterThan(0);
  });

  test('handles missing authorization', async () => {
    const eventWithoutAuth = {
      ...mockEvent,
      requestContext: {}
    };
    
    const result = await handler(eventWithoutAuth as any);
    
    expect(result.statusCode).toBe(401);
    expect(JSON.parse(result.body).error).toContain('Unauthorized');
  });

  test('handles invalid device configuration', async () => {
    const eventWithInvalidConfig = {
      ...mockEvent,
      body: JSON.stringify({
        // Missing required deviceId field
        deviceType: 'energyMeter',
        components: []
      }),
      requestContext: {
        authorizer: {
          claims: {
            sub: 'user123'
          }
        }
      }
    };
    
    const result = await handler(eventWithInvalidConfig as any);
    
    expect(result.statusCode).toBe(400);
    const response = JSON.parse(result.body);
    expect(response.error).toBeDefined();
    expect(response.message).toContain('Missing or invalid required fields');
  });

  test('validates widget mapping for each component type', async () => {
    const config: DeviceConfig = {
      deviceId: 'test-device-002',
      deviceType: 'mixed',
      components: [
        {
          type: 'relay',
          id: 'relay1',
          name: 'Light Switch',
          capabilities: ['toggle'],
          config: {}
        },
        {
          type: 'sensor',
          id: 'sensor1',
          name: 'Temperature',
          capabilities: ['read'],
          config: {
            unit: '°C',
            range: [-20, 50]
          }
        },
        {
          type: 'camera',
          id: 'cam1',
          name: 'Front Door',
          capabilities: ['stream'],
          config: {
            resolution: '1080p'
          }
        }
      ],
      metadata: {
        name: 'Mixed Device'
      }
    };
    
    const event = {
      ...mockEvent,
      body: JSON.stringify(config),
    };
    
    const result = await handler(event as any);
    expect(result.statusCode).toBe(200);
    
    const response = JSON.parse(result.body);
    const layout = response.layout;
    
    // Check that each component type was mapped to the correct widget type
    const mainScreen = layout.screens[0];
    const widgetTypes = mainScreen.widgets.map((w: any) => w.type);
    
    expect(widgetTypes).toContain('toggle');  // For relay
    expect(widgetTypes).toContain('gauge');   // For sensor
    expect(widgetTypes).toContain('video');   // For camera
  });
});