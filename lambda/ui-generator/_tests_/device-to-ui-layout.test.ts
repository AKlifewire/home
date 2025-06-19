import { convertDeviceToUI } from '../device-to-ui-layout';
import * as energyMeterConfig from '../mocks/energy-meter-3p.json';
import * as smartIrrigationConfig from '../mocks/smart-irrigation.json';
import * as environmentSensorConfig from '../mocks/environment-sensor.json';
import { UiLayout } from '../types';

describe('Device to UI Layout Conversion', () => {
  describe('Energy Meter Device', () => {
    it('should generate correct UI layout for 3-phase energy meter', () => {
      const layout = convertDeviceToUI(energyMeterConfig as any);
      
      // Check basic structure
      expect(layout).toBeDefined();
      expect(layout).not.toBeNull();
      const nonNullLayout = layout as UiLayout;
      expect(nonNullLayout.components).toBeDefined();
      expect(nonNullLayout.components!.length).toBeGreaterThan(0);
      
      // Verify required components
      const componentTypes = nonNullLayout.components!.map((c: any) => c.type);
      expect(componentTypes).toContain('header');
      expect(componentTypes).toContain('gauge');
      
      // Check measurements
      const gauges = nonNullLayout.components!.filter((c: any) => c.type === 'gauge');
      expect(gauges.length).toBeGreaterThanOrEqual(3); // Voltage, Current, Power
      
      // Check gauge properties
      gauges.forEach((gauge: any) => {
        expect(gauge.title).toBeDefined();
        expect(gauge.config).toBeDefined();
        expect(typeof gauge.config?.min).toBe('number');
        expect(typeof gauge.config?.max).toBe('number');
        expect(typeof gauge.config?.unit).toBe('string');
      });
      
      // Verify MQTT topics
      const topics = nonNullLayout.components!
        .filter((c: any) => c.topic)
        .map((c: any) => c.topic);
      expect(topics.length).toBeGreaterThan(0);
      expect(topics.every((t: any) => t && t.startsWith('iot/'))).toBe(true);
    });
  });

  describe('Smart Irrigation Device', () => {
    it('should generate correct UI layout for irrigation controller', () => {
      const layout = convertDeviceToUI(smartIrrigationConfig as any);
      
      expect(layout).toBeDefined();
      expect(layout).not.toBeNull();
      const nonNullLayout = layout as UiLayout;

      expect(nonNullLayout.components).toBeDefined();
      
      const componentTypes = nonNullLayout.components!.map((c: any) => c.type);
      expect(componentTypes).toContain('header');
      expect(componentTypes).toContain('switch');
      expect(componentTypes).toContain('scheduler');
      
      // Verify scheduler component
      const scheduler = nonNullLayout.components!.find((c: any) => c.type === 'scheduler');
      expect(scheduler).toBeDefined();
      expect(scheduler?.config).toBeDefined();
      expect(scheduler?.config?.zones).toBeDefined();
      
      // Check zone switches
      const switches = nonNullLayout.components!.filter((c: any) => c.type === 'switch');
      expect(switches.length).toBe(smartIrrigationConfig.config.zones.length);
      
      // Check switch properties
      switches.forEach((switchComp: any, i: number) => {
        expect(switchComp.title).toBe(smartIrrigationConfig.config.zones[i].name);
        expect(switchComp.topic).toBeDefined();
      });
    });
  });

  describe('Environment Sensor Device', () => {
    it('should generate correct UI layout for environmental sensor', () => {
      const layout = convertDeviceToUI(environmentSensorConfig as any);
      
      expect(layout).toBeDefined();
      expect(layout).not.toBeNull();
      const nonNullLayout = layout as UiLayout;

      expect(nonNullLayout.components).toBeDefined();
      
      const componentTypes = nonNullLayout.components!.map((c: any) => c.type);
      expect(componentTypes).toContain('header');
      expect(componentTypes).toContain('gauge');
      expect(componentTypes).toContain('status');
      
      // Check sensor readings
      const gauges = nonNullLayout.components!.filter((c: any) => c.type === 'gauge');
      expect(gauges.length).toBeGreaterThanOrEqual(2); // Temperature, Humidity
      
      // Check gauge properties
      const requiredMeasurements = ['temperature', 'humidity'];
      requiredMeasurements.forEach(measurement => {
        const gauge = gauges.find((g: any) => g.title.toLowerCase().includes(measurement));
        expect(gauge).toBeDefined();
        expect(gauge?.config?.unit).toBe((environmentSensorConfig.config.measurements as any)[measurement].unit);
      });
      
      // Check battery status
      const status = nonNullLayout.components!.find((c: any) => c.type === 'status');
      expect(status).toBeDefined();
      expect(status?.title.toLowerCase()).toContain('battery');
      expect(status?.config?.ranges).toBeDefined();
      expect(status?.config?.unit).toBe(environmentSensorConfig.config.battery.unit);
    });
  });
});