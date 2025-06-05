import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Config-driven UI tests', () {
    testWidgets('Test relay device from config', (tester) async {
      // Test config for a relay device
      final config = {
        "deviceId": "test-relay",
        "deviceType": "relay",
        "title": "Test Relay",
        "subtitle": "Living Room",
        "components": [
          {
            "type": "header",
            "title": "Test Relay",
            "subtitle": "Living Room"
          },
          {
            "type": "status",
            "field": "connection",
            "label": "Status"
          },
          {
            "type": "toggle",
            "field": "relay1",
            "label": "Relay 1"
          }
        ]
      };
      
      // Mock device state
      final deviceState = {
        "connection": "connected",
        "relay1": false
      };
      
      await _testDeviceFromConfig(tester, config, deviceState);
    });
    
    testWidgets('Test sensor device from config', (tester) async {
      // Test config for a sensor device
      final config = {
        "deviceId": "test-sensor",
        "deviceType": "sensor",
        "title": "Test Sensor",
        "subtitle": "Kitchen",
        "components": [
          {
            "type": "header",
            "title": "Test Sensor",
            "subtitle": "Kitchen"
          },
          {
            "type": "status",
            "field": "connection",
            "label": "Status"
          },
          {
            "type": "gauge",
            "field": "temperature",
            "label": "Temperature",
            "unit": "°C"
          }
        ]
      };
      
      // Mock device state
      final deviceState = {
        "connection": "connected",
        "temperature": 22.5
      };
      
      await _testDeviceFromConfig(tester, config, deviceState);
    });
  });
}

/// Helper function to test a device UI from a configuration
Future<void> _testDeviceFromConfig(
  WidgetTester tester,
  Map<String, dynamic> config,
  Map<String, dynamic> deviceState
) async {
  // Build a dynamic UI based on the config
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text(config["title"] as String)),
        body: Builder(builder: (context) {
          final components = config["components"] as List;
          
          return ListView(
            children: components.map((component) {
              final type = component["type"] as String;
              final label = component["label"] ?? component["title"] ?? "";
              final field = component["field"] as String?;
              final value = field != null ? deviceState[field] : null;
              
              switch (type) {
                case "header":
                  return ListTile(
                    title: Text(component["title"] as String),
                    subtitle: Text(component["subtitle"] as String),
                  );
                  
                case "status":
                  final isConnected = value == "connected";
                  return ListTile(
                    title: Text(label as String),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isConnected ? "Connected" : "Disconnected",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                  
                case "toggle":
                  return SwitchListTile(
                    title: Text(label as String),
                    value: value as bool? ?? false,
                    onChanged: (_) {},
                  );
                  
                case "gauge":
                  final unit = component["unit"] as String? ?? "";
                  return ListTile(
                    title: Text(label as String),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.thermostat),
                        const SizedBox(width: 8),
                        Text("${value ?? 0} $unit"),
                      ],
                    ),
                  );
                  
                default:
                  return ListTile(title: Text("Unknown component: $type"));
              }
            }).toList(),
          );
        }),
      ),
    ),
  );
  
  await tester.pumpAndSettle();
  
  // Verify the title and subtitle
  expect(find.text(config["title"] as String), findsWidgets);
  expect(find.text(config["subtitle"] as String), findsWidgets);
  
  // Test each component based on its type
  for (final component in config["components"] as List) {
    final type = component["type"] as String;
    final label = component["label"] ?? component["title"] ?? "";
    
    if (label is String && label.isNotEmpty) {
      expect(find.textContaining(label), findsWidgets);
    }
    
    switch (type) {
      case "toggle":
        expect(find.byType(Switch), findsOneWidget);
        
        // Test interaction
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        break;
        
      case "status":
        expect(find.text("Connected"), findsOneWidget);
        break;
        
      case "gauge":
        final field = component["field"] as String;
        final unit = component["unit"] as String? ?? "";
        final value = deviceState[field];
        
        if (value != null) {
          expect(find.textContaining("$value"), findsWidgets);
        }
        break;
    }
  }
}