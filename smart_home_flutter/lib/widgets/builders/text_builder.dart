import 'package:flutter/material.dart';
import '../../core/models/ui_component.dart';

class TextBuilder extends StatelessWidget {
  final UiComponent component;

  const TextBuilder({Key? key, required this.component}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = component.properties['text'] as String? ?? '';
    final textStyle = component.properties['style'] as String? ?? 'normal';
    final fontSize = component.properties['fontSize'] as double? ?? 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: _getFontWeight(textStyle),
          fontStyle: _getFontStyle(textStyle),
          color: _getColor(component.properties['color']),
        ),
      ),
    );
  }

  FontWeight _getFontWeight(String style) {
    switch (style) {
      case 'bold':
      case 'boldItalic':
        return FontWeight.bold;
      default:
        return FontWeight.normal;
    }
  }

  FontStyle _getFontStyle(String style) {
    switch (style) {
      case 'italic':
      case 'boldItalic':
        return FontStyle.italic;
      default:
        return FontStyle.normal;
    }
  }

  Color? _getColor(dynamic colorValue) {
    if (colorValue == null) return null;
    
    if (colorValue is String) {
      switch (colorValue) {
        case 'red': return Colors.red;
        case 'green': return Colors.green;
        case 'blue': return Colors.blue;
        case 'black': return Colors.black;
        case 'grey': return Colors.grey;
        default: return null;
      }
    }
    
    return null;
  }
}