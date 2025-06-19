import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_state.dart';
import '../providers/mqtt_state.dart';
import '../widgets/dynamic_ui_builder.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
  });

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
  }

  Future<void> _loadDeviceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deviceState = ref.read(deviceProvider);
      
      // Check if we need to fetch devices
      if (deviceState.devices.isEmpty) {
        await ref.read(deviceProvider.notifier).fetchDevices();
      }
      
      // Connect MQTT if not already connected
      final mqttState = ref.read(mqttProvider);
      if (!mqttState.isConnected) {
        await ref.read(mqttProvider.notifier).connect();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load device data. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceProvider);
    final devices = deviceState.devices;
    
    // Find the device in the provider
    final deviceIndex = devices.indexWhere(
      (d) => d.id == widget.deviceId,
    );
    
    if (deviceIndex == -1 && !_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Device Not Found'),
        ),
        body: const Center(
          child: Text('The requested device could not be found.'),
        ),
      );
    }
    
    // If still loading or device not found yet, show loading screen
    if (_isLoading || deviceIndex == -1) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final device = devices[deviceIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDeviceData,
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDeviceData,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : DynamicUiBuilder(
              deviceId: widget.deviceId,
              deviceType: device.type,
              device: device,
            ),
    );
  }
}