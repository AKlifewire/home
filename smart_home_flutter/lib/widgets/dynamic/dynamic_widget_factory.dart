import 'package:flutter/material.dart';
import '../../models/ui_component.dart';
import 'header_widget.dart';
import 'slider_widget.dart';
import 'switch_widget.dart';
import 'chart_widget.dart';
import 'status_widget.dart';
import 'gauge_widget.dart';
import 'action_panel_widget.dart';
import 'input_widget.dart';
import 'scheduler_widget.dart';

/// Factory class that creates Flutter widgets based on UI component definitions
class DynamicWidgetFactory {
  /// Creates a Flutter widget based on the UI component type
  static Widget createWidget({
    required UiComponent component,
    required Map<String, dynamic> deviceState,
    required Function(String key, dynamic value) onControlValueChanged,
  }) {
    final String type = component.type;
    final String title = component.title;
    final Map<String, dynamic> properties = component.properties;
    final Map<String, dynamic> binding = component.binding;
    final dynamic value = component.getValueFromDeviceState(deviceState);

    switch (type) {
      case 'header':
        return HeaderWidget(
          title: title,
          properties: properties,
        );
      case 'gauge':
        return GaugeWidget(
          title: title,
          value: value,
          properties: properties,
        );
      case 'toggle':
      case 'switch':
        return SwitchWidget(
          title: title,
          value: value,
          binding: binding,
          properties: properties,
          onChanged: onControlValueChanged,
        );
      case 'slider':
        return SliderWidget(
          title: title,
          value: value,
          binding: binding,
          properties: properties,
          onChanged: onControlValueChanged,
        );
      case 'input':
        return InputWidget(
          title: title,
          value: value,
          binding: binding,
          properties: properties,
          onChanged: onControlValueChanged,
        );
      case 'chart':
        return ChartWidget(
          title: title,
          value: value,
          properties: properties,
        );
      case 'status':
        return StatusWidget(
          title: title,
          value: value,
          properties: properties,
        );
      case 'actionPanel':
        return ActionPanelWidget(
          title: title,
          properties: properties,
          onAction: onControlValueChanged,
        );
      case 'scheduler':
        return SchedulerWidget(
          title: title,
          properties: properties,
          onScheduleSet: (schedule) => onControlValueChanged('schedule', schedule),
        );
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Unsupported widget type: $type'),
        );
    }
  }
}