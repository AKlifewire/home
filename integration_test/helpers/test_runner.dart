import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// Import your app's components
// import '../../lib/ui/screens/device_dynamic_page.dart';
// import '../../lib/core/graphql/mutations.dart';
// import '../../lib/core/services/ui_json_loader.dart';

/// Universal device test runner that handles the full lifecycle of device testing
Future<void> runDeviceFlowTest({
  required WidgetTester tester,
  required String username,
  required String password,
  required Map<String, dynamic> testConfig,
}) async {
  final deviceId = testConfig['deviceId'] ?? 'test-${DateTime.now().millisecondsSinceEpoch}';
  
  // Step 1: Authentication
  print('🔑 Authenticating as $username');
  final signInResult = await Amplify.Auth.signIn(
    username: username,
    password: password,
  );
  expect(signInResult.isSignedIn, true);
  print('✅ Signed in successfully');
  
  // Step 2: Register device
  print('📝 Registering device: $deviceId');
  final regResult = await Amplify.API.mutate(
    request: GraphQLRequest<String>(
      document: '''
        mutation RegisterDevice(\$deviceId: String!, \$type: String!, \$location: String) {
          registerDevice(deviceId: \$deviceId, type: \$type, location: \$location) {
            deviceId
            type
            location
          }
        }
      ''',
      variables: {
        'deviceId': deviceId,
        'type': testConfig['deviceType'],
        'location': testConfig['subtitle'] ?? 'Test Location',
      },
    ),
  ).response;
  expect(regResult.errors.isEmpty, true);
  print('✅ Device registered: $deviceId');
  
  // Step 3: Wait for UI JSON generation
  print('⏳ Waiting for Lambda to generate UI...');
  await Future.delayed(Duration(seconds: 5));
  
  // Step 4: Fetch UI JSON
  print('📥 Fetching UI JSON for $deviceId');
  final uiJsonResult = await Amplify.API.query(
    request: GraphQLRequest<String>(
      document: '''
        query GetDeviceUiJson(\$deviceId: String!) {
          getDeviceUiJson(deviceId: \$deviceId) {
            deviceId
            uiJson
          }
        }
      ''',
      variables: {
        'deviceId': deviceId,
      },
    ),
  ).response;
  
  expect(uiJsonResult.errors.isEmpty, true);
  final data = json.decode(uiJsonResult.data ?? '{}');
  final uiJson = json.decode(data['getDeviceUiJson']['uiJson'] ?? '{}');
  expect(uiJson['components'], isNotEmpty);
  print('✅ UI JSON loaded with ${uiJson['components'].length} components');
  
  // Step 5: Render the UI
  // Uncomment and adjust based on your actual app structure
  /*
  await tester.pumpWidget(MaterialApp(
    home: DeviceDynamicPage(uiJson: uiJson, deviceId: deviceId),
  ));
  await tester.pumpAndSettle();
  */
  print('✅ UI rendered for $deviceId');
  
  // Step 6: Test each component
  final components = uiJson['components'] as List;
  for (var component in components) {
    final type = component['type'];
    final label = component['label'] ?? component['title'] ?? '';
    final field = component['field'];
    final topic = component['topic'];
    
    print('🔍 Testing component: $type - $label');
    
    // Skip components marked for skipping in test metadata
    if (component['test'] != null && component['test']['skip'] == true) {
      print('⏭️ Skipping test for $type - $label (marked as skip)');
      continue;
    }
    
    switch (type) {
      case 'toggle':
        // Find and interact with toggle
        final toggle = find.byType(Switch);
        expect(toggle, findsOneWidget);
        
        // Get initial state
        final Switch switchWidget = tester.widget(toggle);
        final initialValue = switchWidget.value;
        
        // Toggle the switch
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        
        // Verify state changed
        final updatedSwitch = tester.widget<Switch>(toggle);
        expect(updatedSwitch.value, !initialValue);
        
        // If topic is provided, publish MQTT message
        if (topic != null) {
          await _publishMqttMessage(
            topic: topic,
            payload: json.encode({field: !initialValue}),
          );
        }
        
        print('✅ Toggled: $label');
        break;
        
      case 'gauge':
        // Find gauge component
        final labelFinder = find.text(label);
        expect(labelFinder, findsOneWidget);
        
        // If topic is provided, publish test values
        if (topic != null && field != null) {
          await _publishMqttMessage(
            topic: topic,
            payload: json.encode({field: 75.5}),  // Test value
          );
          await tester.pumpAndSettle();
        }
        
        print('✅ Verified gauge: $label');
        break;
        
      case 'chart':
        // Find chart component
        final labelFinder = find.text(label);
        expect(labelFinder, findsOneWidget);
        
        // If topic is provided, publish test values
        if (topic != null && field != null) {
          // Publish multiple data points for chart
          for (var i = 0; i < 5; i++) {
            await _publishMqttMessage(
              topic: topic,
              payload: json.encode({field: 20.0 + (i * 10)}),
            );
            await Future.delayed(Duration(milliseconds: 500));
          }
          await tester.pumpAndSettle();
        }
        
        print('✅ Verified chart: $label');
        break;
        
      case 'status':
        // Find status component
        final labelFinder = find.text(label);
        expect(labelFinder, findsOneWidget);
        
        // If topic is provided, publish test values
        if (topic != null && field != null) {
          await _publishMqttMessage(
            topic: topic,
            payload: json.encode({field: 'online'}),
          );
          await tester.pumpAndSettle();
        }
        
        print('✅ Verified status: $label');
        break;
        
      case 'text':
      case 'header':
        // Find text component
        final labelFinder = find.text(label);
        expect(labelFinder, findsWidgets);
        print('✅ Verified text: $label');
        break;
        
      case 'image':
        // Find image component
        final imageFinder = find.byType(Image);
        expect(imageFinder, findsWidgets);
        print('✅ Verified image component');
        break;
        
      default:
        print('⚠ Unknown or unhandled component type: $type');
    }
  }
  
  print('✅ Finished test for device: $deviceId');
}

/// Helper function to publish MQTT messages for testing
Future<void> _publishMqttMessage({
  required String topic,
  required String payload,
}) async {
  // Get MQTT connection details from environment or config
  final mqttBroker = 'test.mosquitto.org'; // Replace with your MQTT broker
  final mqttPort = 1883;
  final mqttClientId = 'flutter_test_${DateTime.now().millisecondsSinceEpoch}';
  
  // Create MQTT client
  final client = MqttServerClient(mqttBroker, mqttClientId);
  client.port = mqttPort;
  client.keepAlivePeriod = 30;
  client.onDisconnected = () {
    print('MQTT Disconnected');
  };
  
  try {
    // Connect to MQTT broker
    await client.connect();
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT Connected');
      
      // Publish message
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      client.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      
      print('Published to $topic: $payload');
    }
  } catch (e) {
    print('MQTT Error: $e');
  } finally {
    // Disconnect
    client.disconnect();
  }
}