import { convertDeviceToUI } from '../device-to-ui-layout';
import { DeviceConfig } from '../types/device-config';

describe('Edge Cases and Error Handling', () => {
  it('should handle unknown device type gracefully', () => {
    const unknownDevice = {
      type: "unknown-device",
      deviceId: "test-device-001",
      config: {
        name: "Unknown Device"
      }
    } as DeviceConfig;
    
    expect(() => convertDeviceToUI(unknownDevice)).not.toThrow();
    expect(convertDeviceToUI(unknownDevice)).toBeNull();
  });

  it('should handle missing configuration', () => {
    const incompleteDevice = {
      type: "energy-meter", // Changed to supported type
      deviceId: "test-device-002",
      config: {
        name: "Incomplete Device"
      }
    } as DeviceConfig;
    
    expect(() => convertDeviceToUI(incompleteDevice)).not.toThrow();
    const layout = convertDeviceToUI(incompleteDevice);
    expect(layout).toBeDefined();
    expect(layout?.screens[0].widgets.length).toBeGreaterThan(0);
  });

  it('should ignore unrecognized fields', () => {
    // Using type assertion to bypass TypeScript checking for test purposes
    const deviceWithExtra = {
      type: "energy-meter",
      deviceId: "test-device-003",
      config: {
        name: "Test Device",
        measurements: {
          voltage: {
            unit: "V"
          }
        }
      }
    } as DeviceConfig;
    
    // Add extra fields at runtime to test handling
    (deviceWithExtra.config as any).unknownField = "should be ignored";
    (deviceWithExtra.config as any).extraStuff = { shouldNotBreak: true };
    
    const layout = convertDeviceToUI(deviceWithExtra);
    expect(layout).toBeDefined();
    expect(layout?.screens[0].widgets.some(w => w.type === 'header')).toBe(true);
  });

  it('should handle malformed input gracefully', () => {
    // @ts-ignore - Intentionally passing wrong type for test
    const malformedConfig = "{'not': 'valid' json}";
    
    expect(() => convertDeviceToUI(malformedConfig as any)).not.toThrow();
    expect(convertDeviceToUI(malformedConfig as any)).toBeNull();
  });
});