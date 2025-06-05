import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'logger.dart';

/// A device simulator for testing the smart home platform
class DeviceSimulator {
  final String deviceId;
  final String deviceType;
  final List<DeviceComponent> components;
  final String? location;
  
  MqttServerClient? _mqttClient;
  bool _connected = false;
  final _log = getLogger('DeviceSimulator');
  
  Timer? _heartbeatTimer;
  final Map<String, Timer> _componentTimers = {};
  
  DeviceSimulator({
    required this.deviceId,
    required this.deviceType,
    required this.components,
    this.location,
  });
  
  /// Factory method to create common device types
  factory DeviceSimulator.create(String type, String id, {String? location}) {
    switch (type) {
      case 'relay':
        return DeviceSimulator(
          deviceId: id,
          deviceType: 'relay',
          location: location,
          components: [
            DeviceComponent(
              type: 'toggle',
              field: 'relay1',
              label: 'Relay 1',
            ),
            DeviceComponent(
              type: 'toggle',
              field: 'relay2',
              label: 'Relay 2',
            ),
          ],
        );
        
      case 'sensor':
        return DeviceSimulator(
          deviceId: id,
          deviceType: 'sensor',
          location: location,
          components: [
            DeviceComponent(
              type: 'temperature',
              field: 'temperature',
              label: 'Temperature',
              unit: '°C',
              min: 0,
              max: 50,
              simulateValue: () => 20 + (Random().nextDouble() * 5),
            ),
            DeviceComponent(
              type: 'humidity',
              field: 'humidity',
              label: 'Humidity',
              unit: '%',
              min: 0,
              max: 100,
              simulateValue: () => 40 + (Random().nextDouble() * 20),
            ),
          ],
        );
        
      case 'thermostat':
        return DeviceSimulator(
          deviceId: id,
          deviceType: 'thermostat',
          location: location,
          components: [
            DeviceComponent(
              type: 'temperature',
              field: 'temperature',
              label: 'Current Temperature',
              unit: '°C',
              min: 0,
              max: 50,
              simulateValue: () => 20 + (Random().nextDouble() * 5),
            ),
            DeviceComponent(
              type: 'temperature',
              field: 'setpoint',
              label: 'Target Temperature',
              unit: '°C',
              min: 10,
              max: 30,
              value: 22,
            ),
            DeviceComponent(
              type: 'toggle',
              field: 'heating',
              label: 'Heating',
              value: false,
            ),
          ],
        );
        
      default:
        return DeviceSimulator(
          deviceId: id,
          deviceType: 'generic',
          location: location,
          components: [
            DeviceComponent(
              type: 'text',
              field: 'status',
              label: 'Status',
              value: 'Online',
            ),
          ],
        );
    }
  }
  
  /// Connect to MQTT broker
  Future<bool> connect({
    required String host,
    required int port,
    String? username,
    String? password,
    bool useWebSocket = false,
  }) async {
    try {
      _mqttClient = MqttServerClient(host, deviceId)
        ..port = port
        ..logging(on: false)
        ..keepAlivePeriod = 60
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..secure = true;

      if (useWebSocket) {
        _mqttClient!.useWebSocket = true;
        _mqttClient!.websocketProtocols = ['mqtt'];
      }

      if (username != null) {
        _mqttClient!.connectionMessage = MqttConnectMessage()
          ..authenticateAs(username, password)
          ..withClientIdentifier(deviceId)
          ..withWillQos(MqttQos.atLeastOnce)
          ..withWillRetain(false)
          ..startClean();
      }

      await _mqttClient!.connect();
      return _connected;
    } catch (e) {
      _log.severe('Failed to connect to MQTT broker: $e');
      return false;
    }
  }
  
