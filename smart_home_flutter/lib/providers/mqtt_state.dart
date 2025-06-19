import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import '../config/aws_configuration.dart';

// MQTT state
class MqttState {
  final bool isConnected;
  final String? error;
  final Map<String, Function(Map<String, dynamic>)> messageHandlers;

  MqttState({
    this.isConnected = false,
    this.error,
    this.messageHandlers = const {},
  });

  MqttState copyWith({
    bool? isConnected,
    String? error,
    Map<String, Function(Map<String, dynamic>)>? messageHandlers,
  }) {
    return MqttState(
      isConnected: isConnected ?? this.isConnected,
      error: error,  // Null if not provided
      messageHandlers: messageHandlers ?? this.messageHandlers,
    );
  }
}

// MQTT notifier
class MqttNotifier extends StateNotifier<MqttState> {
  MqttServerClient? _client;
  String? _clientId;
  final Map<String, StreamSubscription> _subscriptions = {};

  MqttNotifier() : super(MqttState());

  Future<void> connect() async {
    if (state.isConnected) {
      return;
    }

    // For web platform, we'll use a mock connection
    if (kIsWeb) {
      state = state.copyWith(isConnected: true);
      return;
    }

    try {
      // Get Cognito credentials
      if (!Amplify.isConfigured) {
        throw Exception('Amplify is not configured');
      }

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
      state = state.copyWith(
        isConnected: false,
        error: 'Failed to connect to MQTT broker: ${e.toString()}',
      );
    }
  }

  void _onConnected() {
    safePrint('MQTT client connected');
    state = state.copyWith(isConnected: true);
  }

  void _onDisconnected() {
    safePrint('MQTT client disconnected');
    _subscriptions.forEach((_, subscription) => subscription.cancel());
    _subscriptions.clear();
    
    state = state.copyWith(isConnected: false);
    
    // Try to reconnect after a delay
    Timer(const Duration(seconds: 5), () => connect());
  }

  void _onSubscribed(String topic) {
    safePrint('Subscription confirmed for topic $topic');
  }

  Future<void> subscribeToDevice(String deviceId, Function(Map<String, dynamic>) onMessage) async {
    if (!state.isConnected) {
      await connect();
    }

    // For web platform, we'll use a mock subscription
    if (kIsWeb) {
      final updatedHandlers = Map<String, Function(Map<String, dynamic>)>.from(state.messageHandlers);
      updatedHandlers[deviceId] = onMessage;
      state = state.copyWith(messageHandlers: updatedHandlers);
      
      // Simulate a device status update after a delay
      Timer(const Duration(seconds: 2), () {
        if (state.messageHandlers.containsKey(deviceId)) {
          state.messageHandlers[deviceId]!({
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'online'
          });
        }
      });
      
      return;
    }

    if (_client == null || !state.isConnected) {
      safePrint('Cannot subscribe: MQTT client not connected');
      return;
    }

    // Define topics
    final statusTopic = 'iot/device/$deviceId/status';
    final telemetryTopic = 'iot/device/$deviceId/telemetry';
    
    // Register message handler
    final updatedHandlers = Map<String, Function(Map<String, dynamic>)>.from(state.messageHandlers);
    updatedHandlers[deviceId] = onMessage;
    state = state.copyWith(messageHandlers: updatedHandlers);
    
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
            if (state.messageHandlers.containsKey(deviceId)) {
              state.messageHandlers[deviceId]!(data);
            }
          } catch (e) {
            safePrint('Error processing MQTT message: $e');
          }
        }
      });
    }
  }

  Future<void> publishToDevice(String deviceId, String messageType, Map<String, dynamic> data) async {
    if (!state.isConnected) {
      await connect();
    }

    // For web platform, we'll simulate a successful publish
    if (kIsWeb) {
      safePrint('Mock publish to device $deviceId: $data');
      
      // Simulate a device response after a delay
      Timer(const Duration(milliseconds: 500), () {
        if (state.messageHandlers.containsKey(deviceId)) {
          final response = Map<String, dynamic>.from(data);
          response['timestamp'] = DateTime.now().toIso8601String();
          state.messageHandlers[deviceId]!(response);
        }
      });
      
      return;
    }

    if (_client == null || !state.isConnected) {
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
    // For web platform, we'll just remove the handler
    if (kIsWeb) {
      final updatedHandlers = Map<String, Function(Map<String, dynamic>)>.from(state.messageHandlers);
      updatedHandlers.remove(deviceId);
      state = state.copyWith(messageHandlers: updatedHandlers);
      return;
    }

    if (_client == null || !state.isConnected) return;
    
    final statusTopic = 'iot/device/$deviceId/status';
    final telemetryTopic = 'iot/device/$deviceId/telemetry';
    
    _client!.unsubscribe(statusTopic);
    _client!.unsubscribe(telemetryTopic);
    
    _subscriptions[deviceId]?.cancel();
    _subscriptions.remove(deviceId);
    
    final updatedHandlers = Map<String, Function(Map<String, dynamic>)>.from(state.messageHandlers);
    updatedHandlers.remove(deviceId);
    state = state.copyWith(messageHandlers: updatedHandlers);
  }

  Future<void> disconnect() async {
    _subscriptions.forEach((_, subscription) => subscription.cancel());
    _subscriptions.clear();
    
    if (_client != null && state.isConnected && !kIsWeb) {
      _client!.disconnect();
    }
    
    _client = null;
    state = state.copyWith(isConnected: false, messageHandlers: {});
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// Provider
final mqttProvider = StateNotifierProvider<MqttNotifier, MqttState>((ref) {
  return MqttNotifier();
});