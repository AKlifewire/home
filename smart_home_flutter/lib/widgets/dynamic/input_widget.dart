import 'package:flutter/material.dart';

class InputWidget extends StatefulWidget {
  final String title;
  final dynamic value;
  final Map<String, dynamic> binding;
  final Map<String, dynamic> properties;
  final Function(String key, dynamic value) onChanged;

  const InputWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.binding,
    required this.properties,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(InputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value.toString() != _controller.text) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String bindingKey = widget.binding['key'] ?? '';
    final String hint = widget.properties['hint'] ?? 'Enter value';
    final String label = widget.properties['label'] ?? widget.title;
    final bool isNumeric = widget.properties['numeric'] == true;
    final bool isPassword = widget.properties['isPassword'] == true;
    
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
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
              keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
              obscureText: isPassword,
              onSubmitted: (value) {
                // Convert to number if numeric
                final dynamic finalValue = isNumeric ? double.tryParse(value) ?? value : value;
                widget.onChanged(bindingKey, finalValue);
              },
            ),
          ],
        ),
      ),
    );
  }
}