import 'package:flutter/material.dart';

class StatusWidget extends StatelessWidget {
  final String title;
  final dynamic value;
  final Map<String, dynamic> properties;

  const StatusWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.properties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}