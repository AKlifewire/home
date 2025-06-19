import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../models/ui_component.dart';
import '../providers/mqtt_state.dart';
import '../services/layout_service.dart';
import 'dynamic/dynamic_widget_factory.dart';

class DynamicUiBuilder extends ConsumerStatefulWidget {
  final String deviceId;
  final String deviceType;
  final Device device;

  const DynamicUiBuilder({
    Key? key,
    required this.deviceId,
    required this.deviceType,
    required this.device,
  }) : super(key: key);

  @override
  ConsumerState<DynamicUiBuilder> createState() => _DynamicUiBuilderState();
}

class _DynamicUiBuilderState extends ConsumerState<DynamicUiBuilder> {
  final LayoutService _layoutService = LayoutService();
  Map<String, dynamic> _deviceState = {};
  Map<String, dynamic>? _layout;
  List<UiComponent> _components = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _deviceState = Map<String, dynamic>.from(widget.device.status);
    _loadLayout();
    _setupMqttSubscription();
  }

  Future<void> _loadLayout() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final layout = await _layoutService.fetchDeviceLayout(
        widget.deviceId,
        widget.deviceType,
      );

      if (mounted) {
        setState(() {
          _layout = layout;
          _components = UiComponentFactory.createFromLayout(layout);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load UI layout: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _setupMqttSubscription() {
    ref.read(mqttProvider.notifier).subscribeToDevice(
      widget.deviceId,
      _handleMqttMessage,
    );
  }

  void _handleMqttMessage(Map<String, dynamic> message) {
    setState(() {
      _deviceState.addAll(message);
    });
  }

  void _handleControlValueChanged(String key, dynamic value) {
    setState(() {
      _deviceState[key] = value;
    });
    
    // Send command via MQTT
    ref.read(mqttProvider.notifier).publishToDevice(
      widget.deviceId,
      'control',
      {key: value},
    );
  }

  @override
  void dispose() {
    ref.read(mqttProvider.notifier).unsubscribeFromDevice(widget.deviceId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLayout,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_layout == null || _components.isEmpty) {
      return const Center(
        child: Text('No UI components found for this device'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _components.map((component) {
            return DynamicWidgetFactory.createWidget(
              component: component,
              deviceState: _deviceState,
              onControlValueChanged: _handleControlValueChanged,
            );
          }).toList(),
        ),
      ),
    );
  }
}