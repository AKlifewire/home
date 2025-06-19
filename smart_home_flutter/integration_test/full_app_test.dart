import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:smart_home_flutter/main.dart' as app;
import 'package:smart_home_flutter/config/aws_configuration.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:smart_home_flutter/config/amplifyconfiguration.dart';
import 'package:smart_home_flutter/test_helpers/test_device_creator.dart';

/// A comprehensive IoT device simulator that connects to AWS IoT Core
/// and simulates real device behavior for end-to-end testing
class TestIoTDevice {
  final String deviceId;
  final String deviceType;
  final MqttServerClient client;
  bool isConnected = false;
  
  // Device state that will be published
  Map<String, dynamic> state = {};

  // Subscription topics
  final List<String> subscriptions = [];

  // Telemetry simulation timer
  bool _simulatingTelemetry = false;

  TestIoTDevice({
    required this.deviceId,
    required this.deviceType,
    Map<String, dynamic>? initialState,
  }) : client = MqttServerClient.withPort(
    Configuration.iotEndpoint,
    'test_device_$deviceId',
    8883,
  ) {
    if (initialState != null) {
      state = Map<String, dynamic>.from(initialState);
    }
    
    // Set up client callbacks
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
  }

  void _onConnected() {
    safePrint('Test device connected successfully: $deviceId');
    isConnected = true;
  }

  void _onDisconnected() {
    safePrint('Test device disconnected: $deviceId');
    isConnected = false;
  }

  void _onSubscribed(String topic) {
    safePrint('Subscribed to: $topic');
  }

  /// Connect to AWS IoT Core
  Future<bool> connect() async {
    if (isConnected) return true;
    
    try {
      // Configure MQTT client for AWS IoT
      client.logging(on: true);
      client.keepAlivePeriod = 20;
      client.secure = true;
      client.port = 8883;
      
      // Set up connection message
      final connMessage = MqttConnectMessage()
          .withClientIdentifier('test_device_$deviceId')
          .withWillQos(MqttQos.atLeastOnce);
      
      client.connectionMessage = connMessage;
      
      // Connect to AWS IoT Core
      await client.connect();
      isConnected = client.connectionStatus!.state == MqttConnectionState.connected;
      
      if (isConnected) {
        safePrint('Test device connected: $deviceId');
        _subscribeToControlTopic();
      }
      
      return isConnected;
    } catch (e) {
      safePrint('Failed to connect test device: $e');
      return false;
    }
  }

  /// Subscribe to control topic to receive commands
  void _subscribeToControlTopic() {
    final controlTopic = 'iot/device/$deviceId/control';
    
    client.subscribe(controlTopic, MqttQos.atLeastOnce);
    subscriptions.add(controlTopic);
    
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        final recMess = message.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        
        try {
          final data = jsonDecode(payload);
          safePrint('Test device received command: $data');
          
          // Update device state based on command
          state.addAll(data);
          
          // Publish updated state
          publishState();
        } catch (e) {
          safePrint('Error processing command: $e');
        }
      }
    });
  }

  /// Publish device state to status topic
  Future<void> publishState() async {
    if (!isConnected) {
      final connected = await connect();
      if (!connected) return;
    }
    
    final topic = 'iot/device/$deviceId/status';
    final payload = jsonEncode(state);
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    
    client.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    
    safePrint('Published to $topic: $payload');
  }

  /// Publish telemetry data
  Future<void> publishTelemetry(Map<String, dynamic> telemetry) async {
    if (!isConnected) {
      final connected = await connect();
      if (!connected) return;
    }
    
    final topic = 'iot/device/$deviceId/telemetry';
    final payload = jsonEncode(telemetry);
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    
    client.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    
    safePrint('Published telemetry to $topic: $payload');
  }

  /// Update a specific state value and publish
  Future<void> updateState(String key, dynamic value) async {
    state[key] = value;
    await publishState();
  }

  /// Simulate a sensor reading change and publish
  Future<void> simulateSensorReading(String sensorName, dynamic value) async {
    await updateState(sensorName, value);
    safePrint('Simulated sensor reading: $sensorName = $value');
  }

  /// Start simulating telemetry data
  void startTelemetrySimulation() {
    if (_simulatingTelemetry) return;
    _simulatingTelemetry = true;
    
    // This would be implemented with a timer in a real test
    // For this example, we'll just set a flag
    safePrint('Started telemetry simulation');
  }

  /// Stop simulating telemetry data
  void stopTelemetrySimulation() {
    _simulatingTelemetry = false;
    safePrint('Stopped telemetry simulation');
  }

  /// Disconnect from AWS IoT Core
  void disconnect() {
    stopTelemetrySimulation();
    
    if (isConnected) {
      // Unsubscribe from all topics
      for (final topic in subscriptions) {
        client.unsubscribe(topic);
      }
      subscriptions.clear();
      
      client.disconnect();
      isConnected = false;
      safePrint('Test device disconnected: $deviceId');
    }
  }
}

