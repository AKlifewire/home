import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Smart Home App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeviceListScreen()),
                );
              },
              child: const Text('View Devices'),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock device data
    final devices = [
      {
        'id': 'device-001',
        'name': 'Living Room Relay',
        'type': 'relay',
        'location': 'Living Room',
      },
      {
        'id': 'device-002',
        'name': 'Kitchen Sensor',
        'type': 'sensor',
        'location': 'Kitchen',
      },
      {
        'id': 'device-003',
        'name': 'Bedroom Light',
        'type': 'light',
        'location': 'Bedroom',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
      ),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                _getIconForDeviceType(device['type'] as String),
                color: Theme.of(context).primaryColor,
              ),
              title: Text(device['name'] as String),
              subtitle: Text(device['location'] as String),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeviceDetailScreen(
                      deviceId: device['id'] as String,
                      deviceName: device['name'] as String,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add device functionality coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForDeviceType(String deviceType) {
    switch (deviceType) {
      case 'relay':
        return Icons.power;
      case 'sensor':
        return Icons.sensors;
      case 'light':
        return Icons.lightbulb;
      default:
        return Icons.devices;
    }
  }
}

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const DeviceDetailScreen({
    Key? key,
    required this.deviceId,
    required this.deviceName,
  }) : super(key: key);

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _switchValue = false;
  double _gaugeValue = 75.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Main Power',
                      style: TextStyle(fontSize: 16),
                    ),
                    Switch(
                      value: _switchValue,
                      onChanged: (value) {
                        setState(() {
                          _switchValue = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Power ${value ? 'On' : 'Off'}')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Power Consumption',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Current Value:'),
                            Text(
                              '${_gaugeValue.toStringAsFixed(1)} W',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Slider(
                              value: _gaugeValue,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              label: _gaugeValue.round().toString(),
                              onChanged: (value) {
                                setState(() {
                                  _gaugeValue = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Device is ${_switchValue ? 'online' : 'offline'} and functioning normally',
                      style: TextStyle(
                        color: _switchValue ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}