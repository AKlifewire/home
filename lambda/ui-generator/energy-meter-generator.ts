import { DeviceConfig, UiLayout } from './types';

const componentToWidgetMap = {
  energyMeter: 'chart',
  powerMeter: 'gauge',
  powerFactor: 'gauge'
};

export async function generateEnergyMeterLayout(config: DeviceConfig): Promise<UiLayout> {
  // Create main dashboard screen
  const mainScreen = {
    id: 'main',
    title: config.metadata.name || `Energy Meter ${config.deviceId}`,
    widgets: []
  };

  // Add status widget
  mainScreen.widgets.push({
    type: 'summary',
    componentId: 'status',
    properties: {
      title: 'Device Status',
      items: [
        {
          id: 'status',
          label: 'Status',
          value: '${device.status}',
          icon: 'check_circle'
        },
        {
          id: 'lastSeen',
          label: 'Last Seen',
          value: '${device.lastSeen}',
          icon: 'access_time'
        }
      ]
    }
  });

  // Add voltage chart for all phases
  const phaseComponents = config.components.filter(c => c.type === 'energyMeter');
  if (phaseComponents.length > 0) {
    mainScreen.widgets.push({
      type: 'chart',
      componentId: 'voltage-chart',
      properties: {
        title: 'Phase Voltages',
        chartType: 'line',
        timeRange: '1h',
        metrics: phaseComponents.map(phase => ({
          id: phase.id,
          label: phase.name,
          color: phase.id === 'phase-1' ? '#F44336' : 
                 phase.id === 'phase-2' ? '#2196F3' : '#4CAF50',
          field: 'voltage',
          unit: 'V'
        }))
      }
    });
  }

  // Add current readings
  mainScreen.widgets.push({
    type: 'chart',
    componentId: 'current-chart',
    properties: {
      title: 'Phase Currents',
      chartType: 'line',
      timeRange: '1h',
      metrics: phaseComponents.map(phase => ({
        id: phase.id,
        label: phase.name,
        color: phase.id === 'phase-1' ? '#F44336' : 
               phase.id === 'phase-2' ? '#2196F3' : '#4CAF50',
        field: 'current',
        unit: 'A'
      }))
    }
  });

  // Add power gauge
  const powerMeter = config.components.find(c => c.type === 'powerMeter');
  if (powerMeter) {
    mainScreen.widgets.push({
      type: 'gauge',
      componentId: powerMeter.id,
      properties: {
        title: powerMeter.name,
        unit: powerMeter.config.unit,
        min: 0,
        max: powerMeter.config.maxPower,
        value: '${device.readings.power}',
        thresholds: {
          warning: powerMeter.config.maxPower * 0.8,
          critical: powerMeter.config.maxPower * 0.95
        }
      }
    });
  }

  // Add power factor display
  const pfMeter = config.components.find(c => c.type === 'powerFactor');
  if (pfMeter) {
    mainScreen.widgets.push({
      type: 'gauge',
      componentId: pfMeter.id,
      properties: {
        title: pfMeter.name,
        min: 0,
        max: 1,
        value: '${device.readings.powerFactor}',
        thresholds: {
          warning: 0.8,
          critical: 0.7
        }
      }
    });
  }

  // Add actions panel
  mainScreen.widgets.push({
    type: 'actionPanel',
    componentId: 'actions',
    properties: {
      title: 'Device Actions',
      actions: [
        {
          id: 'export',
          label: 'Export Data',
          icon: 'download',
          action: 'exportData',
          params: { deviceId: config.deviceId }
        },
        {
          id: 'settings',
          label: 'Settings',
          icon: 'settings',
          action: 'openSettings',
          params: { deviceId: config.deviceId }
        }
      ]
    }
  });

  return {
    version: '1.0',
    metadata: {
      deviceId: config.deviceId,
      lastUpdated: new Date().toISOString()
    },
    screens: [mainScreen]
  };
}
