import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/ui_layout.dart';
import '../core/services/device_ui_service.dart';
import '../core/services/mqtt_service.dart';
import '../widgets/dynamic_component.dart';

/// Enhanced device screen that renders dynamic UI based on device configuration
class DeviceScreenEnhanced extends ConsumerStatefulWidget {
  final String deviceId;
  final String? deviceName;

  const DeviceScreenEnhanced({
    Key? key,
    required this.deviceId,
    this.deviceName,
  }) : super(key: key);

  @override
  ConsumerState<DeviceScreenEnhanced> createState() => _DeviceScreenEnhancedState();
}

class _DeviceScreenEnhancedState extends ConsumerState<DeviceScreenEnhanced> {
  UiLayout? _uiLayout;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _deviceState = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceUI();
  }

  Future<void> _loadDeviceUI() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get device UI layout
      final uiService = ref.read(deviceUiServiceProvider);
      final uiLayout = await uiService.getDeviceUI(widget.deviceId);

      // Subscribe to device status updates
      final mqttService = ref.read(mqttServiceProvider);
      final statusStream = mqttService.subscribeToDeviceStatus(widget.deviceId);
      
      // Listen for status updates
      statusStream.listen((data) {
        setState(() {
          _deviceState = data;
        });
      });

      setState(() {
        _uiLayout = uiLayout;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load device UI: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceName ?? 'Device ${widget.deviceId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeviceUI,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDeviceUI,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_uiLayout == null) {
      return const Center(
        child: Text('No UI layout available for this device'),
      );
    }

    // Convert UiLayout screens to DeviceUI screens
    final screens = _uiLayout!.screens.map((screen) {
      return UiScreen(
        id: screen.id,
        title: screen.title,
        widgets: screen.widgets,
      );
    }).toList();

    return DeviceUI(
      deviceId: widget.deviceId,
      screens: screens,
    );
  }
}