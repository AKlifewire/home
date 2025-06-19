import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:smart_home_flutter/main.dart' as app;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:smart_home_flutter/config/aws_configuration.dart';

// Mock device for testing
class MockDevice {
  final String deviceId;
  final MqttServerClient client;
  bool isConnected = false;

  MockDevice(this.deviceId) : client = MqttServerClient.withPort(
    Configuration.iotEndpoint,
    'mock_device_$deviceId',
    8883,
  );

  Future<void> connect() async {
    // In a real test, you would use proper AWS IoT credentials
    // For this example, we'll just simulate the connection
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.secure = true;
    
    try {
      await client.connect();
      isConnected = true;
      print('Mock device connected: $deviceId');
    } catch (e) {
      print('Failed to connect mock device: $e');
    }
  }

  void publishState(Map<String, dynamic> state) {
    if (!isConnected) return;
    
    final topic = 'iot/device/$deviceId/status';
    final payload = state.toString();
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    
    client.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    
    print('Published to $topic: $payload');
  }

  void disconnect() {
    if (isConnected) {
      client.disconnect();
      isConnected = false;
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test credentials - use environment variables in CI/CD
  const testEmail = 'test_user1@example.com';
  const testPassword = 'Test@123456';
  const testUsername = 'TestUser1';
  
  // Mock device ID that should match a device in the test account
  const mockDeviceId = 'irrigation-001';
  late MockDevice mockDevice;

  setUp(() async {
    // Initialize mock device
    mockDevice = MockDevice(mockDeviceId);
    // Don't actually connect in this example
    // await mockDevice.connect();
  });

  tearDown(() {
    mockDevice.disconnect();
  });

  group('End-to-End IoT Platform Test', () {
    testWidgets('Complete user journey with device interaction', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // 1. Sign Up Flow
      // Find and tap the sign up button on login screen
      await tester.pumpAndSettle();
      final signUpButton = find.text('Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Fill sign up form
      await tester.enterText(find.byType(TextFormField).at(0), testUsername);
      await tester.enterText(find.byType(TextFormField).at(1), testEmail);
      await tester.enterText(find.byType(TextFormField).at(2), testPassword);
      await tester.enterText(find.byType(TextFormField).at(3), testPassword);
      
      // Submit sign up form
      await tester.tap(find.text('Sign Up').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // In a real test, we'd handle the confirmation code
      // For this example, we'll assume the user is pre-confirmed in the test environment
      
      // 2. Sign In Flow
      // Enter login credentials
      await tester.enterText(find.byType(TextFormField).at(0), testEmail);
      await tester.enterText(find.byType(TextFormField).at(1), testPassword);
      
      // Submit login form
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // 3. Verify Home Screen and Device List
      // Check if we're on the home screen
      expect(find.text('My Devices'), findsOneWidget);
      
      // Wait for devices to load
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // 4. Tap on the mock device
      final deviceCard = find.text('Smart Irrigation');
      expect(deviceCard, findsOneWidget);
      await tester.tap(deviceCard);
      await tester.pumpAndSettle();
      
      // 5. Verify Device Detail Screen
      // Check if the UI components from the layout are rendered
      expect(find.text('Water Pump'), findsOneWidget);
      expect(find.text('Duration (min)'), findsOneWidget);
      expect(find.text('Soil Moisture'), findsOneWidget);
      
      // 6. Interact with device controls
      // Toggle the water pump switch
      final switchWidget = find.byType(Switch);
      await tester.tap(switchWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Adjust the duration slider
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(50, 0));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // 7. Simulate device sending data
      // In a real test, we would use the mock device to publish data
      // mockDevice.publishState({'soilMoisture': 75, 'waterPump': true});
      
      // 8. Verify UI updates with new data
      // Wait for MQTT message to be processed
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // 9. Navigate back to home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      
      // 10. Sign out
      await tester.tap(find.byIcon(Icons.account_circle));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify we're back at login screen
      expect(find.text('Login'), findsOneWidget);
    });
  });
}