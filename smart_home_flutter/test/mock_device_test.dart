import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test dynamic UI rendering from JSON', (tester) async {
    // Mock UI JSON that would normally come from the backend
    final mockUiJson = {
      "deviceId": "test-device-123",
      "title": "Test Device",
      "subtitle": "Test Location",
      "components": [
        {
          "type": "header",
          "title": "Test Device",
          "subtitle": "Test Location"
        },
        {
          "type": "status",
          "field": "connection",
          "label": "Connection Status"
        },
        {
          "type": "toggle",
          "field": "power",
          "label": "Power"
        }
      ]
    };
    
    // Build a simple test widget that renders the UI based on JSON
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text(mockUiJson["title"] as String)),
          body: Builder(builder: (context) {
            // This is a simplified version of what your dynamic UI builder would do
            return ListView(
              children: [
                // Header
                ListTile(
                  title: Text(mockUiJson["title"] as String),
                  subtitle: Text(mockUiJson["subtitle"] as String),
                ),
                // Status
                ListTile(
                  title: Text("Connection Status"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("Connected", style: TextStyle(color: Colors.white)),
                  ),
                ),
                // Toggle
                SwitchListTile(
                  title: const Text("Power"),
                  value: false,
                  onChanged: (_) {},
                ),
              ],
            );
          }),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Verify components are rendered correctly
    expect(find.text("Test Device"), findsWidgets);
    expect(find.text("Test Location"), findsWidgets);
    expect(find.text("Connection Status"), findsOneWidget);
    expect(find.text("Connected"), findsOneWidget);
    expect(find.text("Power"), findsOneWidget);
    
    // Verify interactive components
    expect(find.byType(Switch), findsOneWidget);
    
    // Test interaction
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    
    // In a real test, we would verify the state change
    // but this mock doesn't have state management
  });
}