# Universal Device Test Engine

This test framework provides a config-driven approach to E2E testing for IoT devices with dynamic UI components.

## How to Run the Tests

### 1. Install Dependencies

Make sure you have all the required dependencies:

```bash
flutter pub get
```

### 2. Run the Device UI Test

This test uses the existing test UI components in the app:

```bash
flutter test integration_test/device_ui_test.dart
```

### 3. Run the Full E2E Device Flow Test

This test requires authentication and API access:

```bash
flutter test integration_test/e2e_device_flow_test.dart
```

## Test Configuration

Device test configurations are stored in JSON files in the `test_configs/` directory. Each file defines:

- Device properties (ID, type, title)
- UI components to test
- MQTT topics for interaction

Example:

```json
{
  "deviceId": "test-relay",
  "deviceType": "relay",
  "title": "Test Relay",
  "subtitle": "Living Room",
  "components": [
    {
      "type": "toggle",
      "field": "relay1",
      "label": "Relay 1",
      "topic": "iot/control/test-relay/relay"
    }
  ]
}
```

## Adding New Device Types

To test a new device type:

1. Create a new JSON file in `test_configs/`
2. Define the device properties and components
3. Run the tests - no code changes needed!

## Troubleshooting

- If authentication fails, check your AWS credentials
- If MQTT connection fails, verify the broker settings
- If component tests fail, ensure the UI components match the expected types