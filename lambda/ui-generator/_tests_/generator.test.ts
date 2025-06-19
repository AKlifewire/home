import { handler } from '../index';
import * as fs from 'fs';
import * as path from 'path';
import { APIGatewayProxyEvent } from 'aws-lambda';
import { DeviceConfig } from '../types/device-config';
import { UILayout } from '../types/ui-layout';

// Mock AWS SDK
jest.mock('aws-sdk', () => ({
  S3: jest.fn(() => ({
    putObject: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({})
    })
  }))
}));

describe('UI Generator Lambda Integration Tests', () => {
  // Set up test environment
  beforeAll(() => {
    process.env.UI_BUCKET = 'test-ui-bucket';
    process.env.NODE_ENV = 'test';
  });

  const createTestEvent = (config: any): APIGatewayProxyEvent => ({
    body: JSON.stringify({
      deviceId: config.deviceId,
      deviceType: config.type,
      components: [
        {
          type: config.type,
          id: 'comp1',
          name: config.config.name,
          capabilities: ['read'],
          config: config.config
        }
      ],
      metadata: {
        name: config.config.name
      }
    }),
    requestContext: {
      authorizer: {
        claims: {
          sub: 'test-user-id'
        }
      }
    }
  } as any);

  describe('Energy Meter Device', () => {
    it('should generate valid layout for energy meter', async () => {
      const config: DeviceConfig = {
        type: 'energy-meter',
        deviceId: 'test-meter-001',
        config: {
          name: 'Test Energy Meter',
          model: 'EM3000',
          measurements: {
            voltage: {
              unit: 'V',
              ranges: {
                min: 0,
                max: 250,
                warning: 235,
                critical: 245
              }
            },
            current: {
              unit: 'A',
              ranges: {
                min: 0,
                max: 100,
                warning: 80,
                critical: 90
              }
            },
            power: {
              unit: 'W',
              ranges: {
                min: 0,
                max: 10000,
                warning: 8000,
                critical: 9000
              }
            }
          }
        }
      };

      const result = await handler(createTestEvent(config));
      expect(result.statusCode).toBe(200);

      const response = JSON.parse(result.body);
      expect(response.layout).toBeDefined();
      const layout = response.layout as UILayout;

      // Verify basic layout structure
      expect(layout.version).toBe('1.0');
      expect(layout.metadata.deviceId).toBe(config.deviceId);
      expect(layout.screens).toHaveLength(1);
    });
  });

  describe('Error Handling', () => {
    it('should handle missing auth context', async () => {
      const event = createTestEvent({
        type: 'energy-meter',
        deviceId: 'test-001',
        config: { name: 'Test Device' }
      });
      delete event.requestContext.authorizer;

      const result = await handler(event);
      expect(result.statusCode).toBe(401);

      const response = JSON.parse(result.body);
      expect(response.error).toBe('Unauthorized - User ID not found');
    });
  });
});