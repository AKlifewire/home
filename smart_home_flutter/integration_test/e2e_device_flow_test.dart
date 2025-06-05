import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_home_flutter/main.dart' as app;
import 'package:smart_home_flutter/core/services/enhanced_mqtt_service.dart';
import '../lib/utils/device_simulator.dart';
import 'helpers/test_runner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Device Flow Tests', () {
    late DeviceSimulator simulator;
    
    const String testDeviceId = 'e2e-test-device-001';
    
    // MQTT connection parameters - replace with your test environment values
    const String mqttHost = 'test.mosquitto.org';
    const int mqttPort = 1883;
    
    setUp(() async {
      // Create device simulator
      simulator = DeviceSimulator.create('relay', testDeviceId, location: 'Test Room');
      
      // Connect simulator to MQTT broker
      final connected = await simulator.connect(
        host: mqttHost,
        port: mqttPort,
      );
      expect(connected, isTrue);
      
      // Start simulator
      simulator.start();
      
      // Wait for device to publish its config
      await Future.delayed(const Duration(seconds: 2));
    });
    
    tearDown(() {
      simulator.stop();
    });
    
    testWidgets('Full device registration and control flow', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();
      
      // Log in (assuming app starts with login screen)
      // Note: In a real test, you would use actual test credentials
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      
      // Navigate to device registration screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Register device
      await tester.enterText(find.byKey(const Key('deviceId')), testDeviceId);
      await tester.enterText(find.byKey(const Key('deviceName')), 'Test Relay');
      await tester.tap(find.byKey(const Key('deviceTypeDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('relay').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('deviceLocation')), 'Test Room');
      await tester.tap(find.text('Register Device'));
      await tester.pumpAndSettle();
      
      // Wait for registration to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Navigate to device screen
      await tester.tap(find.text('Test Relay'));
      await tester.pumpAndSettle();
      
      // Verify device UI is displayed
      expect(find.text('Test Relay'), findsOneWidget);
      expect(find.text('Relay 1'), findsOneWidget);
      expect(find.text('Relay 2'), findsOneWidget);
      
      // Toggle relay 1
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      
      // Wait for state to update
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify relay state changed
      final switchWidget = tester.widget<Switch>(find.byType(Switch).first);
      expect(switchWidget.value, isTrue);
      
      // Toggle relay 1 again
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      
      // Wait for state to update
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify relay state changed back
      final updatedSwitchWidget = tester.widget<Switch>(find.byType(Switch).first);
      expect(updatedSwitchWidget.value, isFalse);
    });
  });
}