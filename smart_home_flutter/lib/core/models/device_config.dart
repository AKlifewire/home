class DeviceConfig {
  final String deviceId;
  final String deviceType;
  final List<DeviceComponent> components;
  final DeviceMetadata metadata;

  DeviceConfig({
    required this.deviceId,
    required this.deviceType,
    required this.components,
    required this.metadata,
  });

  factory DeviceConfig.fromJson(Map<String, dynamic> json) {
    return DeviceConfig(
      deviceId: json['deviceId'] as String,
      deviceType: json['deviceType'] as String,
      components: (json['components'] as List)
          .map((component) => DeviceComponent.fromJson(component))
          .toList(),
      metadata: DeviceMetadata.fromJson(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceType': deviceType,
    'components': components.map((component) => component.toJson()).toList(),
    'metadata': metadata.toJson(),
  };
}

class DeviceComponent {
  final String type;
  final String id;
  final String name;
  final List<String> capabilities;
  final Map<String, dynamic> config;

  DeviceComponent({
    required this.type,
    required this.id,
    required this.name,
    required this.capabilities,
    required this.config,
  });

  factory DeviceComponent.fromJson(Map<String, dynamic> json) {
    return DeviceComponent(
      type: json['type'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
      capabilities: (json['capabilities'] as List).cast<String>(),
      config: json['config'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'name': name,
    'capabilities': capabilities,
    'config': config,
  };
}

class DeviceMetadata {
  final String name;
  final String location;
  final String manufacturer;
  final String model;
  final String version;

  DeviceMetadata({
    required this.name,
    required this.location,
    required this.manufacturer,
    required this.model,
    required this.version,
  });

  factory DeviceMetadata.fromJson(Map<String, dynamic> json) {
    return DeviceMetadata(
      name: json['name'] as String,
      location: json['location'] as String,
      manufacturer: json['manufacturer'] as String,
      model: json['model'] as String,
      version: json['version'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'manufacturer': manufacturer,
    'model': model,
    'version': version,
  };
}