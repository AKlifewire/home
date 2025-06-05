import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:amplify_api/amplify_api.dart';
import '../lib/screens/add_device/add_device_screen.dart';

// Generate mock classes
@GenerateMocks([AmplifyAPI])
import 'device_registration_test.mocks.dart';

void main() {
  late MockAmplifyAPI mockAmplifyAPI;

  setUp(() {
    mockAmplifyAPI = MockAmplifyAPI();
  });

  group('AddDeviceScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: AddDeviceScreen(),
        ),
      );

      // Verify that the form fields are displayed
      expect(find.text('Device ID'), findsOneWidget);
      expect(find.text('Device Name'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Register Device'), findsOneWidget);
      expect(find.text('Scan QR Code'), findsOneWidget);
    });

    testWidgets('validates form fields', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: AddDeviceScreen(),
        ),
      );

      // Tap the register button without filling the form
      await tester.tap(find.text('Register Device'));
      await tester.pump();

      // Verify validation errors are shown
      expect(find.text('Please enter a device ID'), findsOneWidget);
      expect(find.text('Please enter a device name'), findsOneWidget);
      expect(find.text('Please enter a location'), findsOneWidget);
    });

    // This test would require mocking Amplify API calls
    // We'll just outline it here
    testWidgets('submits form successfully', (WidgetTester tester) async {
      // TODO: Implement with proper mocking of Amplify API
      // This would involve:
      // 1. Setting up mock responses for API calls
      // 2. Filling out the form
      // 3. Submitting the form
      // 4. Verifying the API was called with correct parameters
      // 5. Verifying success message is shown
    });
  });
}