  /// Start device simulation
  void start() {
    if (!_connected) {
      _log.warning('Device not connected to MQTT broker');
      return;
    }
    
    // Publish device config
    _publishDeviceConfig();
    
    // Start heartbeat
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _publishConnectionStatus('online');
    });
    
    // Subscribe to command topics
    _subscribeToCommands();
    
    // Start component simulations
    for (final component in components) {
      if (component.simulateValue != null) {
        // Publish initial value
        _publishComponentValue(component);
        
        // Set up periodic updates
        _componentTimers[component.field] = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _publishComponentValue(component),
        );
      } else {
        // Just publish the static value
        _publishComponentValue(component);
      }
    }
  }
  
  /// Stop device simulation
  void stop() {
    // Stop all timers
    _heartbeatTimer?.cancel();
    for (final timer in _componentTimers.values) {
      timer.cancel();
    }
    _componentTimers.clear();
    
    // Publish offline status
    _publishConnectionStatus('offline');
    
    // Disconnect
    _mqttClient?.disconnect();
  }
  
  /// Publish device configuration
  void _publishDeviceConfig() {
    final config = {
      'deviceId': deviceId,
      'type': deviceType,
      'name': '$deviceType-$deviceId',
      'location': location,
      'components': components.map((c) => c.toJson()).toList(),
    };
    
    _publish('devices/$deviceId/config', jsonEncode(config));
    _log.info('Published device config for $deviceId');
  }
  
  /// Publish connection status
  void _publishConnectionStatus(String status) {
    final data = {
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _publish('devices/$deviceId/connection', jsonEncode(data));
  }
  
  /// Publish component value
  void _publishComponentValue(DeviceComponent component) {
    // Get current value (simulated or static)
    final value = component.simulateValue != null
        ? component.simulateValue!()
        : component.value;
    
    final data = {
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (component.unit != null) {
      data['unit'] = component.unit;
    }
    
    _publish(
      'devices/$deviceId/components/${component.field}/status',
      jsonEncode(data),
    );
  }
  
  /// Subscribe to command topics
  void _subscribeToCommands() {
    _mqttClient!.subscribe(
      'devices/$deviceId/components/+/set',
      MqttQos.atLeastOnce,
    );
    
    _mqttClient!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var msg in messages) {
        final topic = msg.topic;
        final recMess = msg.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        
        _log.info('Received command: $topic - $payload');
        
        // Parse topic to get component field
        // Format: devices/{deviceId}/components/{field}/set
        final parts = topic.split('/');
        if (parts.length >= 5 && parts[4] == 'set') {
          final field = parts[3];
          _handleCommand(field, payload);
        }
      }
    });
  }
  
  /// Handle incoming command
  void _handleCommand(String field, String payload) {
    // Find the component
    final component = components.firstWhere(
      (c) => c.field == field,
      orElse: () => throw Exception('Component not found: $field'),
    );
    
    // Parse command
    dynamic value;
    try {
      final data = jsonDecode(payload);
      value = data['value'];
    } catch (e) {
      // Simple payload
      value = payload;
    }
    
    // Update component value
    if (value == 'on' || value == 'true' || value == '1') {
      component.value = true;
    } else if (value == 'off' || value == 'false' || value == '0') {
      component.value = false;
    } else {
      component.value = value;
    }
    
    // Publish updated value
    _publishComponentValue(component);
    
    _log.info('Updated component $field to ${component.value}');
  }
  
  /// Publish message to topic
  void _publish(String topic, String message) {
    if (!_connected || _mqttClient == null) {
      _log.warning('Cannot publish, not connected');
      return;
    }
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    
    _mqttClient!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }
  
  void _onConnected() {
    _log.info('Connected to MQTT broker');
    _connected = true;
    _publishConnectionStatus('online');
  }
  
  void _onDisconnected() {
    _log.info('Disconnected from MQTT broker');
    _connected = false;
    
    // Stop all timers
    _heartbeatTimer?.cancel();
    for (final timer in _componentTimers.values) {
      timer.cancel();
    }
    _componentTimers.clear();
  }
}

/// Represents a component of a device
class DeviceComponent {
  final String type;
  final String field;
  final String label;
  final String? unit;
  final double? min;
  final double? max;
  dynamic value;
  final double Function()? simulateValue;
  
  DeviceComponent({
    required this.type,
    required this.field,
    required this.label,
    this.unit,
    this.min,
    this.max,
    this.value,
    this.simulateValue,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'field': field,
      'label': label,
      if (unit != null) 'unit': unit,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
    };
  }
}