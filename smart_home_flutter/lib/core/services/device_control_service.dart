import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mqtt_service.dart';

final deviceControlServiceProvider = Provider((ref) => DeviceControlService(ref));

/// Service for controlling devices via MQTT
class DeviceControlService {
  final Ref _ref;
  
  DeviceControlService(this._ref);
  
  /// Send a command to a device
  Future<void> sendCommand(String componentId, Map<String, dynamic> payload) async {
    final mqttService = _ref.read(mqttServiceProvider);
    
    // Extract device ID from component ID (format: deviceId/componentId)
    final parts = componentId.split('/');
    final deviceId = parts.isNotEmpty ? parts[0] : componentId;
    
    // Create command topic
    final topic = 'device/$deviceId/control';
    
    // Add component ID to payload if not already present
    if (!payload.containsKey('componentId') && parts.length > 1) {
      payload['componentId'] = parts[1];
    }
    
    // Add timestamp
    payload['timestamp'] = DateTime.now().toIso8601String();
    
    // Convert payload to JSON
    final jsonPayload = jsonEncode(payload);
    
    // Send command via MQTT
    await mqttService.publishMessage(topic, jsonPayload);
    
    // Log command
    print('Sent command to $topic: $jsonPayload');
  }
  
  /// Toggle a device on/off
  Future<void> toggleDevice(String deviceId, String componentId, bool value) async {
    await sendCommand('$deviceId/$componentId', {
      'command': 'set',
      'value': value,
    });
  }
  
  /// Set a device value
  Future<void> setValue(String deviceId, String componentId, dynamic value) async {
    await sendCommand('$deviceId/$componentId', {
      'command': 'setValue',
      'value': value,
    });
  }
  
  /// Send a custom command
  Future<void> sendCustomCommand(
    String deviceId, 
    String componentId, 
    String command, 
    Map<String, dynamic> parameters
  ) async {
    await sendCommand('$deviceId/$componentId', {
      'command': command,
      ...parameters,
    });
  }
}