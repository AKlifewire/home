# Universal Device Test Engine

This test framework provides a config-driven approach to E2E testing for IoT devices with dynamic UI components.

## Overview

The framework allows testing hundreds of different device types without writing custom test code for each one. Instead, you define device configurations in JSON files and the test engine handles:

1. Device registration
2. UI JSON generation and fetching
3. UI rendering
4. Component validation and interaction
5. MQTT message publishing and subscription

## Directory Structure

```
integration_test/
  ├── e2e_device_flow_test.dart    # Main test runner
  ├── device_simulator_test.dart   # MQTT simulator demo
  ├── mqtt_simulator.dart          # MQTT data simulator
  ├── helpers/
  │   └── test_runner.dart         # Core test engine
  └── test_configs/                # Device test configurations
      ├── test-relay.json
      ├── test-sensor.json
      ├── test-chart.json
      └── test-complex.json
```

## How to Use

### 1. Create Device Test Configurations

Add JSON files to `test_configs/` directory with your device specifications:

```json
{
  "deviceId": "test-sensor",
  "deviceType": "sensor",
  "title": "Test Sensor",
  "subtitle": "Kitchen",
  "components": [
    {
      "type": "gauge",
      "field": "temperature",
      "label": "Temperature",
      "topic": "iot/data/test-sensor",
      "min": 0,
      "max": 100,
      "unit": "°C"
    }
  ]
}
```

### 2. Run the Tests

```bash
flutter test integration_test/e2e_device_flow_test.dart
```

### 3. Simulate MQTT Data (Optional)

Use the MQTT simulator to generate test data:

```dart
final simulator = MqttSimulator();
await simulator.connect();

simulator.simulateSensor(
  deviceId: 'test-sensor',
  field: 'temperature',
  min: 18.0,
  max: 30.0,
  interval: Duration(seconds: 1),
);
```

## Adding New Device Types

To test a new device type:

1. Create a new JSON file in `test_configs/`
2. Define the device properties and components
3. Run the tests - no code changes needed!

## Component Testing

The framework automatically tests different component types:

- **toggle**: Taps the switch and verifies state change
- **gauge**: Verifies rendering and publishes test values
- **chart**: Publishes multiple data points and verifies rendering
- **status**: Tests status changes
- **text/header**: Verifies text rendering
- **image**: Verifies image component rendering

## Test Metadata

Add test-specific metadata to control test behavior:

```json
{
  "type": "toggle",
  "field": "recording",
  "label": "Enable Recording",
  "topic": "iot/control/test-chart/config",
  "test": {
    "skip": true
  }
}
```

## Extending the Framework

To add support for new component types:

1. Update the `runDeviceFlowTest()` function in `test_runner.dart`
2. Add a new case to the component type switch statement
3. Implement the appropriate test logic