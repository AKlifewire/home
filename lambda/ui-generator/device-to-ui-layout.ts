import { DeviceConfig, DeviceConfigDetails } from './types/device-config';
import { UiLayout, UiScreen, UiWidget, UiComponent } from './types';
import { validateLayout } from './utils/validateLayout';

export function convertDeviceToUI(deviceConfig: DeviceConfig): UiLayout | null {
  try {
    // Handle malformed input
    if (!deviceConfig || typeof deviceConfig !== 'object' || !deviceConfig.type) {
      console.warn('Invalid device configuration');
      return null;
    }

    // Create the main screen
    const mainScreen: UiScreen = {
      id: 'main',
      title: deviceConfig.config?.name || `Device ${deviceConfig.deviceId || 'Unknown'}`,
      widgets: [{
        type: 'header',
        componentId: 'header',
        properties: {
          title: deviceConfig.config?.name || 'Device',
          subtitle: deviceConfig.config?.model || ''
        }
      }]
    };

    // Create components array for backward compatibility with tests
    const components: UiComponent[] = [{
      type: 'header',
      title: deviceConfig.config?.name || 'Device',
      config: {
        subtitle: deviceConfig.config?.model || ''
      }
    }];

    const layout: UiLayout = {
      version: "1.0",
      metadata: {
        deviceId: deviceConfig.deviceId || 'unknown-device',
        lastUpdated: new Date().toISOString()
      },
      screens: [mainScreen],
      components: components // For backward compatibility with tests
    };
    
    // Handle different device types
    if (deviceConfig.type && deviceConfig.config) {
      switch (deviceConfig.type) {
        case "energy-meter":
          addEnergyMeterComponents(mainScreen, components, deviceConfig);
          break;
        case "smart-irrigation":
          addIrrigationComponents(mainScreen, components, deviceConfig);
          break;
        case "environment-sensor":
          addEnvironmentSensorComponents(mainScreen, components, deviceConfig);
          break;
        default:
          // Return null for unsupported device types
          console.warn(`Unsupported device type: ${deviceConfig.type}`);
          return null;
      }
    }

    // Validate the generated layout
    validateLayout(layout);
    return layout;
  } catch (error) {
    console.error('Error converting device to UI:', error);
    return null;
  }
}

function addEnergyMeterComponents(screen: UiScreen, components: UiComponent[], device: DeviceConfig) {
  // Add gauges for voltage, current, and power measurements
  const measurements = device.config.measurements || {};
  
  // Use Object.entries to iterate over the measurements object
  Object.entries(measurements).forEach(([key, measurement]) => {
    // Add to screens/widgets structure
    screen.widgets.push({
      type: "gauge",
      componentId: `${key}-gauge`,
      properties: {
        title: key.charAt(0).toUpperCase() + key.slice(1),
        topic: `iot/device/${device.type}/${key}`,
        unit: measurement.unit,
        min: measurement.ranges?.min ?? getMinValueForType(key),
        max: measurement.ranges?.max ?? getMaxValueForType(key),
        warning: measurement.ranges?.warning,
        critical: measurement.ranges?.critical
      }
    });

    // Add to components array for backward compatibility
    components.push({
      type: "gauge",
      title: key.charAt(0).toUpperCase() + key.slice(1),
      topic: `iot/device/${device.type}/${key}`,
      config: {
        unit: measurement.unit,
        min: measurement.ranges?.min ?? getMinValueForType(key),
        max: measurement.ranges?.max ?? getMaxValueForType(key),
        warning: measurement.ranges?.warning,
        critical: measurement.ranges?.critical
      }
    });
  });

  // Add multi-measurement chart if there are multiple measurements
  if (Object.keys(measurements).length > 1) {
    // Add to screens/widgets structure
    screen.widgets.push({
      type: "chart",
      componentId: "measurements-chart",
      properties: {
        title: "Real-time Measurements",
        chartType: "line",
        timeRange: "1h",
        metrics: Object.entries(measurements).map(([key, measurement]) => ({
          id: key,
          label: key.charAt(0).toUpperCase() + key.slice(1),
          unit: measurement.unit,
          min: measurement.ranges?.min ?? getMinValueForType(key),
          max: measurement.ranges?.max ?? getMaxValueForType(key),
          warning: measurement.ranges?.warning,
          critical: measurement.ranges?.critical
        }))
      }
    });

    // Add to components array for backward compatibility
    components.push({
      type: "chart",
      title: "Real-time Measurements",
      config: {
        chartType: "line",
        timeRange: "1h",
        metrics: Object.entries(measurements).map(([key, measurement]) => ({
          id: key,
          label: key.charAt(0).toUpperCase() + key.slice(1),
          unit: measurement.unit,
          min: measurement.ranges?.min ?? getMinValueForType(key),
          max: measurement.ranges?.max ?? getMaxValueForType(key),
          warning: measurement.ranges?.warning,
          critical: measurement.ranges?.critical
        }))
      }
    });
  }
}

