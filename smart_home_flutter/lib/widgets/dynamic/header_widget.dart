import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final String title;
  final Map<String, dynamic> properties;

  const HeaderWidget({
    Key? key,
    required this.title,
    required this.properties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  ? Color(int.parse(properties['color'].toString().replaceAll('#', '0xFF')))
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
}