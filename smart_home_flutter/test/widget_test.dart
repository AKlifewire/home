import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_flutter/test_device_ui.dart';

void main() {
  testWidgets('Test relay device UI', (WidgetTester tester) async {
    // Build the test UI
    await tester.pumpWidget(const MaterialApp(
      home: DeviceUITestPage(),
    ));
    
    // Verify header is displayed - using find.textContaining to handle multiple instances
    expect(find.textContaining('Test Relay Controller'), findsWidgets);
    expect(find.textContaining('Test Location'), findsWidgets);
    
    // Verify status is displayed
    expect(find.text('Connection Status'), findsOneWidget);
    
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
}