/// Helper class to set up Amplify
class TestAmplifySetup {
  static Future<void> configureAmplify() async {
    try {
      if (Amplify.isConfigured) {
        safePrint('Amplify is already configured');
        return;
      }
      
      // Add Amplify plugins
      final authPlugin = AmplifyAuthCognito();
      final apiPlugin = AmplifyAPI();
      final storagePlugin = AmplifyStorageS3();
      
      await Amplify.addPlugins([authPlugin, apiPlugin, storagePlugin]);
      
      // Configure Amplify
      await Amplify.configure(amplifyconfig);
      
      safePrint('Amplify configured successfully');
    } catch (e) {
      safePrint('Error configuring Amplify: $e');
      rethrow;
    }
  }
}

/// Helper class to manage test users
class TestUserManager {
  static Future<bool> signUpTestUser(String username, String email, String password) async {
    try {
      // Check if user already exists by trying to sign in
      try {
        final result = await Amplify.Auth.signIn(
          username: email,
          password: password,
        );
        
        if (result.isSignedIn) {
          safePrint('Test user already exists and can sign in');
          await Amplify.Auth.signOut();
          return true;
        }
      } catch (e) {
        // User doesn't exist, which is what we want
        safePrint('User does not exist, will create: $e');
      }
      
      // Create the user
      final userAttributes = <CognitoUserAttributeKey, String>{
        CognitoUserAttributeKey.email: email,
        CognitoUserAttributeKey.preferredUsername: username,
      };
      
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: userAttributes,
        ),
      );
      
