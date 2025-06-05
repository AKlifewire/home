import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

import 'mqtt_simulator.dart';

/// This test demonstrates how to use the MQTT simulator to generate test data
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Device Simulator Tests', () {
    late MqttSimulator simulator;
    
    setUp(() async {
      simulator = MqttSimulator();
      final connected = await simulator.connect();
      expect(connected, true, reason: 'MQTT simulator should connect successfully');
    });
    
    tearDown(() {
      simulator.disconnect();
    });
    
    testWidgets('Simulate sensor data for temperature device', (tester) async {
      // Load test config
      final configFile = File('integration_test/test_configs/test-sensor.json');
      final config = json.decode(await configFile.readAsString());
      final deviceId = config['deviceId'];
      
      // Start simulation
      simulator.simulateSensor(
        deviceId: deviceId,
        field: 'temperature',
        min: 18.0,
        max: 30.0,
        interval: Duration(seconds: 1),
      );
      
      // Simulate humidity as well
      simulator.simulateSensor(
        deviceId: deviceId,
        field: 'humidity',
        min: 30.0,
        max: 70.0,
        interval: Duration(seconds: 2),
      );
      
      // Keep test running to observe simulation
      await Future.delayed(Duration(seconds: 10));
    });
    
    testWidgets('Simulate chart data with trend', (tester) async {
      // Load test config
      final configFile = File('integration_test/test_configs/test-chart.json');
      final config = json.decode(await configFile.readAsString());
      final deviceId = config['deviceId'];
      
      // Start simulation
      simulator.simulateChartData(
        deviceId: deviceId,
        field: 'power',
        baseValue: 100.0,
        variance: 20.0,
        interval: Duration(milliseconds: 500),
      );
      
      // Keep test running to observe simulation
      await Future.delayed(Duration(seconds: 10));
    });
    
    testWidgets('Simulate device status changes', (tester) async {
      // Load test config
      final configFile = File('integration_test/test_configs/test-complex.json');
      final config = json.decode(await configFile.readAsString());
      final deviceId = config['deviceId'];
      
      // Start simulation
      simulator.simulateStatusChanges(
        deviceId: deviceId,
        states: ['online', 'offline', 'error'],
        minInterval: Duration(seconds: 2),
        maxInterval: Duration(seconds: 5),
      );
      
      // Keep test running to observe simulation
      await Future.delayed(Duration(seconds: 15));
    });
  });
}