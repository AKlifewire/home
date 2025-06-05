import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../lib/utils/device_simulator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Device Simulator Tests', () {
    late MqttServerClient testClient;
    late DeviceSimulator simulator;
    
    const String mqttHost = 'test.mosquitto.org';
    const int mqttPort = 1883;
    const String testDeviceId = 'test-device-001';
    
    setUp(() async {
      // Set up test MQTT client to verify simulator behavior
      testClient = MqttServerClient(mqttHost, 'test-client-${DateTime.now().millisecondsSinceEpoch}')
        ..port = mqttPort
        ..keepAlivePeriod = 60
        ..logging(on: false);
      
      await testClient.connect();
      expect(testClient.connectionStatus!.state, MqttConnectionState.connected);
      
      // Create device simulator
      simulator = DeviceSimulator.create('sensor', testDeviceId, location: 'Test Room');
    });
    
    tearDown(() {
      simulator.stop();
      testClient.disconnect();
    });
    
    test('Device simulator connects and publishes config', () async {
      // Set up listener for device config
      final configCompleter = Completer<String>();
      testClient.subscribe('devices/$testDeviceId/config', MqttQos.atLeastOnce);
      
      testClient.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (var msg in messages) {
          if (msg.topic == 'devices/$testDeviceId/config') {
            final recMess = msg.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
              recMess.payload.message,
            );
            configCompleter.complete(payload);
          }
        }
      });
      
      // Connect simulator
      final connected = await simulator.connect(
        host: mqttHost,
        port: mqttPort,
      );
      expect(connected, isTrue);
      
      // Start simulator
      simulator.start();
      
      // Wait for config message
      final configJson = await configCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Config message not received'),
      );
      
      // Verify config
      final config = jsonDecode(configJson);
      expect(config['deviceId'], testDeviceId);
      expect(config['type'], 'sensor');
      expect(config['location'], 'Test Room');
      expect(config['components'], isNotEmpty);
      
      // Verify components
      final components = config['components'] as List;
      expect(components.length, 2);
      
      final tempComponent = components.firstWhere(
        (c) => c['field'] == 'temperature',
        orElse: () => null,
      );
      expect(tempComponent, isNotNull);
      expect(tempComponent['type'], 'temperature');
      expect(tempComponent['label'], 'Temperature');
      expect(tempComponent['unit'], '°C');
      
      final humidityComponent = components.firstWhere(
        (c) => c['field'] == 'humidity',
        orElse: () => null,
      );
      expect(humidityComponent, isNotNull);
      expect(humidityComponent['type'], 'humidity');
      expect(humidityComponent['label'], 'Humidity');
      expect(humidityComponent['unit'], '%');
    });
    
    test('Device simulator publishes component values', () async {
      // Set up listener for temperature updates
      final tempCompleter = Completer<String>();
      testClient.subscribe('devices/$testDeviceId/components/temperature/status', MqttQos.atLeastOnce);
      
      testClient.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (var msg in messages) {
          if (msg.topic == 'devices/$testDeviceId/components/temperature/status') {
            final recMess = msg.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
              recMess.payload.message,
            );
            tempCompleter.complete(payload);
          }
        }
      });
      
      // Connect and start simulator
      await simulator.connect(host: mqttHost, port: mqttPort);
      simulator.start();
      
      // Wait for temperature update
      final tempJson = await tempCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Temperature update not received'),
      );
      
      // Verify temperature data
      final tempData = jsonDecode(tempJson);
      expect(tempData['value'], isNotNull);
      expect(tempData['timestamp'], isNotNull);
      expect(tempData['unit'], '°C');
      
      // Temperature should be between 20 and 25 degrees
      final tempValue = tempData['value'] as num;
      expect(tempValue, greaterThanOrEqualTo(20));
      expect(tempValue, lessThanOrEqualTo(25));
    });
    
    test('Device simulator responds to commands', () async {
      // Set up listener for relay status
      final relaySimulator = DeviceSimulator.create('relay', 'test-relay-001');
      final statusCompleter = Completer<String>();
      
      await relaySimulator.connect(host: mqttHost, port: mqttPort);
      relaySimulator.start();
      
      testClient.subscribe('devices/test-relay-001/components/relay1/status', MqttQos.atLeastOnce);
      
      testClient.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (var msg in messages) {
          if (msg.topic == 'devices/test-relay-001/components/relay1/status') {
            final recMess = msg.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
              recMess.payload.message,
            );
            statusCompleter.complete(payload);
          }
        }
      });
      
      // Wait for initial status
      await statusCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Initial status not received'),
      );
      
      // Reset completer for next status update
      final commandCompleter = Completer<String>();
      testClient.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (var msg in messages) {
          if (msg.topic == 'devices/test-relay-001/components/relay1/status') {
            final recMess = msg.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
              recMess.payload.message,
            );
            commandCompleter.complete(payload);
          }
        }
      });
      
      // Send command to turn on relay
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode({'value': 'on'}));
      
      testClient.publishMessage(
        'devices/test-relay-001/components/relay1/set',
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      
      // Wait for status update
      final statusJson = await commandCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Command response not received'),
      );
      
      // Verify relay turned on
      final statusData = jsonDecode(statusJson);
      expect(statusData['value'], isTrue);
      
      relaySimulator.stop();
    });
  });
}