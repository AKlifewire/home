import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../providers/mqtt_provider.dart';
import '../services/layout_service.dart';

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  bool _isLoading = false;
  final Map<String, bool> _testResults = {
    'auth': false,
    'api': false,
    'mqtt': false,
    'storage': false,
  };
  final Map<String, String> _testMessages = {
    'auth': 'Not tested',
    'api': 'Not tested',
    'mqtt': 'Not tested',
    'storage': 'Not tested',
  };

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
    });

    await _testAuth();
    await _testApi();
    await _testMqtt();
    await _testStorage();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testAuth() async {
    try {
      setState(() {
        _testMessages['auth'] = 'Testing authentication...';
      });

      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
      await authProvider.checkAuthStatus();

      setState(() {
        _testResults['auth'] = authProvider.isAuthenticated;
        _testMessages['auth'] = authProvider.isAuthenticated
            ? 'Authentication successful. User: ${authProvider.username}'
            : 'Not authenticated';
      });
    } catch (e) {
      setState(() {
        _testResults['auth'] = false;
        _testMessages['auth'] = 'Authentication error: $e';
      });
    }
  }

  Future<void> _testApi() async {
    try {
      setState(() {
        _testMessages['api'] = 'Testing API connection...';
      });

      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final result = await deviceProvider.testBackendConnection();

      setState(() {
        _testResults['api'] = result;
        _testMessages['api'] = result
            ? 'API connection successful'
            : 'API connection failed';
      });
    } catch (e) {
      setState(() {
        _testResults['api'] = false;
        _testMessages['api'] = 'API error: $e';
      });
    }
  }

  Future<void> _testMqtt() async {
    try {
      setState(() {
        _testMessages['mqtt'] = 'Testing MQTT connection...';
      });

      final mqttProvider = Provider.of<MqttProvider>(context, listen: false);
      await mqttProvider.connect();

      setState(() {
        _testResults['mqtt'] = mqttProvider.isConnected;
        _testMessages['mqtt'] = mqttProvider.isConnected
            ? 'MQTT connection successful'
            : 'MQTT connection failed';
      });
    } catch (e) {
      setState(() {
        _testResults['mqtt'] = false;
        _testMessages['mqtt'] = 'MQTT error: $e';
      });
    }
  }

  Future<void> _testStorage() async {
    try {
      setState(() {
        _testMessages['storage'] = 'Testing S3 storage...';
      });

      // Try to fetch a test layout
      final layoutService = LayoutService();
      
      try {
        await layoutService.fetchDeviceLayout('test-device', 'test');
        setState(() {
          _testResults['storage'] = true;
          _testMessages['storage'] = 'Storage connection successful';
        });
      } catch (e) {
        // Even if we can't fetch a specific layout, check if the error is about
        // the layout not existing rather than a connection issue
        if (e.toString().contains('NoSuchKey') || 
            e.toString().contains('not found')) {
          setState(() {
            _testResults['storage'] = true;
            _testMessages['storage'] = 'Storage connection successful (layout not found)';
          });
        } else {
          throw e;
        }
      }
    } catch (e) {
      setState(() {
        _testResults['storage'] = false;
        _testMessages['storage'] = 'Storage error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Testing connections to backend services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Test results
            Expanded(
              child: ListView(
                children: [
                  _buildTestResultTile(
                    'Authentication (Cognito)',
                    _testResults['auth']!,
                    _testMessages['auth']!,
                  ),
                  _buildTestResultTile(
                    'API (AppSync)',
                    _testResults['api']!,
                    _testMessages['api']!,
                  ),
                  _buildTestResultTile(
                    'MQTT (IoT Core)',
                    _testResults['mqtt']!,
                    _testMessages['mqtt']!,
                  ),
                  _buildTestResultTile(
                    'Storage (S3)',
                    _testResults['storage']!,
                    _testMessages['storage']!,
                  ),
                ],
              ),
            ),
            
            // Overall status
            Card(
              color: _allTestsPassed()
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _allTestsPassed()
                          ? Icons.check_circle
                          : Icons.error,
                      color: _allTestsPassed()
                          ? Colors.green
                          : Colors.red,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _allTestsPassed()
                            ? 'All connections successful!'
                            : 'Some connections failed. Check details above.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _allTestsPassed()
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Retry button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runTests,
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Testing connections...'),
                        ],
                      )
                    : const Text('Retry All Tests'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultTile(String title, bool passed, String message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          passed ? Icons.check_circle : Icons.error,
          color: passed ? Colors.green : Colors.red,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(message),
        isThreeLine: message.length > 40,
      ),
    );
  }

  bool _allTestsPassed() {
    return _testResults.values.every((passed) => passed);
  }
}