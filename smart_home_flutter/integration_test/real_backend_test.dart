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

/// A real IoT device simulator that connects to AWS IoT Core
class RealIoTDevice {
  final String deviceId;
  final String deviceType;
  final MqttServerClient client;
  bool isConnected = false;
  
  // Device state that will be published
  Map<String, dynamic> state = {};

  RealIoTDevice({
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
    safePrint('IoT device connected successfully: $deviceId');
    isConnected = true;
  }

  void _onDisconnected() {
    safePrint('IoT device disconnected: $deviceId');
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
        safePrint('IoT device connected: $deviceId');
        _subscribeToControlTopic();
      }
      
      return isConnected;
    } catch (e) {
      safePrint('Failed to connect IoT device: $e');
      return false;
    }
  }

  /// Subscribe to control topic to receive commands
  void _subscribeToControlTopic() {
    final controlTopic = 'iot/device/$deviceId/control';
    
    client.subscribe(controlTopic, MqttQos.atLeastOnce);
    
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        final recMess = message.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        
        try {
          final data = jsonDecode(payload);
          safePrint('IoT device received command: $data');
          
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

  /// Update a specific state value and publish
  Future<void> updateState(String key, dynamic value) async {
    state[key] = value;
    await publishState();
  }

  /// Disconnect from AWS IoT Core
  void disconnect() {
    if (isConnected) {
      client.disconnect();
      isConnected = false;
      safePrint('IoT device disconnected: $deviceId');
    }
  }
}

/// Helper class to set up Amplify
class AmplifySetup {
  static Future<void> configureAmplify() async {
    try {
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test credentials - use environment variables in CI/CD
  const testEmail = 'test_user1@example.com';
  const testPassword = 'Test@123456';
  
  // Mock device configuration
  const deviceId = 'irrigation-001';
  const deviceType = 'smart-irrigation';
  late RealIoTDevice iotDevice;

  setUpAll(() async {
    // Configure Amplify
    await AmplifySetup.configureAmplify();
  });

  setUp(() async {
    // Initialize IoT device with initial state
    iotDevice = RealIoTDevice(
      deviceId: deviceId,
      deviceType: deviceType,
      initialState: {
        'waterPump': false,
        'duration': 10,
        'soilMoisture': 45,
        'lastWatered': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      },
    );
    
    try {
      // Connect IoT device to AWS IoT Core
      await iotDevice.connect();
      
      // Publish initial state
      await iotDevice.publishState();
    } catch (e) {
      safePrint('Error in test setup: $e');
    }
  });

  tearDown(() {
    // Disconnect IoT device
    iotDevice.disconnect();
  });

  group('Real Backend Integration Test', () {
    testWidgets('Complete user journey with real backend connection', (WidgetTester tester) async {
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
      await tester.enterText(find.byType(TextFormField).at(0), 'TestUser1');
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
      
      // ===== 4. TAP ON THE DEVICE =====
      safePrint('STEP 4: Selecting Device from List');
      
      final deviceCard = find.text('Smart Irrigation');
      if (deviceCard.evaluate().isNotEmpty) {
        await tester.tap(deviceCard);
        await tester.pumpAndSettle();
        
        // ===== 5. VERIFY DEVICE DETAIL SCREEN =====
        safePrint('STEP 5: Verifying Device Detail Screen');
        
        // Check if the UI components from the layout are rendered
        expect(find.text('Water Pump'), findsOneWidget, reason: 'Water Pump control not found');
        
        // ===== 6. INTERACT WITH DEVICE CONTROLS =====
        safePrint('STEP 6: Testing Device Control Interaction');
        
        // Toggle the water pump switch
        final switchWidget = find.byType(Switch);
        if (switchWidget.evaluate().isNotEmpty) {
          await tester.tap(switchWidget);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          // Update IoT device state to simulate real-time response
          await iotDevice.updateState('waterPump', true);
        }
        
        // Adjust the duration slider if available
        final slider = find.byType(Slider);
        if (slider.evaluate().isNotEmpty) {
          await tester.drag(slider, const Offset(50, 0));
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          // Update IoT device state to simulate real-time response
          await iotDevice.updateState('duration', 20);
        }
        
        // ===== 7. SIMULATE DEVICE SENDING DATA =====
        safePrint('STEP 7: Simulating Device Data Updates');
        
        // Simulate device sending new soil moisture data
        await iotDevice.updateState('soilMoisture', 75);
        
        // Wait for MQTT message to be processed
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // ===== 8. NAVIGATE BACK TO HOME =====
        safePrint('STEP 8: Navigating Back to Home Screen');
        
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      } else {
        safePrint('No devices found in the list, skipping device interaction tests');
      }
      
      // ===== 9. SIGN OUT =====
      safePrint('STEP 9: Testing Sign Out Flow');
      
      await tester.tap(find.byIcon(Icons.account_circle));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify we're back at login screen
      expect(find.text('Login'), findsOneWidget, reason: 'Not returned to login screen after sign out');
    });
  });
}