import 'package:flutter/material.dart';
import 'dart:convert';

/// A widget that renders dynamic UI components based on JSON configuration
class DynamicUIComponents extends StatelessWidget {
  final Map<String, dynamic> uiConfig;
  final Map<String, dynamic>? deviceState;
  final Function(String, dynamic)? onControlAction;

  const DynamicUIComponents({
    Key? key,
    required this.uiConfig,
    this.deviceState,
    this.onControlAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> components = [];
    
    for (final component in uiConfig['components']) {
      switch (component['type']) {
        case 'header':
          components.add(_buildHeader(context, component));
          break;
        case 'status':
          components.add(_buildStatus(context, component));
          break;
        case 'toggle':
          components.add(_buildToggle(context, component));
          break;
        case 'gauge':
          components.add(_buildGauge(context, component));
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

  Widget _buildHeader(BuildContext context, Map<String, dynamic> component) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          component['title'],
          style: Theme.of(context).textTheme.headline5,
        ),
        Text(
          component['subtitle'],
          style: Theme.of(context).textTheme.subtitle1,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatus(BuildContext context, Map<String, dynamic> component) {
    final String field = component['field'];
    final bool isConnected = deviceState != null && 
                            deviceState!['connection'] == 'connected';
    
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

  Widget _buildToggle(BuildContext context, Map<String, dynamic> component) {
    final String field = component['field'];
    final bool value = deviceState != null && 
                      deviceState![field] != null ? 
                      deviceState![field] : false;
    
    return Card(
      child: SwitchListTile(
        title: Text(component['label']),
        value: value,
        onChanged: (newValue) {
          if (onControlAction != null) {
            onControlAction!(field, newValue);
          }
        },
      ),
    );
  }

  Widget _buildGauge(BuildContext context, Map<String, dynamic> component) {
    final String field = component['field'];
    final dynamic value = deviceState != null && 
                        deviceState![field] != null ? 
                        deviceState![field] : 0;
    final String displayValue = value.toString();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              component['label'],
              style: Theme.of(context).textTheme.subtitle1,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.thermostat, size: 32),
                const SizedBox(width: 8),
                Text(
                  '$displayValue ${component['unit'] ?? ''}',
                  style: Theme.of(context).textTheme.headline5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A screen that displays a device UI based on dynamic configuration
class DeviceScreen extends StatefulWidget {
  final String deviceId;
  final Map<String, dynamic> uiConfig;

  const DeviceScreen({
    Key? key,
    required this.deviceId,
    required this.uiConfig,
  }) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  Map<String, dynamic> _deviceState = {
    'connection': 'connected',
    'relay1': false,
    'temperature': 22.5,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uiConfig['title'] ?? 'Device'),
        subtitle: Text(widget.uiConfig['subtitle'] ?? ''),
      ),
      body: DynamicUIComponents(
        uiConfig: widget.uiConfig,
        deviceState: _deviceState,
        onControlAction: _handleControlAction,
      ),
    );
  }

  void _handleControlAction(String field, dynamic value) {
    setState(() {
      _deviceState[field] = value;
    });
    
    // In a real app, this would publish to IoT
    print('Control action: $field = $value');
  }
}