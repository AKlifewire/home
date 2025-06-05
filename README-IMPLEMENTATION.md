# Smart Home IoT Platform Implementation Guide

This document provides an overview of the implementation details for the Smart Home IoT Platform with Dynamic UI.

## Architecture Overview

The platform consists of two main components:

1. **Backend (AWS CDK)**: Serverless infrastructure for device management, UI generation, and real-time communication.
2. **Frontend (Flutter)**: Cross-platform mobile app that dynamically renders device UIs based on configurations.

## Backend Components

### AWS CDK Stacks

- **AuthStack**: Cognito UserPool and IdentityPool for user authentication
- **AppSyncStack**: GraphQL API for device management and UI retrieval
- **IoTStack**: MQTT topics and rules for device communication
- **LambdaStack**: Business logic for device handling and UI generation
- **StorageStack**: S3 bucket for storing UI JSON layouts
- **SSMParameterStack**: Shared configuration parameters

### Key Lambda Functions

1. **Device Registration Handler** (`device-registration-handler.js`):
   - Processes device registration events
   - Stores device information in DynamoDB
   - Triggers UI generation

2. **Device Config to UI Converter** (`enhanced-device-config-to-ui.js`):
   - Converts device configuration to UI layout
   - Supports various device types and components
   - Stores UI layout in S3

## Frontend Components

### Core Services

1. **MQTT Service** (`enhanced_mqtt_service.dart`):
   - Handles real-time communication with devices
   - Manages subscriptions to device status topics
   - Provides reconnection logic

2. **Device UI Service** (`device_ui_service.dart`):
   - Fetches UI layouts from S3 or AppSync
   - Caches UI layouts for offline use
   - Provides fallback UI for devices without layouts

3. **Device Control Service** (`device_control_service.dart`):
   - Sends commands to devices via MQTT
   - Handles different command types (toggle, setValue, etc.)

### UI Components

1. **Smart Device Widget Factory** (`smart_device_widget_factory.dart`):
   - Creates widgets based on UI component definitions
   - Supports various widget types (toggle, gauge, chart, etc.)

2. **Dynamic Component** (`dynamic_component.dart`):
   - Renders UI components based on their type
   - Provides a unified interface for all component types

3. **Device Screen** (`device_screen_enhanced.dart`):
   - Renders dynamic UI based on device configuration
   - Handles multiple screens and tabs
   - Updates UI based on real-time device status

## Data Flow

### Device Registration Flow

1. Device connects to AWS IoT Core
2. Device publishes registration message to `device/register` topic
3. IoT Rule triggers `device-registration-handler` Lambda
4. Lambda stores device info in DynamoDB
5. Lambda triggers UI generation

### UI Generation Flow

1. `device-config-to-ui` Lambda receives device config
2. Lambda maps device components to UI widgets
3. Lambda generates UI layout JSON
4. Lambda stores UI layout in S3 under `users/{userId}/devices/{deviceId}/ui-layout.json`

### Device Control Flow

1. User interacts with UI component in app
2. App sends command via MQTT to `device/{deviceId}/control` topic
3. Device receives command and performs action
4. Device publishes status update to `device/{deviceId}/status` topic
5. App receives status update and updates UI

## Device Configuration Format

```json
{
  "deviceId": "relay-123",
  "type": "relay",
  "name": "Living Room Lights",
  "components": [
    {
      "type": "relay",
      "id": "relay1",
      "name": "Main Light",
      "config": {
        "defaultState": false
      }
    },
    {
      "type": "sensor",
      "id": "temp1",
      "name": "Temperature",
      "config": {
        "min": 0,
        "max": 50,
        "unit": "°C"
      }
    }
  ],
  "metadata": {
    "location": "Living Room",
    "manufacturer": "Acme Inc",
    "model": "Smart Relay v2"
  }
}
```

## UI Layout Format

```json
{
  "title": "Living Room Lights",
  "deviceId": "relay-123",
  "deviceType": "relay",
  "version": "1.0",
  "generated": "2023-06-15T12:34:56Z",
  "location": "Living Room",
  "screens": [
    {
      "id": "main",
      "title": "Main",
      "widgets": [
        {
          "type": "toggle",
          "id": "relay1",
          "title": "Main Light",
          "properties": {
            "topic": "device/relay-123/control",
            "statusTopic": "device/relay-123/status",
            "payload": {
              "command": "set",
              "component": "relay1",
              "value": "${value}"
            }
          }
        },
        {
          "type": "gauge",
          "id": "temp1",
          "title": "Temperature",
          "properties": {
            "min": 0,
            "max": 50,
            "unit": "°C",
            "statusTopic": "device/relay-123/status"
          }
        }
      ]
    }
  ]
}
```

## Testing

### Integration Tests

The project includes several integration tests to validate the end-to-end flow:

1. **Device Registration Test**: Tests the device registration process
2. **UI Generation Test**: Tests the UI generation from device config
3. **Device Control Test**: Tests sending commands to devices and receiving status updates

### Test Devices

The project includes several test device configurations for testing:

1. **Relay Controller**: A simple relay controller with on/off functionality
2. **Environmental Sensor**: A sensor that reports temperature, humidity, etc.
3. **Energy Meter**: A device that measures power consumption and generates charts

## Deployment

The project can be deployed to AWS using the CDK CLI:

```bash
# Deploy development environment
npm run deploy:dev

# Deploy production environment
npm run deploy:prod
```

## Future Enhancements

1. **Device Groups**: Group devices by room or function
2. **Automation Rules**: Create rules for device automation
3. **Voice Control**: Add voice control capabilities
4. **Analytics Dashboard**: Add analytics for device usage and performance
5. **Remote Access**: Access devices from outside the local network
6. **Multi-User Support**: Share devices with family members
7. **Device Firmware Updates**: Update device firmware over-the-air