import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../utils/logger.dart';

final mqttServiceProvider = Provider((ref) => MQTTService());

/// Service for MQTT communication with IoT devices
class MQTTService {
  final _log = getLogger('MQTTService');
  MqttServerClient? _client;
  bool _connected = false;

  /// Initializes and connects to the MQTT broker
  Future<void> connect({
    required String host,
    required int port,
    required String clientId,
    String? username,
    String? password,
  }) async {
    try {
      _client = MqttServerClient(host, clientId)
        ..port = port
        ..logging(on: true)
        ..keepAlivePeriod = 60
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..onSubscribed = _onSubscribed
        ..secure = true;

      if (username != null) {
        _client!.connectionMessage = MqttConnectMessage()
          ..authenticateAs(username, password)
          ..withClientIdentifier(clientId)
          ..withWillQos(MqttQos.atLeastOnce);
      }

      await _client!.connect();
    } catch (e, stack) {
      _log.severe('Failed to connect to MQTT broker', e, stack);
      rethrow;
    }
  }

  /// Publishes a message to a topic
  Future<void> publish(String topic, MqttQos qos, String message) async {
    if (!_connected || _client == null) {
      throw Exception('MQTT client not connected');
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    _client!.publishMessage(topic, qos, builder.payload!, retain: false);
  }

  /// Subscribes to a topic
  Future<void> subscribe(
    String topic,
    MqttQos qos,
    Function(String topic, String message) onMessage,
  ) async {
    if (!_connected || _client == null) {
      throw Exception('MQTT client not connected');
    }

    _client!.subscribe(topic, qos);
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var msg in messages) {
        final recMess = msg.payload as MqttPublishMessage;
        final message = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        onMessage(msg.topic, message);
      }
    });
  }

  /// Disconnects from the MQTT broker
  Future<void> disconnect() async {
    _client?.disconnect();
  }

  void _onConnected() {
    _log.info('MQTT client connected');
    _connected = true;
  }

  void _onDisconnected() {
    _log.info('MQTT client disconnected');
    _connected = false;
  }

  void _onSubscribed(String topic) {
    _log.info('Subscription confirmed for topic $topic');
  }
}
