import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_flutter/test_device_ui.dart';

void main() {
  testWidgets('Test sensor device UI', (WidgetTester tester) async {
    // Build the test UI
    await tester.pumpWidget(const MaterialApp(
      home: DeviceUITestPage(),
    ));
    
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
}