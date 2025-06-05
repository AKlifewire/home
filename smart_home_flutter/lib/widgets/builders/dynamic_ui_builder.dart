import 'package:flutter/material.dart';
import '../../core/models/ui_layout.dart';
import '../../core/models/ui_component.dart';
import 'switch_builder.dart';
import 'gauge_builder.dart';
import 'chart_builder.dart';
import 'text_builder.dart';

class DynamicUIBuilder {
  static Widget fromJson(UiLayout layout) {
    return DynamicUIContainer(layout: layout);
  }
}

class DynamicUIContainer extends StatelessWidget {
  final UiLayout layout;

  const DynamicUIContainer({Key? key, required this.layout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(layout.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: layout.components.map((component) {
              return _buildComponent(component);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildComponent(UiComponent component) {
    switch (component.type) {
      case 'switch':
        return SwitchBuilder(component: component);
      case 'gauge':
        return GaugeBuilder(component: component);
      case 'chart':
        return ChartBuilder(component: component);
      case 'text':
        return TextBuilder(component: component);
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Unknown component type: ${component.type}'),
        );
    }
  }
}