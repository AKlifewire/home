import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/ui_component.dart';
import '../../core/services/device_control_mock.dart';

class SwitchBuilder extends ConsumerStatefulWidget {
  final UiComponent component;

  const SwitchBuilder({Key? key, required this.component}) : super(key: key);

  @override
  ConsumerState<SwitchBuilder> createState() => _SwitchBuilderState();
}

class _SwitchBuilderState extends ConsumerState<SwitchBuilder> {
  bool _value = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    if (widget.component.properties.containsKey('initialValue')) {
      setState(() {
        _value = widget.component.properties['initialValue'] as bool;
      });
    }
  }

  Future<void> _toggleSwitch(bool newValue) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceControlService = ref.read(deviceControlServiceProvider);
      final deviceId = widget.component.properties['deviceId'] as String;
      final componentId = widget.component.id;

      final success = await deviceControlService.controlDevice(
        deviceId: deviceId,
        componentId: componentId,
        command: 'setState',
        parameters: {'state': newValue},
      );

      if (success) {
        setState(() {
          _value = newValue;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to control device: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.component.name,
            style: const TextStyle(fontSize: 16),
          ),
          _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: _value,
                  onChanged: _toggleSwitch,
                ),
        ],
      ),
    );
  }
}