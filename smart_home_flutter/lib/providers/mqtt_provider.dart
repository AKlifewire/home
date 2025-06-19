import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import '../config/aws_configuration.dart';

class MqttProvider with ChangeNotifier {
  MqttServerClient? _client;
  bool _isConnected = false;
  String? _clientId;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Function(Map<String, dynamic>)> _messageHandlers = {};

  bool get isConnected => _isConnected;

  // Skip actual MQTT connection in web mode
  Future<void> connect() async {
    if (_isConnected || kIsWeb) {
      _isConnected = true;
      notifyListeners();
      return;
    }

    try {
      // Get Cognito credentials
      final cognitoPlugin = Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);
      final session = await cognitoPlugin.fetchAuthSession();
      final credentials = session.credentials;

      if (credentials == null) {
        throw Exception('Failed to get AWS credentials');
      }

      // Create a unique client ID
      _clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
      
      // Initialize MQTT client
      _client = MqttServerClient.withPort(
        Configuration.iotEndpoint,
        _clientId!,
        8883,
      );
      
      // Set up client parameters
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 20;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.secure = true;
      
      // Set up connection message
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(_clientId!)
          .withWillQos(MqttQos.atLeastOnce);
      
      _client!.connectionMessage = connMessage;
      
      // Connect to AWS IoT Core
      await _client!.connect();
    } catch (e) {
      safePrint('MQTT connection failed: $e');
      _client = null;
      _isConnected = false;
      notifyListeners();
    }
  }

  void _onConnected() {
    safePrint('MQTT client connected');
    _isConnected = true;
    notifyListeners();
  }

  void _onDisconnected() {
    safePrint('MQTT client disconnected');
    _isConnected = false;
    _subscriptions.forEach((_, subscription) => subscription.cancel());
    _subscriptions.clear();
    notifyListeners();
    
    // Try to reconnect after a delay
    Timer(const Duration(seconds: 5), () => connect());
  }

  void _onSubscribed(String topic) {
    safePrint('Subscription confirmed for topic $topic');
  }

  Future<void> subscribeToDevice(String deviceId, Function(Map<String, dynamic>) onMessage) async {
    if (!_isConnected) {
      await connect();
    }

    if (kIsWeb) {
      // Mock subscription for web
      _messageHandlers[deviceId] = onMessage;
      return;
    }

    if (_client == null || !_isConnected) {
      safePrint('Cannot subscribe: MQTT client not connected');
      return;
    }

    // Define topics
    final statusTopic = 'iot/device/$deviceId/status';
    final telemetryTopic = 'iot/device/$deviceId/telemetry';
    
    // Register message handler
    _messageHandlers[deviceId] = onMessage;
    
    // Subscribe to topics
    _client!.subscribe(statusTopic, MqttQos.atLeastOnce);
    _client!.subscribe(telemetryTopic, MqttQos.atLeastOnce);
    
    // Listen for messages
    if (!_subscriptions.containsKey(deviceId)) {
      _subscriptions[deviceId] = _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (final message in messages) {
          final recMess = message.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          
          try {
            final data = jsonDecode(payload);
            if (_messageHandlers.containsKey(deviceId)) {
              _messageHandlers[deviceId]!(data);
            }
          } catch (e) {
            safePrint('Error processing MQTT message: $e');
          }
        }
      });
    }
  }

  Future<void> publishToDevice(String deviceId, String messageType, Map<String, dynamic> data) async {
    if (!_isConnected) {
      await connect();
    }

    if (kIsWeb) {
      // Mock publish for web
      return;
    }

    if (_client == null || !_isConnected) {
      safePrint('Cannot publish: MQTT client not connected');
      return;
    }

    // Define topic based on message type
    String topic;
    if (messageType == 'control') {
      topic = 'iot/device/$deviceId/control';
    } else if (messageType == 'status') {
      topic = 'iot/device/$deviceId/status';
    } else if (messageType == 'telemetry') {
      topic = 'iot/device/$deviceId/telemetry';
    } else {
      topic = 'iot/device/$deviceId/$messageType';
    }
    
    final payload = jsonEncode(data);
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    
    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: false,
    );
  }

  void unsubscribeFromDevice(String deviceId) {
    if (kIsWeb) {
      // Mock unsubscribe for web
      _messageHandlers.remove(deviceId);
      return;
    }

    if (_client == null || !_isConnected) return;
    
    final statusTopic = 'iot/device/$deviceId/status';
    final telemetryTopic = 'iot/device/$deviceId/telemetry';
    
    _client!.unsubscribe(statusTopic);
    _client!.unsubscribe(telemetryTopic);
    
    _subscriptions[deviceId]?.cancel();
    _subscriptions.remove(deviceId);
    _messageHandlers.remove(deviceId);
  }

  Future<void> disconnect() async {
    _subscriptions.forEach((_, subscription) => subscription.cancel());
    _subscriptions.clear();
    _messageHandlers.clear();
    
    if (_client != null && _isConnected && !kIsWeb) {
      _client!.disconnect();
    }
    
    _client = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}