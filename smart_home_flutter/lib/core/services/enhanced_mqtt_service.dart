import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

final mqttServiceProvider = Provider((ref) => EnhancedMqttService(ref));

/// Enhanced MQTT service for real-time device communication
class EnhancedMqttService {
  final Ref _ref;
  MqttServerClient? _client;
  final Map<String, StreamController<Map<String, dynamic>>> _topicControllers = {};
  bool _isConnected = false;
  
  // Connection parameters
  String? _host;
  int _port = 8883;
  String? _clientId;
  
  // Authentication
  String? _username;
  String? _password;
  
  // Reconnection
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  EnhancedMqttService(this._ref);
  
  /// Initialize the MQTT service with connection parameters
  Future<void> initialize({
    required String host,
    int port = 8883,
    String? clientId,
    bool useTls = true,
  }) async {
    _host = host;
    _port = port;
    _clientId = clientId ?? 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    
    // Get authentication credentials
    final authService = _ref.read(authServiceProvider);
    final credentials = await authService.getMqttCredentials();
    _username = credentials['username'];
    _password = credentials['password'];
    
    // Connect to MQTT broker
    await connect();
  }
  
  /// Connect to the MQTT broker
  Future<bool> connect() async {
    if (_host == null) {
      throw Exception('MQTT host not initialized. Call initialize() first.');
    }
    
    // Create MQTT client
    _client = MqttServerClient(_host!, _clientId!)
      ..port = _port
      ..keepAlivePeriod = 30
      ..onDisconnected = _onDisconnected
      ..onConnected = _onConnected
      ..onSubscribed = _onSubscribed
      ..secure = _port == 8883; // Use TLS if port is 8883
    
    // Set up client
    final connMessage = MqttConnectMessage()
      ..withClientIdentifier(_clientId!)
      ..withWillQos(MqttQos.atLeastOnce)
      ..withWillRetain(false);
    
    // Add authentication if available
    if (_username != null && _password != null) {
      connMessage.authenticateAs(_username!, _password!);
    }
    
    _client!.connectionMessage = connMessage;
    
    try {
      await _client!.connect();
      return _isConnected;
    } catch (e) {
      logger.e('Failed to connect to MQTT broker: $e');
      _scheduleReconnect();
      return false;
    }
  }
  
  /// Disconnect from the MQTT broker
  Future<void> disconnect() async {
    _cancelReconnectTimer();
    _client?.disconnect();
    
    // Close all topic controllers
    for (final controller in _topicControllers.values) {
      await controller.close();
    }
    _topicControllers.clear();
  }
  
  /// Subscribe to a topic
  Stream<Map<String, dynamic>> subscribeTopic(String topic) {
    if (!_isConnected) {
      throw Exception('MQTT client not connected');
    }
    
    // Create controller if it doesn't exist
    if (!_topicControllers.containsKey(topic)) {
      _topicControllers[topic] = StreamController<Map<String, dynamic>>.broadcast();
      
      // Subscribe to the topic
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }
    
    return _topicControllers[topic]!.stream;
  }
  
  /// Subscribe to device status updates
  Stream<Map<String, dynamic>> subscribeToDeviceStatus(String deviceId) {
    return subscribeTopic('device/$deviceId/status');
  }
  
  /// Publish a message to a topic
  Future<void> publishMessage(String topic, String message) async {
    if (!_isConnected) {
      await connect();
      if (!_isConnected) {
        throw Exception('MQTT client not connected');
      }
    }
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    
    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: false,
    );
  }
  
  /// Called when connected to the broker
  void _onConnected() {
    logger.i('Connected to MQTT broker');
    _isConnected = true;
    _reconnectAttempts = 0;
    _cancelReconnectTimer();
    
    // Set up message handler
    _client!.updates!.listen(_onMessage);
    
    // Resubscribe to all topics
    for (final topic in _topicControllers.keys) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }
  }
  
  /// Called when disconnected from the broker
  void _onDisconnected() {
    logger.w('Disconnected from MQTT broker');
    _isConnected = false;
    _scheduleReconnect();
  }
  
  /// Called when subscribed to a topic
  void _onSubscribed(String topic) {
    logger.i('Subscribed to topic: $topic');
  }
  
  /// Handle incoming messages
  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = (message.payload as MqttPublishMessage).payload.message;
      
      // Convert payload to string
      final payloadString = MqttPublishPayload.bytesToStringAsString(payload);
      
      try {
        // Parse JSON payload
        final data = jsonDecode(payloadString) as Map<String, dynamic>;
        
        // Send to topic controller
        if (_topicControllers.containsKey(topic)) {
          _topicControllers[topic]!.add(data);
        }
      } catch (e) {
        logger.e('Failed to parse MQTT message: $e');
      }
    }
  }
  
  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _cancelReconnectTimer();
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: _reconnectAttempts * 2);
      
      logger.i('Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds} seconds');
      
      _reconnectTimer = Timer(delay, () async {
        logger.i('Attempting to reconnect to MQTT broker');
        await connect();
      });
    } else {
      logger.e('Max reconnect attempts reached');
    }
  }
  
  /// Cancel reconnection timer
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  /// Check if connected to the broker
  bool get isConnected => _isConnected;
}