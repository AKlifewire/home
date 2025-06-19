import 'package:flutter/material.dart';

/// Represents a UI component from the dynamic layout JSON
class UiComponent {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> binding;
  final Map<String, dynamic> styling;

  UiComponent({
    required this.id,
    required this.type,
    required this.title,
    required this.properties,
    required this.binding,
    this.styling = const {},
  });

  factory UiComponent.fromJson(Map<String, dynamic> json) {
    return UiComponent(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      binding: Map<String, dynamic>.from(json['binding'] ?? {}),
      styling: Map<String, dynamic>.from(json['styling'] ?? {}),
    );
  }

  /// Get the bound value from device state
  dynamic getValueFromDeviceState(Map<String, dynamic> deviceState) {
    if (binding.containsKey('key')) {
      final String key = binding['key'];
      return deviceState[key];
    }
    return null;
  }
}

/// Factory for creating UI components from JSON
class UiComponentFactory {
  static List<UiComponent> createFromLayout(Map<String, dynamic> layout) {
    final List<dynamic> widgets = layout['widgets'] ?? [];
    return widgets.map((widget) => UiComponent.fromJson(widget)).toList();
  }
}