import 'package:flutter/material.dart';

class ActionPanelWidget extends StatelessWidget {
  final String title;
  final Map<String, dynamic> properties;
  final Function(String key, dynamic value) onAction;

  const ActionPanelWidget({
    Key? key,
    required this.title,
    required this.properties,
    required this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic> actions = properties['actions'] ?? [];
    
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
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: actions.map<Widget>((action) {
                return _buildActionButton(action);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> action) {
    final String label = action['label'] ?? 'Action';
    final String actionKey = action['key'] ?? '';
    final dynamic actionValue = action['value'];
    final String? colorString = action['color'];
    final Color? buttonColor = colorString != null 
        ? Color(int.parse(colorString.replaceAll('#', '0xFF')))
        : null;
    
    return ElevatedButton(
      onPressed: () {
        onAction(actionKey, actionValue);
      },
      style: buttonColor != null 
          ? ElevatedButton.styleFrom(backgroundColor: buttonColor)
          : null,
      child: Text(label),
    );
  }
}