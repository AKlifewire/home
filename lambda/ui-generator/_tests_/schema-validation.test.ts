import { validateLayout } from '../utils/validateLayout';
import { UiLayout } from '../types';

describe('UI Layout Schema Validation', () => {
  it('should validate a correct UI layout', () => {
    const validLayout: UiLayout = {
      version: "1.0",
      metadata: {
        deviceId: "test-device-001", 
        lastUpdated: new Date().toISOString()
      },
      screens: [
        {
          id: "main",
          title: "Test Device",
          widgets: [
            {
              type: "gauge",
              componentId: "temp-sensor-1",
              properties: {
                title: "Temperature",
                topic: "iot/device/temp"
              }
            }
          ]
        }
      ]
    };
    
    expect(() => validateLayout(validLayout)).not.toThrow();
  });

  it('should reject layout without required metadata', () => {
    const invalidLayout = {
      version: "1.0",
      metadata: {}, // missing deviceId
      screens: [
        {
          id: "main",
          title: "Test",
          widgets: []
        }
      ]
    };
    
    // Use type assertion to allow the test to check validation
    expect(() => validateLayout(invalidLayout as any)).toThrow("Layout must have metadata with deviceId");
  });

  it('should reject layout with unknown widget type', () => {
    const invalidLayout: UiLayout = {
      version: "1.0",
      metadata: {
        deviceId: "test-device-001",
        lastUpdated: new Date().toISOString()
      },
      screens: [
        {
          id: "main",
          title: "Test Screen",
          widgets: [
            {
              type: "invalid-type",
              componentId: "widget-1",
              properties: {
                title: "Test Widget"
              }
            }
          ]
        }
      ]
    };
    
    expect(() => validateLayout(invalidLayout)).toThrow();
  });

  it('should validate nested components', () => {
    const layoutWithNested: UiLayout = {
      version: "1.0",
      metadata: {
        deviceId: "test-device-001",
        lastUpdated: new Date().toISOString()
      },
      screens: [
        {
          id: "main",
          title: "Test Screen",
          widgets: [
            {
              type: "gauge",
              componentId: "temp-sensor",
              properties: {
                title: "Temperature"
              }
            }
          ]
        }
      ]
    };
    
    expect(() => validateLayout(layoutWithNested)).not.toThrow();
  });
});