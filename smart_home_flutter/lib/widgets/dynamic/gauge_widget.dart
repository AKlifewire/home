import 'package:flutter/material.dart';

class GaugeWidget extends StatelessWidget {
  final String title;
  final dynamic value;
  final Map<String, dynamic> properties;

  const GaugeWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.properties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double min = properties['min']?.toDouble() ?? 0.0;
    final double max = properties['max']?.toDouble() ?? 100.0;
    final String unit = properties['unit'] ?? '';
    final double currentValue = value?.toDouble() ?? min;
    final double progress = (currentValue - min) / (max - min);
    
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
              value: progress.clamp(0.0, 1.0),
              minHeight: 20,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress),
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$min $unit'),
                Text(
                  '$currentValue $unit',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('$max $unit'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (properties.containsKey('colorMap')) {
      final Map<String, dynamic> colorMap = properties['colorMap'];
      
      // Find the appropriate color based on progress
      if (progress < 0.3 && colorMap.containsKey('low')) {
        return _parseColor(colorMap['low']);
      } else if (progress > 0.7 && colorMap.containsKey('high')) {
        return _parseColor(colorMap['high']);
      } else if (colorMap.containsKey('medium')) {
        return _parseColor(colorMap['medium']);
      }
    }
    
    // Default color logic based on progress
    if (progress < 0.3) {
      return Colors.green;
    } else if (progress > 0.7) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}