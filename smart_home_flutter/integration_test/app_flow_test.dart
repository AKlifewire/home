import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_home_flutter/main.dart' as app;

/// A simplified integration test that focuses on UI flow without backend connections
/// This test is useful for quick validation of the app's UI flow
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test credentials
  const testEmail = 'test_user1@example.com';
  const testPassword = 'Test@123456';
  const testUsername = 'TestUser1';

  group('App Flow Test', () {
    testWidgets('Basic app navigation flow test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // ===== 1. SIGN UP FLOW =====
      // Find and tap the sign up button on login screen
      await tester.pumpAndSettle();
      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Verify sign up screen
      expect(find.text('Create Account'), findsOneWidget);
      
      // Go back to login
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // ===== 2. SIGN IN FLOW =====
      // Enter login credentials
      await tester.enterText(find.byType(TextFormField).at(0), testEmail);
      await tester.enterText(find.byType(TextFormField).at(1), testPassword);
      
      // Submit login form
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // ===== 3. VERIFY HOME SCREEN =====
      // Check if we're on the home screen (or if we're still on login due to auth failure)
      if (find.text('My Devices').evaluate().isNotEmpty) {
        // We successfully logged in
        expect(find.text('My Devices'), findsOneWidget);
        
        // ===== 4. CHECK PROFILE SCREEN =====
        await tester.tap(find.byIcon(Icons.account_circle));
        await tester.pumpAndSettle();
        
        expect(find.text('Profile'), findsOneWidget);
        
        // Go back to home
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        
        // ===== 5. CHECK DEVICE INTERACTION IF AVAILABLE =====
        final deviceCard = find.text('Smart Irrigation');
        if (deviceCard.evaluate().isNotEmpty) {
          await tester.tap(deviceCard);
          await tester.pumpAndSettle();
          
          // Go back to home
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
        
        // ===== 6. SIGN OUT =====
        await tester.tap(find.byIcon(Icons.account_circle));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();
      }
      
      // Verify we're at login screen (either after sign out or if login failed)
      expect(find.text('Login'), findsOneWidget);
    });
  });
}