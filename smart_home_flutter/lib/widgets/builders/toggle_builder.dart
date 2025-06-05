import 'package:flutter/material.dart';
import '../../core/models/ui_component.dart';
import '../../core/services/device_control_service.dart';

class ToggleBuilder extends StatefulWidget {
  final UiComponent component;
  final String deviceId;
  final DeviceControlService deviceControlService;

  const ToggleBuilder({
    Key? key,
    required this.component,
    required this.deviceId,
    required this.deviceControlService,
  }) : super(key: key);

  @override
  State<ToggleBuilder> createState() => _ToggleBuilderState();
}

class _ToggleBuilderState extends State<ToggleBuilder> {
  bool _value = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialState();
  }

  Future<void> _fetchInitialState() async {
    try {
      final state = await widget.deviceControlService.getDeviceState(
        widget.deviceId,
        widget.component.field ?? '',
      );
      
      setState(() {
        _value = state == true || state == 'true' || state == 1 || state == '1';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleState(bool newValue) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare payload based on component configuration
      final payload = widget.component.payload != null 
          ? Map<String, dynamic>.from(widget.component.payload!)
          : {'command': 'toggle', 'value': newValue};
      
      // Add the new value to the payload if not already included
      if (!payload.containsKey('value')) {
        payload['value'] = newValue;
      }
      
      // Send command to device
      await widget.deviceControlService.sendCommand(
        widget.deviceId,
        widget.component.field ?? '',
        payload,
        topic: widget.component.topic,
      );
      
      setState(() {
        _value = newValue;
        _isLoading = false;
      });
    } catch (e) {
      // Revert to previous state on error
      setState(() {
        _isLoading = false;
      });
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to control device: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.component.label ?? 'Toggle',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: _value,
                onChanged: _toggleState,
              ),
          ],
        ),
      ),
    );
  }
}