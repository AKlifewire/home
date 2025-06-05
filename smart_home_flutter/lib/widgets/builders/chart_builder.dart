import 'package:flutter/material.dart';
import '../../core/models/ui_layout.dart';

class ChartBuilder extends StatelessWidget {
  final UiComponent component;

  const ChartBuilder({Key? key, required this.component}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chartType = component.properties['chartType'] as String? ?? 'line';
    final data = component.properties['data'] as List<dynamic>? ?? [];

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
          SizedBox(
            height: 200,
            child: _buildMockChart(chartType, data),
          ),
        ],
      ),
    );
  }

  Widget _buildMockChart(String chartType, List<dynamic> data) {
    // Simple mock chart implementation
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chart Type: $chartType'),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                data.length,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: (data[i] as num).toDouble() * 1.5,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Time →'),
        ],
      ),
    );
  }
}