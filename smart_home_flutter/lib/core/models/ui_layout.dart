import 'ui_component.dart';

/// Represents a complete UI layout for a device
class UiLayout {
  final String title;
  final String deviceId;
  final String deviceType;
  final String version;
  final String generated;
  final List<UiScreen> screens;
  final String? location;

  UiLayout({
    required this.title,
    required this.deviceId,
    required this.deviceType,
    required this.version,
    required this.generated,
    required this.screens,
    this.location,
  });

  factory UiLayout.fromJson(Map<String, dynamic> json) {
    // Handle both new format (with screens) and legacy format (with components)
    if (json.containsKey('screens')) {
      // New format
      return UiLayout(
        title: json['title'] as String? ?? 'Device',
        deviceId: json['deviceId'] as String? ?? '',
        deviceType: json['deviceType'] as String? ?? 'unknown',
        version: json['version'] as String? ?? '1.0',
        generated: json['generated'] as String? ?? DateTime.now().toIso8601String(),
        location: json['location'] as String?,
        screens: (json['screens'] as List<dynamic>?)
                ?.map((screen) => UiScreen.fromJson(screen as Map<String, dynamic>))
                .toList() ?? [],
      );
    } else {
      // Legacy format - convert to new format
      return UiLayout(
        title: json['title'] as String? ?? 'Device',
        deviceId: json['deviceId'] as String? ?? '',
        deviceType: json['deviceType'] as String? ?? 'unknown',
        version: json['version'] as String? ?? '1.0',
        generated: json['generated'] as String? ?? DateTime.now().toIso8601String(),
        location: json['location'] as String?,
        screens: [
          UiScreen(
            id: 'main',
            title: 'Main',
            widgets: (json['components'] as List<dynamic>?)
                    ?.map((component) => UiWidget.fromJson(component as Map<String, dynamic>))
                    .toList() ?? [],
          ),
        ],
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'deviceId': deviceId,
    'deviceType': deviceType,
    'version': version,
    'generated': generated,
    if (location != null) 'location': location,
    'screens': screens.map((screen) => screen.toJson()).toList(),
  };
}

/// Represents a screen in the UI layout
class UiScreen {
  final String id;
  final String title;
  final List<UiWidget> widgets;

  UiScreen({
    required this.id,
    required this.title,
    required this.widgets,
  });

  factory UiScreen.fromJson(Map<String, dynamic> json) {
    return UiScreen(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((widget) => UiWidget.fromJson(widget as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'widgets': widgets.map((widget) => widget.toJson()).toList(),
  };
}

/// Represents a widget in the UI layout
class UiWidget {
  final String type;
  final String id;
  final String title;
  final Map<String, dynamic> properties;

  UiWidget({
    required this.type,
    required this.id,
    required this.title,
    required this.properties,
  });

  factory UiWidget.fromJson(Map<String, dynamic> json) {
    // Handle legacy format conversion
    if (json.containsKey('field') && !json.containsKey('id')) {
      return UiWidget(
        type: json['type'] as String? ?? 'text',
        id: json['field'] as String? ?? '',
        title: json['label'] as String? ?? '',
        properties: {
          'field': json['field'],
          ...Map<String, dynamic>.from(json)
            ..remove('type')
            ..remove('field')
            ..remove('label'),
        },
      );
    }

    return UiWidget(
      type: json['type'] as String? ?? 'text',
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'title': title,
    'properties': properties,
  };
}