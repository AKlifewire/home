import 'package:flutter/material.dart';

class SwitchWidget extends StatelessWidget {
  final String title;
  final dynamic value;
  final Map<String, dynamic> binding;
  final Map<String, dynamic> properties;
  final Function(String key, dynamic value) onChanged;

  const SwitchWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.binding,
    required this.properties,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isOn = value == true;
    final String bindingKey = binding['key'] ?? '';
    
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
            Switch(
              value: isOn,
              onChanged: (newValue) {
                onChanged(bindingKey, newValue);
              },
            ),
          ],
        ),
      ),
    );
  }
}