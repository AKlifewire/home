import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert'; // Add this import
import 'device_screen.dart';
import 'device_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
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
        setState(() {
          _error = response.errors.first.message;
          _isLoading = false;
        });
        return;
      }

      final data = response.data;
      if (data == null) {
        setState(() {
          _error = 'No data returned';
          _isLoading = false;
        });
        return;
      }

      final jsonData = jsonDecode(data);
      final devices = List<Map<String, dynamic>>.from(
        jsonData['getMyDevices'].map((device) => Map<String, dynamic>.from(device)),
      );

      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DeviceTestScreen()),
              );
            },
            tooltip: 'Test Tools',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDevices,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _devices.isEmpty
                  ? const Center(child: Text('No devices found'))
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return ListTile(
                          leading: Icon(_getIconForDeviceType(device['type'])),
                          title: Text(device['name'] ?? 'Unnamed Device'),
                          subtitle: Text(device['location'] ?? 'No location'),
                          trailing: _buildStatusIndicator(device['status']),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeviceScreen(deviceId: device['id']),
                              ),
                            );
                          },
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add device screen
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Device',
      ),
    );
  }

  IconData _getIconForDeviceType(String? type) {
    switch (type) {
      case 'relay':
        return Icons.power;
      case 'sensor':
        return Icons.thermostat;
      case 'camera':
        return Icons.camera_alt;
      default:
        return Icons.devices;
    }
  }

  Widget _buildStatusIndicator(String? status) {
    Color color;
    switch (status) {
      case 'online':
        color = Colors.green;
        break;
      case 'offline':
        color = Colors.grey;
        break;
      case 'error':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}