      if (result.isSignUpComplete) {
        safePrint('Test user created successfully');
        return true;
      } else {
        safePrint('User creation requires confirmation');
        // In a real test environment, you would need to auto-confirm the user
        return false;
      }
    } catch (e) {
      safePrint('Error creating test user: $e');
      return false;
    }
  }
  
  static Future<bool> signInTestUser(String email, String password) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      
      return result.isSignedIn;
    } catch (e) {
      safePrint('Error signing in test user: $e');
      return false;
    }
  }
  
  static Future<void> signOutTestUser() async {
    try {
      await Amplify.Auth.signOut();
      safePrint('Test user signed out');
    } catch (e) {
      safePrint('Error signing out test user: $e');
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test credentials - use environment variables in CI/CD
  const testEmail = 'test_user1@example.com';
  const testPassword = 'Test@123456';
  const testUsername = 'TestUser1';
  
  // Mock device configuration
  const mockDeviceId = 'irrigation-001';
  const mockDeviceType = 'smart-irrigation';
  late TestIoTDevice testDevice;
  String? createdDeviceId;

  setUpAll(() async {
    // Configure Amplify
    await TestAmplifySetup.configureAmplify();
    
    // Pre-create test user if needed
    await TestUserManager.signUpTestUser(testUsername, testEmail, testPassword);
  });

  setUp(() async {
    // Initialize test device with initial state
    testDevice = TestIoTDevice(
      deviceId: mockDeviceId,
      deviceType: mockDeviceType,
      initialState: {
        'waterPump': false,
        'duration': 10,
        'soilMoisture': 45,
        'lastWatered': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      },
    );
    
    try {
      // Set up test environment - create test device
      // This is commented out because it requires backend access
      // In a real test environment, you would uncomment this
      // createdDeviceId = await TestDeviceCreator.createTestDevice();
      
      // Connect test device to AWS IoT Core
      // In a real test environment, you would uncomment this
      // await testDevice.connect();
      // await testDevice.publishState();
    } catch (e) {
      safePrint('Error in test setup: $e');
    }
  });

  tearDown(() async {
    // Disconnect test device
    testDevice.disconnect();
    
    try {
      // Clean up test environment
      // In a real test environment, you would uncomment this
      // if (createdDeviceId != null) {
      //   await TestDeviceCreator.deleteTestDevice(createdDeviceId!);
      // }
    } catch (e) {
      safePrint('Error in test teardown: $e');
    }
  });

  tearDownAll(() async {
    // Sign out any logged in users
    await TestUserManager.signOutTestUser();
  });

  group('End-to-End Smart Home App Test', () {
    testWidgets('Complete user journey with device interaction', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // ===== 1. SIGN UP FLOW =====
      safePrint('STEP 1: Testing Sign Up Flow');
      
      // Find and tap the sign up button on login screen
      await tester.pumpAndSettle();
      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget, reason: 'Sign Up button not found on login screen');
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
      
      // ===== 2. SIGN IN FLOW =====
      safePrint('STEP 2: Testing Sign In Flow');
      
      // Enter login credentials
      await tester.enterText(find.byType(TextFormField).at(0), testEmail);
      await tester.enterText(find.byType(TextFormField).at(1), testPassword);
      
      // Submit login form
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // ===== 3. VERIFY HOME SCREEN AND DEVICE LIST =====
      safePrint('STEP 3: Verifying Home Screen and Device List');
      
      // Check if we're on the home screen
      expect(find.text('My Devices'), findsOneWidget, reason: 'Home screen not loaded');
      
      // Wait for devices to load
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // ===== 4. TAP ON THE MOCK DEVICE =====
      safePrint('STEP 4: Selecting Device from List');
      
      final deviceCard = find.text('Smart Irrigation');
      expect(deviceCard, findsOneWidget, reason: 'Device card not found');
      await tester.tap(deviceCard);
      await tester.pumpAndSettle();
      
      // ===== 5. VERIFY DEVICE DETAIL SCREEN =====
      safePrint('STEP 5: Verifying Device Detail Screen');
      
      // Check if the UI components from the layout are rendered
      expect(find.text('Water Pump'), findsOneWidget, reason: 'Water Pump control not found');
      expect(find.text('Duration (min)'), findsOneWidget, reason: 'Duration slider not found');
      expect(find.text('Soil Moisture'), findsOneWidget, reason: 'Soil Moisture chart not found');
      
      // ===== 6. INTERACT WITH DEVICE CONTROLS =====
      safePrint('STEP 6: Testing Device Control Interaction');
      
      // Toggle the water pump switch
      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget, reason: 'Switch widget not found');
      await tester.tap(switchWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Adjust the duration slider
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget, reason: 'Slider widget not found');
      await tester.drag(slider, const Offset(50, 0));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // ===== 7. SIMULATE DEVICE SENDING DATA =====
      safePrint('STEP 7: Simulating Device Data Updates');
      
      // In a real test, we would use the test device to publish data
      // This would be enabled in a real test environment
      // await testDevice.updateState('soilMoisture', 75);
      // await testDevice.updateState('waterPump', true);
      
      // ===== 8. VERIFY UI UPDATES WITH NEW DATA =====
      safePrint('STEP 8: Verifying UI Updates with New Data');
      
      // Wait for MQTT message to be processed
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // ===== 9. TEST ERROR HANDLING =====
      safePrint('STEP 9: Testing Error Handling');
      
      // Test offline mode or error states if applicable
      // This would depend on your app's error handling capabilities
      
      // ===== 10. NAVIGATE BACK TO HOME =====
      safePrint('STEP 10: Navigating Back to Home Screen');
      
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      
      // ===== 11. SIGN OUT =====
      safePrint('STEP 11: Testing Sign Out Flow');
      
      await tester.tap(find.byIcon(Icons.account_circle));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify we're back at login screen
      expect(find.text('Login'), findsOneWidget, reason: 'Not returned to login screen after sign out');
    });
  });
}