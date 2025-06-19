import '../models/device.dart';

/// Mock service for demo purposes
/// This provides sample data when the app is not connected to a real backend
class MockService {
  /// Get a list of mock devices
  static List<Device> getMockDevices() {
    return [
      Device(
        id: 'device-001',
        name: 'Living Room Light',
        type: 'light',
        status: {
          'power': true,
          'brightness': 80,
          'color': '#FFAA00',
        },
        owner: 'user123',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Device(
        id: 'device-002',
        name: 'Kitchen Thermostat',
        type: 'thermostat',
        status: {
          'power': true,
          'temperature': 22.5,
          'targetTemperature': 23.0,
          'humidity': 45,
          'mode': 'auto',
        },
        owner: 'user123',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Device(
        id: 'device-003',
        name: 'Garden Irrigation',
        type: 'irrigation',
        status: {
          'power': false,
          'schedule': 'active',
          'moisture': 65,
          'lastWatered': '2023-05-15T08:30:00Z',
        },
        owner: 'user123',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Device(
        id: 'device-004',
        name: 'Bedroom Sensor',
        type: 'sensor',
        status: {
          'temperature': 21.0,
          'humidity': 40,
          'motion': false,
          'battery': 85,
        },
        owner: 'user123',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  /// Get a mock UI layout for a device
  static Map<String, dynamic> getMockLayout(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'light':
        return {
          'widgets': [
            {
              'id': 'header1',
              'type': 'header',
              'title': 'Light Control',
              'properties': {'fontSize': 24.0}
            },
            {
              'id': 'switch1',
              'type': 'toggle',
              'title': 'Power',
              'binding': {'key': 'power'},
              'properties': {}
            },
            {
              'id': 'slider1',
              'type': 'slider',
              'title': 'Brightness',
              'binding': {'key': 'brightness'},
              'properties': {'min': 0.0, 'max': 100.0, 'unit': '%'}
            }
          ]
        };
      case 'thermostat':
        return {
          'widgets': [
            {
              'id': 'header1',
              'type': 'header',
              'title': 'Thermostat',
              'properties': {'fontSize': 24.0}
            },
            {
              'id': 'switch1',
              'type': 'toggle',
              'title': 'Power',
              'binding': {'key': 'power'},
              'properties': {}
            },
            {
              'id': 'gauge1',
              'type': 'gauge',
              'title': 'Current Temperature',
              'binding': {'key': 'temperature'},
              'properties': {'min': 10.0, 'max': 30.0, 'unit': '°C'}
            },
            {
              'id': 'slider1',
              'type': 'slider',
              'title': 'Target Temperature',
              'binding': {'key': 'targetTemperature'},
              'properties': {'min': 16.0, 'max': 28.0, 'unit': '°C'}
            },
            {
              'id': 'status1',
              'type': 'status',
              'title': 'Mode',
              'binding': {'key': 'mode'},
              'properties': {
                'statusMap': {
                  'auto': 'Automatic',
                  'heat': 'Heating',
                  'cool': 'Cooling',
                  'off': 'Off'
                },
                'colorMap': {
                  'auto': '#0088FF',
                  'heat': '#FF4400',
                  'cool': '#00AAFF',
                  'off': '#888888'
                }
              }
            }
          ]
        };
      case 'irrigation':
        return {
          'widgets': [
            {
              'id': 'header1',
              'type': 'header',
              'title': 'Irrigation System',
              'properties': {'fontSize': 24.0}
            },
            {
              'id': 'switch1',
              'type': 'toggle',
              'title': 'Power',
              'binding': {'key': 'power'},
              'properties': {}
            },
            {
              'id': 'gauge1',
              'type': 'gauge',
              'title': 'Soil Moisture',
              'binding': {'key': 'moisture'},
              'properties': {'min': 0.0, 'max': 100.0, 'unit': '%'}
            },
            {
              'id': 'scheduler1',
              'type': 'scheduler',
              'title': 'Watering Schedule',
              'properties': {
                'zones': [
                  {'id': 'zone1', 'name': 'Front Lawn', 'maxDuration': 30},
                  {'id': 'zone2', 'name': 'Back Garden', 'maxDuration': 45},
                  {'id': 'zone3', 'name': 'Flower Beds', 'maxDuration': 15}
                ]
              }
            },
            {
              'id': 'actions1',
              'type': 'actionPanel',
              'title': 'Quick Actions',
              'properties': {
                'actions': [
                  {'label': 'Water Now', 'key': 'waterNow', 'value': true},
                  {'label': 'Skip Next', 'key': 'skipNext', 'value': true},
                  {'label': 'Run Diagnostics', 'key': 'runDiagnostics', 'value': true}
                ]
              }
            }
          ]
        };
      case 'sensor':
        return {
          'widgets': [
            {
              'id': 'header1',
              'type': 'header',
              'title': 'Environmental Sensor',
              'properties': {'fontSize': 24.0}
            },
            {
              'id': 'gauge1',
              'type': 'gauge',
              'title': 'Temperature',
              'binding': {'key': 'temperature'},
              'properties': {'min': 10.0, 'max': 30.0, 'unit': '°C'}
            },
            {
              'id': 'gauge2',
              'type': 'gauge',
              'title': 'Humidity',
              'binding': {'key': 'humidity'},
              'properties': {'min': 0.0, 'max': 100.0, 'unit': '%'}
            },
            {
              'id': 'status1',
              'type': 'status',
              'title': 'Motion',
              'binding': {'key': 'motion'},
              'properties': {
                'statusMap': {
                  'true': 'Detected',
                  'false': 'Clear'
                },
                'colorMap': {
                  'true': '#FF0000',
                  'false': '#00FF00'
                }
              }
            },
            {
              'id': 'gauge3',
              'type': 'gauge',
              'title': 'Battery',
              'binding': {'key': 'battery'},
              'properties': {'min': 0.0, 'max': 100.0, 'unit': '%'}
            }
          ]
        };
      default:
        return {
          'widgets': [
            {
              'id': 'header1',
              'type': 'header',
              'title': 'Device Control',
              'properties': {'fontSize': 24.0}
            },
            {
              'id': 'status1',
              'type': 'status',
              'title': 'Status',
              'binding': {'key': 'status'},
              'properties': {}
            }
          ]
        };
    }
  }
}