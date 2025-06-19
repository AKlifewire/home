import 'package:flutter/material.dart';

class SliderWidget extends StatefulWidget {
  final String title;
  final dynamic value;
  final Map<String, dynamic> binding;
  final Map<String, dynamic> properties;
  final Function(String key, dynamic value) onChanged;

  const SliderWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.binding,
    required this.properties,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value?.toDouble() ?? widget.properties['min']?.toDouble() ?? 0.0;
  }

  @override
  void didUpdateWidget(SliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != _currentValue) {
      setState(() {
        _currentValue = widget.value.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double min = widget.properties['min']?.toDouble() ?? 0.0;
    final double max = widget.properties['max']?.toDouble() ?? 100.0;
    final int divisions = widget.properties['divisions'] ?? 100;
    final String unit = widget.properties['unit'] ?? '';
    final String bindingKey = widget.binding['key'] ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
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
                    value: _currentValue,
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: '$_currentValue $unit',
                    onChanged: (newValue) {
                      setState(() {
                        _currentValue = newValue;
                      });
                    },
                    onChangeEnd: (newValue) {
                      widget.onChanged(bindingKey, newValue);
                    },
                  ),
                ),
                Text('$max'),
              ],
            ),
            Center(
              child: Text(
                '$_currentValue $unit',
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
}