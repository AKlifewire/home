import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/device_ui_service.dart';
import '../core/services/graphql_service.dart';
import 'device_screen_enhanced.dart';

class EnhancedHomeScreen extends ConsumerStatefulWidget {
  const EnhancedHomeScreen({Key? key}) : super(key: key);

  @override
  _EnhancedHomeScreenState createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends ConsumerState<EnhancedHomeScreen> {
  late Future<List<DeviceListItem>> _devicesFuture;
  
  @override
  void initState() {
    super.initState();
    _devicesFuture = _loadDevices();
  }
  
  Future<List<DeviceListItem>> _loadDevices() async {
    try {
      final graphQLService = ref.read(graphQLServiceProvider);
      final result = await graphQLService.query(
        query: r'''
          query GetDevices {
            getDevices {
              deviceId
              name
              type
              location
            }
          }
        ''',
      );
      
      if (result.hasException) {
        throw Exception(result.exception.toString());
      }
      
      final devices = (result.data?['getDevices'] as List?)
          ?.map((device) => DeviceListItem.fromJson(device))
          .toList() ?? [];
      
      // Prefetch UI layouts for all devices
      if (devices.isNotEmpty) {
        final deviceUiService = ref.read(deviceUiServiceProvider);
        await deviceUiService.batchGetDeviceUIs(
          devices.map((d) => d.deviceId).toList()
        );
      }
      
      return devices;
    } catch (e) {
      print('Error loading devices: $e');
      rethrow;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _devicesFuture = _loadDevices();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<DeviceListItem>>(
        future: _devicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load devices: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _devicesFuture = _loadDevices();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final devices = snapshot.data!;
          
          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.devices, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No devices found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add-device');
                    },
                    child: const Text('Add Device'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return DeviceCard(device: device);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-device');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final DeviceListItem device;
  
  const DeviceCard({Key? key, required this.device}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(_getDeviceIcon(device.type)),
        title: Text(device.name),
        subtitle: Text(device.location ?? 'No location'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnhancedDeviceScreen(deviceId: device.deviceId),
            ),
          );
        },
      ),
    );
  }
  
  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'relay':
        return Icons.power;
      case 'sensor':
        return Icons.sensors;
      case 'thermostat':
        return Icons.thermostat;
      case 'camera':
        return Icons.camera_alt;
      default:
        return Icons.devices_other;
    }
  }
}

class DeviceListItem {
  final String deviceId;
  final String name;
  final String type;
  final String? location;
  
  DeviceListItem({
    required this.deviceId,
    required this.name,
    required this.type,
    this.location,
  });
  
  factory DeviceListItem.fromJson(Map<String, dynamic> json) {
    return DeviceListItem(
      deviceId: json['deviceId'],
      name: json['name'],
      type: json['type'],
      location: json['location'],
    );
  }
}