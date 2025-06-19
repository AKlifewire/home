import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_home_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test credentials - use environment variables in CI/CD
  const testEmail = 'test_user1@example.com';
  const testPassword = 'Test@123456';
  const testUsername = 'TestUser1';

  group('End-to-End Smart Home App Test', () {
    testWidgets('Complete user journey with device interaction', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ===== 1. SIGN UP FLOW =====
      print('STEP 1: Testing Sign Up Flow');
      
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
      print('STEP 2: Testing Sign In Flow');
      
      // Enter login credentials
      await tester.enterText(find.byType(TextFormField).at(0), testEmail);
      await tester.enterText(find.byType(TextFormField).at(1), testPassword);
      
      // Submit login form
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // ===== 3. VERIFY HOME SCREEN AND DEVICE LIST =====
      print('STEP 3: Verifying Home Screen and Device List');
      
      // Check if we're on the home screen
      expect(find.text('My Devices'), findsOneWidget, reason: 'Home screen not loaded');
      
      // Wait for devices to load
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // ===== 4. TAP ON THE DEVICE =====
      print('STEP 4: Selecting Device from List');
      
      // Find a device card - this might need to be adjusted based on your actual UI
      final deviceCard = find.byType(Card).first;
      expect(deviceCard, findsOneWidget, reason: 'No device cards found');
      await tester.tap(deviceCard);
      await tester.pumpAndSettle();
      
      // ===== 5. VERIFY DEVICE DETAIL SCREEN =====
      print('STEP 5: Verifying Device Detail Screen');
      
      // Check if we're on the device detail screen
      // This might need to be adjusted based on your actual UI
      expect(find.byType(AppBar), findsOneWidget);
      
      // ===== 6. INTERACT WITH DEVICE CONTROLS =====
      print('STEP 6: Testing Device Control Interaction');
      
      // Find and interact with controls - this will depend on your specific UI
      // For example, if there's a switch:
      final switchWidget = find.byType(Switch);
      if (switchWidget.evaluate().isNotEmpty) {
        await tester.tap(switchWidget.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        print('Toggled switch control');
      }
      
      // If there's a slider:
      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        print('Adjusted slider control');
      }
      
      // ===== 7. WAIT FOR DEVICE UPDATES =====
      print('STEP 7: Waiting for Device Updates');
      
      // Wait for any updates to be processed
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // ===== 8. NAVIGATE BACK TO HOME =====
      print('STEP 8: Navigating Back to Home Screen');
      
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      
      // ===== 9. SIGN OUT =====
      print('STEP 9: Testing Sign Out Flow');
      
      // Find and tap the account icon
      final accountIcon = find.byIcon(Icons.account_circle);
      expect(accountIcon, findsOneWidget, reason: 'Account icon not found');
      await tester.tap(accountIcon);
      await tester.pumpAndSettle();
      
      // Find and tap the sign out button
      final signOutButton = find.text('Sign Out');
      expect(signOutButton, findsOneWidget, reason: 'Sign Out button not found');
      await tester.tap(signOutButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify we're back at login screen
      expect(find.text('Login'), findsOneWidget, reason: 'Not returned to login screen after sign out');
      
      print('End-to-End test completed successfully!');
    });
  });
}