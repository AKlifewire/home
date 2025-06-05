class DeviceCommand {
  final String deviceId;
  final String componentId;
  final String command;
  final Map<String, dynamic> parameters;

  DeviceCommand({
    required this.deviceId,
    required this.componentId,
    required this.command,
    required this.parameters,
  });

  factory DeviceCommand.fromJson(Map<String, dynamic> json) {
    return DeviceCommand(
      deviceId: json['deviceId'] as String,
      componentId: json['componentId'] as String,
      command: json['command'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'componentId': componentId,
    'command': command,
    'parameters': parameters,
  };
}