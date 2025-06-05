import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home_flutter/core/services/mqtt_service.dart';
import 'package:smart_home_flutter/core/services/device_control_service.dart';
import 'package:smart_home_flutter/core/services/device_ui_service.dart';

/// Helper class for running integration tests
class TestRunner {
  /// Load test configuration from file
  static Future<String> loadTestConfig(String filename) async {
    return await rootBundle.loadString('integration_test/test_configs/$filename');
  }
  
  /// Initialize app with mock services for testing
  static Future<void> initializeAppWithMocks() async {
    // Create container with overrides for testing
    final container = ProviderContainer(
      overrides: [
        mqttServiceProvider.overrideWithValue(MockMqttService()),
        deviceControlServiceProvider.overrideWithValue(
          DeviceControlService(ProviderRef(container, mqttServiceProvider))
        ),
        deviceUiServiceProvider.overrideWithValue(MockDeviceUIService()),
      ],
    );
    
    // Initialize mock services
    await (container.read(mqttServiceProvider) as MockMqttService).initialize();
  }
  
  /// Load test device configuration
  static Future<Map<String, dynamic>> loadTestDevice(String deviceId) async {
    // Find test config file for device
    final filename = '$deviceId.json';
    try {
      final configJson = await loadTestConfig(filename);
      return jsonDecode(configJson);
    } catch (e) {
      // Try default test config
      final configJson = await loadTestConfig('test-relay.json');
      return jsonDecode(configJson);
    }
  }
  
  /// Send mock command to device
  static Future<CommandResult> sendMockCommand(
    String deviceId, 
    String componentId, 
    Map<String, dynamic> payload
  ) async {
    // Get mock MQTT service
    final mqttService = MockMqttService();
    
    // Create topic
    final topic = 'device/$deviceId/control';
    
    // Add component ID to payload
    payload['componentId'] = componentId;
    
    // Add timestamp
    payload['timestamp'] = DateTime.now().toISOString();
    
    // Convert payload to JSON
    final jsonPayload = jsonEncode(payload);
    
    // Send command via mock MQTT
    await mqttService.publishMessage(topic, jsonPayload);
    
    // Return success
    return CommandResult(
      success: true,
      topic: topic,
      payload: payload,
    );
  }
  
  /// Get device state from mock MQTT
  static Future<Map<String, dynamic>> getDeviceState(String deviceId) async {
    // Get mock MQTT service
    final mqttService = MockMqttService();
    
    // Get device state
    return mqttService.getDeviceState(deviceId);
  }
}

/// Mock MQTT service for testing
class MockMqttService implements EnhancedMqttService {
  bool _isConnected = false;
  final Map<String, Map<String, dynamic>> _deviceStates = {};
  
  @override
  Future<void> initialize({
    String? host,
    int port = 8883,
    String? clientId,
    bool useTls = true,
  }) async {
    _isConnected = true;
    
    // Initialize with some test devices
    _deviceStates['test-relay-01'] = {
      'relay1': false,
      'relay2': false,
      'status': 'online',
    };
    
    _deviceStates['test-sensor-01'] = {
      'temperature': 22.5,
      'humidity': 45.0,
      'status': 'online',
    };
  }
  
  @override
  Future<bool> connect() async {
    _isConnected = true;
    return _isConnected;
  }
  
  @override
  Future<void> disconnect() async {
    _isConnected = false;
  }
  
  @override
  Stream<Map<String, dynamic>> subscribeTopic(String topic) {
    // Extract device ID from topic
    final parts = topic.split('/');
    if (parts.length >= 2 && parts[0] == 'device') {
      final deviceId = parts[1];
      if (_deviceStates.containsKey(deviceId)) {
        return Stream.fromIterable([_deviceStates[deviceId]!]);
      }
    }
    
    return Stream.fromIterable([{}]);
  }
  
  @override
  Stream<Map<String, dynamic>> subscribeToDeviceStatus(String deviceId) {
    if (_deviceStates.containsKey(deviceId)) {
      return Stream.fromIterable([_deviceStates[deviceId]!]);
    }
    
    return Stream.fromIterable([{}]);
  }
  
  @override
  Future<void> publishMessage(String topic, String message) async {
    // Extract device ID from topic
    final parts = topic.split('/');
    if (parts.length >= 3 && parts[0] == 'device' && parts[2] == 'control') {
      final deviceId = parts[1];
      
      // Parse message
      final payload = jsonDecode(message);
      
      // Update device state
      if (_deviceStates.containsKey(deviceId)) {
        if (payload['command'] == 'set' && payload['componentId'] != null) {
          _deviceStates[deviceId]![payload['componentId']] = payload['value'];
        }
      }
    }
  }
  
  /// Get device state (test helper)
  Map<String, dynamic> getDeviceState(String deviceId) {
    return _deviceStates[deviceId] ?? {};
  }
  
  @override
  bool get isConnected => _isConnected;
}

/// Mock Device UI Service for testing
class MockDeviceUIService implements DeviceUIService {
  final Map<String, dynamic> _uiCache = {};
  
  @override
  Future<UiLayout> getDeviceUI(String deviceId) async {
    // Load test UI layout
    final testLayoutJson = await TestRunner.loadTestConfig('test-relay.json');
    final layoutMap = jsonDecode(testLayoutJson);
    
    // Update device ID
    layoutMap['deviceId'] = deviceId;
    
    // Create UI layout
    final uiLayout = UiLayout.fromJson(layoutMap);
    
    // Cache layout
    _uiCache[deviceId] = uiLayout;
    
    return uiLayout;
  }
  
  @override
  Future<Map<String, UiLayout>> batchGetDeviceUIs(List<String> deviceIds) async {
    final results = <String, UiLayout>{};
    
    for (final deviceId in deviceIds) {
      results[deviceId] = await getDeviceUI(deviceId);
    }
    
    return results;
  }
  
  @override
  void invalidateCache(String deviceId) {
    _uiCache.remove(deviceId);
  }
  
  @override
  void clearCache() {
    _uiCache.clear();
  }
}

/// Command result class
class CommandResult {
  final bool success;
  final String topic;
  final Map<String, dynamic> payload;
  
  CommandResult({
    required this.success,
    required this.topic,
    required this.payload,
  });
}