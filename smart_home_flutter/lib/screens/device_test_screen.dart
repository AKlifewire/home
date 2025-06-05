import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../utils/device_simulator.dart';

class DeviceTestScreen extends StatefulWidget {
  const DeviceTestScreen({Key? key}) : super(key: key);

  @override
  State<DeviceTestScreen> createState() => _DeviceTestScreenState();
}

class _DeviceTestScreenState extends State<DeviceTestScreen> {
  final TextEditingController _deviceIdController = TextEditingController();
  final List<String> _logs = [];
  DeviceSimulator? _simulator;
  bool _isSimulatingTemperature = false;
  bool _isSimulatingRelay = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _simulator?.stop();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 100) {
        _logs.removeAt(0);
      }
    });
  }

  void _startTemperatureSimulation() {
    final deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) {
      _addLog('Please enter a device ID');
      return;
    }

    _simulator = DeviceSimulator(deviceId);
    _simulator!.startTemperatureSimulation();
    setState(() {
      _isSimulatingTemperature = true;
    });
    _addLog('Started temperature simulation for $deviceId');
  }

  void _startRelaySimulation() {
    final deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) {
      _addLog('Please enter a device ID');
      return;
    }

    _simulator = DeviceSimulator(deviceId);
    _simulator!.startRelaySimulation();
    setState(() {
      _isSimulatingRelay = true;
    });
    _addLog('Started relay simulation for $deviceId');
  }

  void _stopSimulation() {
    _simulator?.stop();
    setState(() {
      _isSimulatingTemperature = false;
      _isSimulatingRelay = false;
    });
    _addLog('Stopped simulation');
  }

  Future<void> _fetchDevices() async {
    try {
      _addLog('Fetching devices...');
      
      final request = GraphQLRequest<String>(
        document: '''
          query GetMyDevices {
            getMyDevices {
              id
              name
              type
              location
              status
            }
          }
        ''',
      );
      
      final response = await Amplify.API.query(request: request).response;
      
      if (response.errors.isNotEmpty) {
        _addLog('Error: ${response.errors.first.message}');
        return;
      }
      
      _addLog('Devices: ${response.data}');
    } catch (e) {
      _addLog('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Test Tool'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: 'Device ID',
                hintText: 'Enter device ID to simulate',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isSimulatingTemperature ? null : _startTemperatureSimulation,
                  child: const Text('Simulate Temperature'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSimulatingRelay ? null : _startRelaySimulation,
                  child: const Text('Simulate Relay'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_isSimulatingTemperature || _isSimulatingRelay) ? _stopSimulation : null,
                  child: const Text('Stop Simulation'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDevices,
              child: const Text('Fetch Devices'),
            ),
            const SizedBox(height: 16),
            const Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(_logs[index], style: const TextStyle(fontFamily: 'monospace'));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}