import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_home_flutter/test_device_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Device UI Tests', () {
    testWidgets('Test relay device UI', (tester) async {
      // Build the test UI
      await tester.pumpWidget(const MaterialApp(
        home: DeviceUITestPage(),
      ));
      await tester.pumpAndSettle();
      
      // Verify header is displayed
      expect(find.textContaining('Test Relay Controller'), findsWidgets);
      expect(find.textContaining('Test Location'), findsWidgets);
      
      // Verify status is displayed
      expect(find.text('Connection Status'), findsOneWidget);
      expect(find.textContaining('Connected'), findsWidgets);
      
      // Find and toggle the switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      
      // Get initial state
      final Switch switchWidget = tester.widget(switchFinder);
      final initialValue = switchWidget.value;
      
      // Toggle the switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      
      // Verify state changed
      final updatedSwitch = tester.widget<Switch>(switchFinder);
      expect(updatedSwitch.value, !initialValue);
    });
    
    testWidgets('Test sensor device UI', (tester) async {
      // Build the test UI
      await tester.pumpWidget(const MaterialApp(
        home: DeviceUITestPage(),
      ));
      await tester.pumpAndSettle();
      
      // Navigate to sensor tab
      await tester.tap(find.text('Sensor'));
      await tester.pumpAndSettle();
      
      // Verify header is displayed
      expect(find.textContaining('Test Environment Sensor'), findsWidgets);
      expect(find.textContaining('Test Room'), findsWidgets);
      
      // Verify temperature gauge is displayed
      expect(find.text('Temperature'), findsOneWidget);
      expect(find.textContaining('22.5 °C'), findsWidgets);
    });
  });
}