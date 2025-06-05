import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:smart_home_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Backend Integration Tests', () {
    setUpAll(() async {
      // Initialize the app
      app.main();
      await Future.delayed(Duration(seconds: 2));
    });

    testWidgets('Authentication and device fetching flow', (tester) async {
      // Sign in with test credentials
      final signInResult = await Amplify.Auth.signIn(
        username: 'test@example.com',
        password: 'Test123!',
      );
      expect(signInResult.isSignedIn, true);
      
      // Get devices via GraphQL
      final request = GraphQLRequest<String>(
        document: '''
          query GetMyDevices {
            getMyDevices {
              id
              name
              type
              location
              status
            }
          }
        ''',
      );
      
      final response = await Amplify.API.query(request: request).response;
      expect(response.errors.isEmpty, true);
      
      // Verify we have device data
      final data = response.data;
      expect(data, isNotNull);
      
      // Print for debugging
      print('Devices: $data');
      
      // Parse the response
      final jsonData = jsonDecode(data!);
      final devices = jsonData['getMyDevices'];
      expect(devices, isNotNull);
      expect(devices.length, greaterThan(0));
    });
    
    testWidgets('Get UI JSON for device', (tester) async {
      // First get a device ID
      final devicesRequest = GraphQLRequest<String>(
        document: '''
          query GetMyDevices {
            getMyDevices {
              id
            }
          }
        ''',
      );
      
      final devicesResponse = await Amplify.API.query(request: devicesRequest).response;
      final devicesData = jsonDecode(devicesResponse.data!);
      final deviceId = devicesData['getMyDevices'][0]['id'];
      
      // Get UI JSON for the device
      final uiJsonRequest = GraphQLRequest<String>(
        document: '''
          query GetUiJson(\$deviceId: String!) {
            getUiJson(deviceId: \$deviceId) {
              statusCode
              deviceId
              uiJson
            }
          }
        ''',
        variables: {
          'deviceId': deviceId
        },
      );
      
      final uiJsonResponse = await Amplify.API.query(request: uiJsonRequest).response;
      expect(uiJsonResponse.errors.isEmpty, true);
      
      final uiJsonData = jsonDecode(uiJsonResponse.data!);
      expect(uiJsonData['getUiJson']['statusCode'], 200);
      expect(uiJsonData['getUiJson']['deviceId'], deviceId);
      
      final uiJson = jsonDecode(uiJsonData['getUiJson']['uiJson']);
      expect(uiJson['components'], isNotNull);
      expect(uiJson['components'].length, greaterThan(0));
      
      print('UI JSON: ${jsonEncode(uiJson)}');
    });
  });
}