function addIrrigationComponents(screen: UiScreen, components: UiComponent[], device: DeviceConfig) {
  // Add zone controls
  if (device.config.zones) {
    device.config.zones.forEach(zone => {
      // Add to screens/widgets structure
      screen.widgets.push({
        type: "toggle",
        componentId: `zone-${zone.id}`,
        properties: {
          title: zone.name,
          topic: `iot/device/${device.type}/zone/${zone.id}/state`,
          maxDuration: zone.maxDuration
        }
      });

      // Add to components array for backward compatibility
      components.push({
        type: "switch", // Using "switch" for backward compatibility
        title: zone.name,
        topic: `iot/device/${device.type}/zone/${zone.id}/state`,
        config: {
          maxDuration: zone.maxDuration
        }
      });
    });

    // Always add scheduler for irrigation devices
    // Add to screens/widgets structure
    screen.widgets.push({
      type: "scheduler",
      componentId: "schedule",
      properties: {
        title: "Irrigation Schedule",
        zones: device.config.zones.map(zone => ({
          id: zone.id,
          name: zone.name,
          maxDuration: zone.maxDuration
        })),
        defaultDuration: device.config.scheduler?.defaultDuration || 30,
        maxDuration: device.config.scheduler?.maxDuration || 120,
        scheduleTopic: `iot/device/${device.type}/schedule`
      }
    });

    // Add to components array for backward compatibility
    components.push({
      type: "scheduler",
      title: "Irrigation Schedule",
      config: {
        zones: device.config.zones.map(zone => ({
          id: zone.id,
          name: zone.name,
          maxDuration: zone.maxDuration
        })),
        defaultDuration: device.config.scheduler?.defaultDuration || 30,
        maxDuration: device.config.scheduler?.maxDuration || 120
      }
    });
  }
}

function addEnvironmentSensorComponents(screen: UiScreen, components: UiComponent[], device: DeviceConfig) {
  // Add measurement gauges
  const measurements = device.config.measurements || {};
  
  // Use Object.entries to iterate over the measurements object
  Object.entries(measurements).forEach(([key, measurement]) => {
    // Add to screens/widgets structure
    screen.widgets.push({
      type: "gauge",
      componentId: `${key}-gauge`,
      properties: {
        title: key.charAt(0).toUpperCase() + key.slice(1),
        topic: `iot/device/${device.type}/${key}`,
        unit: measurement.unit,
        min: measurement.ranges?.min ?? getMinValueForType(key),
        max: measurement.ranges?.max ?? getMaxValueForType(key),
        warning: measurement.ranges?.warning,
        critical: measurement.ranges?.critical
      }
    });

    // Add to components array for backward compatibility
    components.push({
      type: "gauge",
      title: key.charAt(0).toUpperCase() + key.slice(1),
      topic: `iot/device/${device.type}/${key}`,
      config: {
        unit: measurement.unit,
        min: measurement.ranges?.min ?? getMinValueForType(key),
        max: measurement.ranges?.max ?? getMaxValueForType(key),
        warning: measurement.ranges?.warning,
        critical: measurement.ranges?.critical
      }
    });
  });

  // Add battery status if present
  if (device.config.battery) {
    // Add to screens/widgets structure
    screen.widgets.push({
      type: "status",
      componentId: "battery",
      properties: {
        title: "Battery",
        topic: `iot/device/${device.type}/battery`,
        unit: device.config.battery.unit,
        min: device.config.battery.ranges.min,
        max: device.config.battery.ranges.max,
        warning: device.config.battery.ranges.warning,
        critical: device.config.battery.ranges.critical
      }
    });

    // Add to components array for backward compatibility
    components.push({
      type: "status",
      title: "Battery",
      topic: `iot/device/${device.type}/battery`,
      config: {
        unit: device.config.battery.unit,
        ranges: {
          min: device.config.battery.ranges.min,
          max: device.config.battery.ranges.max,
          warning: device.config.battery.ranges.warning,
          critical: device.config.battery.ranges.critical
        }
      }
    });
  }
}

function getMaxValueForType(type: string): number {
  switch (type) {
    case "voltage": return 500;
    case "current": return 100;
    case "power": return 50;
    case "temperature": return 50;
    case "humidity": return 100;
    case "co2": return 5000;
    default: return 100;
  }
}

function getMinValueForType(type: string): number {
  switch (type) {
    case "temperature": return -20;
    default: return 0;
  }
}