import 'package:flutter/material.dart';

class ChartWidget extends StatelessWidget {
  final String title;
  final dynamic value;
  final Map<String, dynamic> properties;

  const ChartWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.properties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is a placeholder for a real chart implementation
    // In a real app, you would use a charting library like fl_chart or charts_flutter
    
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
              height: properties['height']?.toDouble() ?? 200.0,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: _buildChartPlaceholder(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    // If we have data, show a simple representation
    if (value is List && value.isNotEmpty) {
      return CustomPaint(
        painter: SimpleChartPainter(data: List<double>.from(value)),
      );
    }
    
    // Otherwise show a placeholder
    return const Center(
      child: Text('Chart will display data when available'),
    );
  }
}

class SimpleChartPainter extends CustomPainter {
  final List<double> data;
  
  SimpleChartPainter({required this.data});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    
    // Find min and max values for scaling
    final double minValue = data.reduce((a, b) => a < b ? a : b);
    final double maxValue = data.reduce((a, b) => a > b ? a : b);
    final double range = maxValue - minValue;
    
    // Start path at first point
    final double stepX = size.width / (data.length - 1);
    double x = 0;
    double y = size.height - ((data[0] - minValue) / range * size.height);
    path.moveTo(x, y);
    
    // Add points to path
    for (int i = 1; i < data.length; i++) {
      x = i * stepX;
      y = size.height - ((data[i] - minValue) / range * size.height);
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}