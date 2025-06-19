import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';
import '../models/device.dart';
import '../services/layout_service.dart';

class DynamicUiRenderer extends StatefulWidget {
  final String deviceId;
  final String deviceType;
  final Device device;

  const DynamicUiRenderer({
    super.key,
    required this.deviceId,
    required this.deviceType,
    required this.device,
  });

  @override
  State<DynamicUiRenderer> createState() => _DynamicUiRendererState();
}

class _DynamicUiRendererState extends State<DynamicUiRenderer> {
  final LayoutService _layoutService = LayoutService();
  Map<String, dynamic> _deviceState = {};
  Map<String, dynamic>? _layout;
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
    final mqttProvider = Provider.of<MqttProvider>(context, listen: false);
    mqttProvider.subscribeToDevice(widget.deviceId, _handleMqttMessage);
  }

  void _handleMqttMessage(Map<String, dynamic> message) {
    setState(() {
      _deviceState.addAll(message);
    });
  }

  @override
  void dispose() {
    final mqttProvider = Provider.of<MqttProvider>(context, listen: false);
    mqttProvider.unsubscribeFromDevice(widget.deviceId);
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

    if (_layout == null || !_layout!.containsKey('widgets')) {
      return const Center(
        child: Text('Invalid UI layout format'),
      );
    }

    final List<dynamic> widgets = _layout!['widgets'] ?? [];
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets.map<Widget>((widgetConfig) {
            return _buildWidget(widgetConfig);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWidget(Map<String, dynamic> config) {
    final String type = config['type'] ?? '';
    final String title = config['title'] ?? '';
    final Map<String, dynamic> binding = config['binding'] ?? {};
    final Map<String, dynamic> properties = config['properties'] ?? {};
    
    // Get the bound value from device state
    dynamic value;
    if (binding.containsKey('key')) {
      final String key = binding['key'];
      value = _deviceState[key];
    }

    switch (type) {
      case 'header':
        return _buildHeader(title, properties);
      case 'gauge':
        return _buildGauge(title, value, properties);
      case 'toggle':
        return _buildToggle(title, value, binding, properties);
      case 'slider':
        return _buildSlider(title, value, binding, properties);
      case 'chart':
        return _buildChart(title, value, properties);
      case 'status':
        return _buildStatus(title, value, properties);
      case 'actionPanel':
        return _buildActionPanel(title, properties);
      case 'scheduler':
        return _buildScheduler(title, properties);
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Unsupported widget type: $type'),
        );
    }
  }

  Widget _buildHeader(String title, Map<String, dynamic> properties) {
    final subtitle = properties['subtitle'] as String?;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: properties['fontSize'] ?? 24.0,
              fontWeight: FontWeight.bold,
              color: properties['color'] != null
                  ? Color(int.parse(properties['color'], radix: 16))
                  : null,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: (properties['fontSize'] ?? 24.0) * 0.6,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGauge(String title, dynamic value, Map<String, dynamic> properties) {
    final double min = properties['min']?.toDouble() ?? 0.0;
    final double max = properties['max']?.toDouble() ?? 100.0;
    final String unit = properties['unit'] ?? '';
    final double currentValue = value?.toDouble() ?? min;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            LinearProgressIndicator(
              value: (currentValue - min) / (max - min),
              minHeight: 20,
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$min $unit'),
                Text('$currentValue $unit'),
                Text('$max $unit'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(
    String title,
    dynamic value,
    Map<String, dynamic> binding,
    Map<String, dynamic> properties,
  ) {
    final bool isOn = value == true;
    final String key = binding['key'] ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: isOn,
              onChanged: (newValue) {
                setState(() {
                  _deviceState[key] = newValue;
                });
                
                // Send command via MQTT
                final mqttProvider = Provider.of<MqttProvider>(context, listen: false);
                mqttProvider.publishToDevice(
                  widget.deviceId,
                  'control',
                  {key: newValue},
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String title,
    dynamic value,
    Map<String, dynamic> binding,
    Map<String, dynamic> properties,
  ) {
    final double min = properties['min']?.toDouble() ?? 0.0;
    final double max = properties['max']?.toDouble() ?? 100.0;
    final int divisions = properties['divisions'] ?? 100;
    final String unit = properties['unit'] ?? '';
    final String key = binding['key'] ?? '';
    final double currentValue = value?.toDouble() ?? min;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Text('$min'),
                Expanded(
                  child: Slider(
                    value: currentValue,
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: '$currentValue $unit',
                    onChanged: (newValue) {
                      setState(() {
                        _deviceState[key] = newValue;
                      });
                    },
                    onChangeEnd: (newValue) {
                      // Send command via MQTT
                      final mqttProvider = Provider.of<MqttProvider>(context, listen: false);
                      mqttProvider.publishToDevice(
                        widget.deviceId,
                        'control',
                        {key: newValue},
                      );
                    },
                  ),
                ),
                Text('$max'),
              ],
            ),
            Center(
              child: Text(
                '$currentValue $unit',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String title, dynamic value, Map<String, dynamic> properties) {
    // Placeholder for chart widget
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Text('Chart will be displayed here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(String title, dynamic value, Map<String, dynamic> properties) {
    final Map<String, dynamic> statusMap = properties['statusMap'] ?? {};
    final String status = value?.toString() ?? 'unknown';
    final String displayStatus = statusMap[status] ?? status;
    final Color statusColor = _getStatusColor(status, properties);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Chip(
              label: Text(displayStatus),
              backgroundColor: statusColor.withOpacity(0.2),
              labelStyle: TextStyle(color: statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, Map<String, dynamic> properties) {
    final Map<String, dynamic> colorMap = properties['colorMap'] ?? {};
    final String colorHex = colorMap[status] ?? '#000000';
    
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildActionPanel(String title, Map<String, dynamic> properties) {
    final List<dynamic> actions = properties['actions'] ?? [];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: actions.map<Widget>((action) {
                return ElevatedButton(
                  onPressed: () {
                    final String actionKey = action['key'] ?? '';
                    final dynamic actionValue = action['value'];
                    
                    // Send command via MQTT
                    final mqttProvider = Provider.of<MqttProvider>(context, listen: false);
                    mqttProvider.publishToDevice(
                      widget.deviceId,
                      'control',
                      {actionKey: actionValue},
                    );
                  },
                  child: Text(action['label'] ?? 'Action'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduler(String title, Map<String, dynamic> properties) {
    final List<dynamic> zones = properties['zones'] ?? [];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            ...zones.map<Widget>((zone) {
              return ListTile(
                title: Text(zone['name'] ?? 'Zone'),
                subtitle: Text('Max duration: ${zone['maxDuration']} min'),
                trailing: IconButton(
                  icon: const Icon(Icons.schedule),
                  onPressed: () {
                    // Show schedule dialog
                    _showScheduleDialog(zone);
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showScheduleDialog(Map<String, dynamic> zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule ${zone['name']}'),
        content: const Text('Scheduling functionality will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}