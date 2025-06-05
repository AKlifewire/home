import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';
import '../widgets/device_card.dart';
import '../widgets/device_stats_card.dart';
import 'device_screen_improved.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _fetchDevices,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDeviceStats(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Devices',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to all devices
                              },
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRecentDevices(),
                        const SizedBox(height: 24),
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDeviceStats() {
    // Count devices by type and status
    int totalDevices = _devices.length;
    int onlineDevices = _devices.where((d) => d['status'] == 'online').length;
    int relayDevices = _devices.where((d) => d['type'] == 'relay').length;
    int sensorDevices = _devices.where((d) => d['type'] == 'sensor').length;

    return DeviceStatsCard(
      title: 'Device Statistics',
      stats: [
        DeviceStat(
          label: 'Total Devices',
          value: totalDevices.toString(),
          icon: Icons.devices,
          color: Colors.blue,
        ),
        DeviceStat(
          label: 'Online',
          value: '$onlineDevices/$totalDevices',
          icon: Icons.wifi,
          color: Colors.green,
        ),
        DeviceStat(
          label: 'Relays',
          value: relayDevices.toString(),
          icon: Icons.power,
          color: Colors.orange,
        ),
        DeviceStat(
          label: 'Sensors',
          value: sensorDevices.toString(),
          icon: Icons.thermostat,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildRecentDevices() {
    if (_devices.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No devices found'),
          ),
        ),
      );
    }

    // Show only the first 3 devices
    final recentDevices = _devices.take(3).toList();

    return Column(
      children: recentDevices.map((device) {
        return DeviceCard(
          name: device['name'] ?? 'Unnamed Device',
          type: device['type'] ?? 'unknown',
          location: device['location'],
          status: device['status'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceScreen(deviceId: device['id']),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildActionCard(
          'All Lights',
          Icons.lightbulb,
          Colors.amber,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Controlling all lights')),
            );
          },
        ),
        _buildActionCard(
          'All Relays',
          Icons.power,
          Colors.green,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Controlling all relays')),
            );
          },
        ),
        _buildActionCard(
          'Add Device',
          Icons.add_circle,
          Colors.blue,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add device functionality coming soon')),
            );
          },
        ),
        _buildActionCard(
          'Settings',
          Icons.settings,
          Colors.grey,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings functionality coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}