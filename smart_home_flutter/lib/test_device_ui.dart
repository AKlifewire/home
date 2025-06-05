import 'package:flutter/material.dart';

/// A test app for the dynamic UI components
class DynamicUITestApp extends StatelessWidget {
  const DynamicUITestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const DeviceUITestPage();
  }
}

class DeviceUITestPage extends StatefulWidget {
  const DeviceUITestPage({Key? key}) : super(key: key);

  @override
  State<DeviceUITestPage> createState() => _DeviceUITestPageState();
}

class _DeviceUITestPageState extends State<DeviceUITestPage> {
  final List<Map<String, dynamic>> _testDevices = [
    {
      "deviceId": "test-relay-f181fa48",
      "title": "Test Relay Controller",
      "subtitle": "Test Location",
      "deviceType": "relay",
      "components": [
        {
          "type": "header",
          "title": "Test Relay Controller",
          "subtitle": "Test Location"
        },
        {
          "type": "status",
          "field": "connection",
          "label": "Connection Status"
        },
        {
          "type": "toggle",
          "field": "relay1",
          "label": "Relay 1",
          "topic": "iot/control/test-relay-f181fa48/relay"
        }
      ]
    },
    {
      "deviceId": "test-sensor-a9e50c3e",
      "title": "Test Environment Sensor",
      "subtitle": "Test Room",
      "deviceType": "sensor",
      "components": [
        {
          "type": "header",
          "title": "Test Environment Sensor",
          "subtitle": "Test Room"
        },
        {
          "type": "status",
          "field": "connection",
          "label": "Connection Status"
        },
        {
          "type": "gauge",
          "field": "temperature",
          "label": "Temperature",
          "unit": "°C"
        }
      ]
    }
  ];

  int _selectedIndex = 0;
  Map<String, dynamic> _deviceStates = {
    "test-relay-f181fa48": {
      "connection": "connected",
      "relay1": false
    },
    "test-sensor-a9e50c3e": {
      "connection": "connected",
      "temperature": 22.5
    }
  };

  @override
  Widget build(BuildContext context) {
    final currentDevice = _testDevices[_selectedIndex];
    final deviceId = currentDevice["deviceId"];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(currentDevice["title"]),
      ),
      body: _buildDynamicUI(currentDevice, _deviceStates[deviceId]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.toggle_on),
            label: 'Relay',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.thermostat),
            label: 'Sensor',
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicUI(Map<String, dynamic> uiConfig, Map<String, dynamic> deviceState) {
    final List<Widget> components = [];
    
    for (final component in uiConfig['components']) {
      switch (component['type']) {
        case 'header':
          components.add(_buildHeader(component));
          break;
        case 'status':
          components.add(_buildStatus(component, deviceState));
          break;
        case 'toggle':
          components.add(_buildToggle(component, deviceState, uiConfig['deviceId']));
          break;
        case 'gauge':
          components.add(_buildGauge(component, deviceState));
          break;
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: components,
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> component) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          component['title'],
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          component['subtitle'],
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatus(Map<String, dynamic> component, Map<String, dynamic> deviceState) {
    final bool isConnected = deviceState['connection'] == 'connected';
    
    return Card(
      child: ListTile(
        title: Text(component['label']),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(Map<String, dynamic> component, Map<String, dynamic> deviceState, String deviceId) {
    final String field = component['field'];
    final bool value = deviceState[field] ?? false;
    
    return Card(
      child: SwitchListTile(
        title: Text(component['label']),
        value: value,
        onChanged: (newValue) {
          setState(() {
            _deviceStates[deviceId][field] = newValue;
          });
          print('Control action on $deviceId: $field = $newValue');
        },
      ),
    );
  }

  Widget _buildGauge(Map<String, dynamic> component, Map<String, dynamic> deviceState) {
    final String field = component['field'];
    final dynamic value = deviceState[field] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              component['label'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.thermostat, size: 32),
                const SizedBox(width: 8),
                Text(
                  '$value ${component['unit'] ?? ''}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}