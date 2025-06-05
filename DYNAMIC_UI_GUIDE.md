# Dynamic UI Implementation Guide

This guide explains how to implement and use the dynamic UI system for IoT devices.

## Overview

The dynamic UI system allows devices to define their own user interface by sending a configuration JSON to AWS IoT Core. This configuration is processed by a Lambda function that generates a UI layout JSON, which is then stored in S3. The Flutter app downloads and renders this layout dynamically.

## Device Configuration Format

Devices should publish a configuration JSON to the MQTT topic `device/{deviceId}/config` with the following format:

```json
{
  "deviceId": "esp32-relay-001",
  "type": "relay",
  "location": "Floor 1 - Generator Room",
  "features": ["relay1", "relay2", "powerMeter"],
  "labels": {
    "relay1": "AC Main 1",
    "relay2": "AC Main 2",
    "powerMeter": "Power Consumption"
  },
  "uiVersion": "v1"
}
```

### Required Fields

- `deviceId`: Unique identifier for the device
- `type`: Type of device (relay, sensor, energyMeter, etc.)
- `features`: Array of features/capabilities the device supports

### Optional Fields

- `location`: Physical location of the device
- `labels`: Human-readable labels for features
- `uiVersion`: Version of the UI schema

## Testing the System

### 1. Publish Device Configuration

Use the provided script to publish a device configuration:

```bash
.\test-device-config.bat
```

Or manually with AWS CLI:

```bash
aws iot-data publish --topic "device/esp32-relay-001/config" --payload file://lambda/ui-generator/examples/relay-controller-config.json
```

### 2. Test Lambda Function

Test the Lambda function locally:

```bash
.\test-lambda.bat
```

### 3. Verify UI Layout in S3

Check the S3 bucket for the generated UI layout:

```bash
aws s3 cp s3://your-bucket/users/userId/devices/deviceId.json .
```

### 4. Test Flutter App

Run the Flutter app and navigate to the device screen to see the dynamic UI in action.

## Troubleshooting

### Lambda Not Processing Config

- Check IoT Rule SQL statement
- Verify Lambda permissions
- Check CloudWatch logs for errors

### S3 Access Issues

- Verify IAM permissions
- Check Cognito identity pool configuration
- Ensure correct S3 bucket policy

### Flutter App Not Rendering UI

- Check S3 path format
- Verify authentication is working
- Look for errors in app logs