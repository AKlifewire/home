import 'package:flutter/material.dart';
import '../../core/models/ui_layout.dart';

class GaugeBuilder extends StatelessWidget {
  final UiComponent component;

  const GaugeBuilder({Key? key, required this.component}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = component.properties['value'] as double? ?? 0.0;
    final min = component.properties['min'] as double? ?? 0.0;
    final max = component.properties['max'] as double? ?? 100.0;
    final unit = component.properties['unit'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            component.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSimpleGauge(value, min, max, unit),
        ],
      ),
    );
  }

  Widget _buildSimpleGauge(double value, double min, double max, String unit) {
    // Calculate percentage for the gauge
    final percentage = ((value - min) / (max - min)).clamp(0.0, 1.0);
    
    return SizedBox(
      height: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 20,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.yellow, Colors.red],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$min $unit'),
              Text('$max $unit'),
            ],
          ),
        ],
      ),
    );
  }
}