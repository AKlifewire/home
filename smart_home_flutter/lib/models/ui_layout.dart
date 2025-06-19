class UiLayout {
  final String id;
  final String deviceId;
  final String deviceType;
  final Map<String, dynamic> layout;

  UiLayout({
    required this.id,
    required this.deviceId,
    required this.deviceType,
    required this.layout,
  });

  factory UiLayout.fromJson(Map<String, dynamic> json) {
    return UiLayout(
      id: json['id'],
      deviceId: json['deviceId'],
      deviceType: json['deviceType'],
      layout: Map<String, dynamic>.from(json['layout']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceType': deviceType,
      'layout': layout,
    };
  }
}

class WidgetConfig {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> binding;
  final Map<String, dynamic> styling;

  WidgetConfig({
    required this.id,
    required this.type,
    required this.title,
    required this.properties,
    required this.binding,
    this.styling = const {},
  });

  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      binding: Map<String, dynamic>.from(json['binding'] ?? {}),
      styling: Map<String, dynamic>.from(json['styling'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'properties': properties,
      'binding': binding,
      'styling': styling,
    };
  }
}