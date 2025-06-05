/// Represents a UI component in the device interface
class UiComponent {
  final String type;
  final String id;
  final String name;
  final Map<String, dynamic> properties;

  UiComponent({
    required this.type,
    required this.id,
    required this.name,
    required this.properties,
  });

  factory UiComponent.fromJson(Map<String, dynamic> json) {
    return UiComponent(
      type: json['type'] as String? ?? 'text',
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'name': name,
    'properties': properties,
  };
  
  /// Create a component from a widget definition
  factory UiComponent.fromWidget(Map<String, dynamic> widget) {
    return UiComponent(
      type: widget['type'] as String? ?? 'text',
      id: widget['id'] as String? ?? '',
      name: widget['title'] as String? ?? '',
      properties: widget['properties'] as Map<String, dynamic>? ?? {},
    );
  }
}