import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// MQTT Simulator for generating test data during E2E tests
class MqttSimulator {
  final String broker;
  final int port;
  final String clientId;
  MqttServerClient? _client;
  final Map<String, Timer> _activeSimulations = {};
  final Random _random = Random();

  MqttSimulator({
    this.broker = 'test.mosquitto.org',
    this.port = 1883,
    String? clientId,
  }) : clientId = clientId ?? 'flutter_simulator_${DateTime.now().millisecondsSinceEpoch}';

  /// Connect to the MQTT broker
  Future<bool> connect() async {
    _client = MqttServerClient(broker, clientId);
    _client!.port = port;
    _client!.keepAlivePeriod = 30;
    _client!.onDisconnected = _onDisconnected;

    try {
      await _client!.connect();
      return _client!.connectionStatus!.state == MqttConnectionState.connected;
    } catch (e) {
      print('MQTT Simulator connection error: $e');
      return false;
    }
  }

  /// Disconnect from the MQTT broker
  void disconnect() {
    // Stop all active simulations
    _activeSimulations.forEach((topic, timer) {
      timer.cancel();
    });
    _activeSimulations.clear();

    // Disconnect client
    _client?.disconnect();
    _client = null;
  }

  void _onDisconnected() {
    print('MQTT Simulator disconnected');
    _activeSimulations.forEach((topic, timer) {
      timer.cancel();
    });
    _activeSimulations.clear();
  }

  /// Simulate sensor data for a specific device
  void simulateSensor({
    required String deviceId,
    required String field,
    required double min,
    required double max,
    Duration interval = const Duration(seconds: 2),
  }) {
    final topic = 'iot/data/$deviceId';
    
    // Cancel existing simulation if any
    _activeSimulations[topic]?.cancel();
    
    // Create new simulation
    _activeSimulations[topic] = Timer.periodic(interval, (timer) {
      if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
        timer.cancel();
        _activeSimulations.remove(topic);
        return;
      }
      
      // Generate random value
      final value = min + _random.nextDouble() * (max - min);
      
      // Publish to MQTT
      publishMessage(
        topic: topic,
        payload: json.encode({field: value.toStringAsFixed(1)}),
      );
    });
    
    print('Started simulation for $deviceId.$field ($min-$max) every ${interval.inSeconds}s');
  }

  /// Simulate chart data with trend
  void simulateChartData({
    required String deviceId,
    required String field,
    required double baseValue,
    required double variance,
    Duration interval = const Duration(seconds: 1),
  }) {
    final topic = 'iot/data/$deviceId';
    double currentValue = baseValue;
    
    // Cancel existing simulation if any
    _activeSimulations[topic]?.cancel();
    
    // Create new simulation
    _activeSimulations[topic] = Timer.periodic(interval, (timer) {
      if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
        timer.cancel();
        _activeSimulations.remove(topic);
        return;
      }
      
      // Generate next value with some randomness but following a trend
      currentValue += (_random.nextDouble() - 0.5) * variance;
      
      // Publish to MQTT
      publishMessage(
        topic: topic,
        payload: json.encode({
          field: currentValue.toStringAsFixed(1),
          'timestamp': DateTime.now().millisecondsSinceEpoch
        }),
      );
    });
    
    print('Started chart simulation for $deviceId.$field around $baseValue±$variance');
  }

  /// Simulate device status changes
  void simulateStatusChanges({
    required String deviceId,
    List<String> states = const ['online', 'offline', 'error', 'maintenance'],
    Duration minInterval = const Duration(seconds: 30),
    Duration maxInterval = const Duration(seconds: 120),
  }) {
    final topic = 'iot/status/$deviceId';
    
    // Cancel existing simulation if any
    _activeSimulations[topic]?.cancel();
    
    // Function to schedule next status change
    void scheduleNext() {
      if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
        _activeSimulations.remove(topic);
        return;
      }
      
      // Select random state
      final state = states[_random.nextInt(states.length)];
      
      // Publish to MQTT
      publishMessage(
        topic: topic,
        payload: json.encode({'connection': state}),
      );
      
      print('Device $deviceId status changed to: $state');
      
      // Schedule next change
      final nextInterval = Duration(
        milliseconds: minInterval.inMilliseconds + 
            _random.nextInt(maxInterval.inMilliseconds - minInterval.inMilliseconds),
      );
      
      _activeSimulations[topic] = Timer(nextInterval, scheduleNext);
    }
    
    // Start the simulation
    scheduleNext();
  }

  /// Publish a single message to a topic
  void publishMessage({
    required String topic,
    required String payload,
  }) {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      print('Cannot publish: MQTT client not connected');
      return;
    }
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    
    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }
}