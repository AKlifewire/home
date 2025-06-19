import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Basic UI Test', () {
    testWidgets('Verify basic UI elements', (WidgetTester tester) async {
      // Create a simple test app
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Smart Home Test'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Welcome to Smart Home'),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Wait for the UI to settle
      await tester.pumpAndSettle();

      // Verify UI elements
      expect(find.text('Smart Home Test'), findsOneWidget);
      expect(find.text('Welcome to Smart Home'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);

      // Test form interaction
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      
      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
      
      // Tap the login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Tap the sign up button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      
      // Test passed if we got here without errors
    });
  });
}