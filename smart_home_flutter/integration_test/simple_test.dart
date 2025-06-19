import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_home_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Home App Test', () {
    testWidgets('Login screen test', (WidgetTester tester) async {
      // Start the app
      app.main();
      
      // Wait for app to load
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Verify login screen appears
      expect(find.text('Login'), findsOneWidget);
      
      // Find email and password fields
      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      
      // Enter test credentials
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'Password123!');
      
      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
      
      // Find and tap Sign Up button to navigate to sign up screen
      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget);
      await tester.tap(signUpButton);
      
      // Wait for navigation
      await tester.pumpAndSettle();
      
      // Verify we're on the sign up screen
      expect(find.text('Create Account'), findsOneWidget);
    });
  });
}