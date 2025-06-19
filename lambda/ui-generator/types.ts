import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

// Device configuration types
export interface DeviceConfig {
  deviceId: string;
  deviceType: string;
  components: DeviceComponent[];
  metadata: DeviceMetadata;
}

export interface DeviceMetadata {
  name?: string;
  location?: string;
  [key: string]: any;
}

export interface DeviceComponent {
  type: string;           // 'relay' | 'sensor' | 'camera' | 'energyMeter' | etc
  id: string;            // Unique component ID
  name?: string;         // Display name
  capabilities: string[]; // What the component can do
  config: ComponentConfig;
}

export interface ComponentConfig {
  [key: string]: any;
}

// UI layout types
export interface UiLayout {
  version: string;
  metadata: {
    deviceId: string;
    lastUpdated: string;
  };
  screens: UiScreen[];
  components?: UiComponent[]; // For backward compatibility with tests
}

export interface UiScreen {
  id: string;
  title: string;
  widgets: UiWidget[];
}

export interface UiWidget {
  type: string;          // 'toggle' | 'gauge' | 'chart' | 'video' | etc
  componentId: string;   // References the device component
  properties: {
    [key: string]: any;
  };
}

// For backward compatibility with tests
export interface UiComponent {
  type: string;
  title: string;
  topic?: string;
  config?: {
    [key: string]: any;
    min?: number;
    max?: number;
    unit?: string;
    ranges?: {
      min: number;
      max: number;
      warning: number;
      critical: number;
    };
    zones?: Array<{
      id: string;
      name: string;
      maxDuration: number;
    }>;
  };
  components?: UiComponent[];
}

// Component to widget mapping type
export type ComponentWidgetMap = {
  [key: string]: string;
};

// Lambda handler type
export type UiGeneratorHandler = (event: APIGatewayProxyEvent) => Promise<APIGatewayProxyResult>;