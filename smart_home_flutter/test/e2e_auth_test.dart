import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_home_flutter/main.dart' as app;
import 'package:smart_home_flutter/screens/auth/signin_screen.dart';
import 'package:smart_home_flutter/screens/auth/signup_screen.dart';
import 'package:smart_home_flutter/screens/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Auth Flow Test', () {
    testWidgets('Sign in with valid credentials should navigate to home screen',
        (tester) async {
      // Initialize the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on the auth screen
      expect(find.byType(SignInScreen), findsOneWidget);

      // Enter email and password
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'Password123!');

      // Tap sign in button
      await tester.tap(find.byKey(const Key('sign_in_button')));
      
      // Wait for auth and navigation
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we're on the home screen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Navigate to sign up screen and back', (tester) async {
      // Initialize the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on the auth screen
      expect(find.byType(SignInScreen), findsOneWidget);

      // Tap on sign up link
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Verify we're on the sign up screen
      expect(find.byType(SignUpScreen), findsOneWidget);

      // Go back to sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify we're back on the sign in screen
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('Sign up flow should work correctly', (tester) async {
      // Initialize the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to sign up screen
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Enter registration details
      await tester.enterText(
          find.byKey(const Key('email_field')), 'newuser@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'Password123!');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'Password123!');

      // Tap sign up button
      await tester.tap(find.byKey(const Key('sign_up_button')));
      await tester.pumpAndSettle();

      // Verify we're on the confirmation screen
      expect(find.text('Confirm Sign Up'), findsOneWidget);

      // Enter confirmation code
      await tester.enterText(
          find.byKey(const Key('confirmation_code_field')), '123456');

      // Tap confirm button
      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we're on the sign in screen after confirmation
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });
}