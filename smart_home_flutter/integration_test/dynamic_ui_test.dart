import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_home_flutter/main_enhanced.dart' as app;
import 'package:smart_home_flutter/core/models/ui_layout.dart';
import 'package:smart_home_flutter/widgets/dynamic_component.dart';
import 'helpers/test_runner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic UI Tests', () {
    testWidgets('Test UI layout parsing and rendering', (WidgetTester tester) async {
      // Load test UI layout
      final testLayoutJson = await TestRunner.loadTestConfig('test-relay.json');
      final layoutMap = jsonDecode(testLayoutJson);
      final uiLayout = UiLayout.fromJson(layoutMap);

      // Verify layout was parsed correctly
      expect(uiLayout.deviceId, 'test-relay-01');
      expect(uiLayout.screens.length, greaterThan(0));
      
      // Create test widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceUI(
              deviceId: uiLayout.deviceId,
              screens: uiLayout.screens,
            ),
          ),
        ),
      );
      
      // Wait for widget to build
      await tester.pumpAndSettle();
      
      // Verify UI components are rendered
      expect(find.text('Main'), findsOneWidget); // Screen title
      
      // Find toggle widgets
      final toggleWidgets = find.byType(Switch);
      expect(toggleWidgets, findsWidgets);
      
      // Test interaction with toggle
      await tester.tap(toggleWidgets.first);
      await tester.pumpAndSettle();
      
      // Verify toggle state changed (this would normally send MQTT command)
      final Switch switchWidget = tester.widget(toggleWidgets.first);
      expect(switchWidget.value, isTrue);
    });
  });

  group('Device Control Tests', () {
    testWidgets('Test device control with mock MQTT', (WidgetTester tester) async {
      // Initialize app with mock services
      await TestRunner.initializeAppWithMocks();
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to device screen (assuming we're logged in for this test)
      // This would require mocking auth state
      
      // Load test device
      final testDevice = await TestRunner.loadTestDevice('test-relay-01');
      
      // Verify device loaded
      expect(testDevice, isNotNull);
      
      // Test sending command
      final result = await TestRunner.sendMockCommand(
        'test-relay-01', 
        'relay1', 
        {'command': 'set', 'value': true}
      );
      
      // Verify command was sent
      expect(result.success, isTrue);
      
      // Verify device state updated
      final deviceState = await TestRunner.getDeviceState('test-relay-01');
      expect(deviceState['relay1'], isTrue);
    });
  });
}