import 'package:flutter/material.dart';
import '../../core/models/ui_component.dart';
import '../../core/services/device_control_service.dart';
import 'toggle_builder.dart';
import 'gauge_builder.dart';
import 'chart_builder.dart';
import 'text_builder.dart';

/// A factory class that creates widgets based on UI component definitions
class SmartDeviceWidgetFactory {
  final DeviceControlService _controlService;

  SmartDeviceWidgetFactory(this._controlService);

  /// Create a widget from a UI component definition
  Widget createWidget(UiComponent component) {
    switch (component.type) {
      case 'toggle':
        return ToggleBuilder(
          component: component,
          controlService: _controlService,
        );
      case 'gauge':
        return GaugeBuilder(component: component);
      case 'chart':
        return ChartBuilder(component: component);
      case 'status':
        return StatusIndicator(component: component);
      case 'video':
        return VideoPlayer(component: component);
      case 'climate':
        return ClimateControl(
          component: component,
          controlService: _controlService,
        );
      case 'lock':
        return LockControl(
          component: component,
          controlService: _controlService,
        );
      case 'alert':
        return AlertWidget(component: component);
      case 'button':
        return ActionButton(
          component: component,
          controlService: _controlService,
        );
      case 'slider':
        return SliderControl(
          component: component,
          controlService: _controlService,
        );
      case 'text':
      default:
        return TextBuilder(component: component);
    }
  }
}

/// Status indicator widget
class StatusIndicator extends StatelessWidget {
  final UiComponent component;

  const StatusIndicator({Key? key, required this.component}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This would be connected to real-time status updates via MQTT
    // For now, we'll use a placeholder
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              component.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Online'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Video player widget
class VideoPlayer extends StatelessWidget {
  final UiComponent component;

  const VideoPlayer({Key? key, required this.component}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final streamUrl = component.properties['streamUrl'] as String? ?? '';
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              component.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: streamUrl.isNotEmpty
                  ? Text('Video stream would load from: $streamUrl')
                  : const Text('No video stream available',
                      style: TextStyle(color: Colors.white)),
            ),
          ),
          ButtonBar(
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('SNAPSHOT'),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('FULLSCREEN'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Climate control widget
class ClimateControl extends StatefulWidget {
  final UiComponent component;
  final DeviceControlService controlService;

  const ClimateControl({
    Key? key,
    required this.component,
    required this.controlService,
  }) : super(key: key);

  @override
  State<ClimateControl> createState() => _ClimateControlState();
}

class _ClimateControlState extends State<ClimateControl> {
  double _temperature = 21.0;

  @override
  void initState() {
    super.initState();
    // Initialize from component properties if available
    _temperature = widget.component.properties['temperature'] as double? ?? 21.0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.component.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${_temperature.toStringAsFixed(1)}°C',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Slider(
              value: _temperature,
              min: 16,
              max: 30,
              divisions: 28,
              label: '${_temperature.toStringAsFixed(1)}°C',
              onChanged: (value) {
                setState(() {
                  _temperature = value;
                });
              },
              onChangeEnd: (value) {
                // Send command to device
                widget.controlService.sendCommand(
                  widget.component.id,
                  {
                    'command': 'setTemperature',
                    'value': value,
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _modeButton('Heat', Icons.whatshot),
                _modeButton('Cool', Icons.ac_unit),
                _modeButton('Fan', Icons.air),
                _modeButton('Auto', Icons.auto_mode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String mode, IconData icon) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: () {
            // Send command to device
            widget.controlService.sendCommand(
              widget.component.id,
              {
                'command': 'setMode',
                'value': mode.toLowerCase(),
              },
            );
          },
        ),
        Text(mode),
      ],
    );
  }
}

/// Lock control widget
class LockControl extends StatelessWidget {
  final UiComponent component;
  final DeviceControlService controlService;

  const LockControl({
    Key? key,
    required this.component,
    required this.controlService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This would be connected to real-time status updates via MQTT
    final bool isLocked = component.properties['locked'] as bool? ?? true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              component.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    size: 48,
                    color: isLocked ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLocked ? 'Locked' : 'Unlocked',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Send command to device
                  controlService.sendCommand(
                    component.id,
                    {
                      'command': isLocked ? 'unlock' : 'lock',
                    },
                  );
                },
                child: Text(isLocked ? 'Unlock' : 'Lock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alert widget
class AlertWidget extends StatelessWidget {
  final UiComponent component;

  const AlertWidget({Key? key, required this.component}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isActive = component.properties['active'] as bool? ?? false;
    final String message = component.properties['message'] as String? ?? 'Alert';

    return Card(
      color: isActive ? Colors.red.shade100 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isActive)
                  const Icon(Icons.warning_amber, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  component.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isActive ? Colors.red : null,
                      ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }
}

/// Action button widget
class ActionButton extends StatelessWidget {
  final UiComponent component;
  final DeviceControlService controlService;

  const ActionButton({
    Key? key,
    required this.component,
    required this.controlService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              component.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Get payload from component properties
                  final payload = component.properties['payload'] ?? {};
                  
                  // Send command to device
                  controlService.sendCommand(component.id, payload);
                },
                child: Text(component.properties['buttonText'] as String? ?? 'Execute'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slider control widget
class SliderControl extends StatefulWidget {
  final UiComponent component;
  final DeviceControlService controlService;

  const SliderControl({
    Key? key,
    required this.component,
    required this.controlService,
  }) : super(key: key);

  @override
  State<SliderControl> createState() => _SliderControlState();
}

class _SliderControlState extends State<SliderControl> {
  late double _value;
  late double _min;
  late double _max;
  late int _divisions;
  late String _unit;

  @override
  void initState() {
    super.initState();
    // Initialize from component properties
    _value = widget.component.properties['value'] as double? ?? 0.0;
    _min = widget.component.properties['min'] as double? ?? 0.0;
    _max = widget.component.properties['max'] as double? ?? 100.0;
    _divisions = widget.component.properties['divisions'] as int? ?? 100;
    _unit = widget.component.properties['unit'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.component.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${_value.toStringAsFixed(1)}$_unit'),
                Expanded(
                  child: Slider(
                    value: _value,
                    min: _min,
                    max: _max,
                    divisions: _divisions,
                    label: '${_value.toStringAsFixed(1)}$_unit',
                    onChanged: (value) {
                      setState(() {
                        _value = value;
                      });
                    },
                    onChangeEnd: (value) {
                      // Send command to device
                      widget.controlService.sendCommand(
                        widget.component.id,
                        {
                          'command': 'setValue',
                          'value': value,
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}