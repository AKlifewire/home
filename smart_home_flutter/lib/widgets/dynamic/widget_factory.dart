import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import 'gauge_widget.dart';
import 'switch_widget.dart';
import 'chart_widget.dart';
import 'status_widget.dart';
import 'scheduler_widget.dart';
import 'header_widget.dart';
import 'action_panel_widget.dart';

abstract class DynamicWidget extends StatefulWidget {
  final DeviceComponent component;
  final Function(String action, Map<String, dynamic> data)? onAction;

  const DynamicWidget({
    Key? key,
    required this.component,
    this.onAction,
  }) : super(key: key);
}

class WidgetFactory {
  static final Map<
          String,
          Widget Function(
              DeviceComponent, Function(String, Map<String, dynamic>)?)>
      _widgets = {};

  static void registerWidget(
      String type,
      Widget Function(DeviceComponent, Function(String, Map<String, dynamic>)?)
          builder) {
    _widgets[type] = builder;
  }

  static Widget? createWidget(DeviceComponent component,
      Function(String, Map<String, dynamic>)? onAction) {
    final builder = _widgets[component.type];
    if (builder == null) return null;
    return builder(component, onAction);
  }

  static void initializeDefaultWidgets() {
    // Register all default widget types
    _widgets.addAll({
      'gauge': (component, onAction) =>
          GaugeWidget(component: component, onAction: onAction),
      'switch': (component, onAction) =>
          SwitchWidget(component: component, onAction: onAction),
      'chart': (component, onAction) =>
          ChartWidget(component: component, onAction: onAction),
      'status': (component, onAction) =>
          StatusWidget(component: component, onAction: onAction),
      'scheduler': (component, onAction) =>
          SchedulerWidget(component: component, onAction: onAction),
      'header': (component, onAction) =>
          HeaderWidget(component: component, onAction: onAction),
      'actionPanel': (component, onAction) =>
          ActionPanelWidget(component: component, onAction: onAction),
    });
  }
}
