import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:smart_home_flutter/test_helpers/test_device_creator.dart';

/// Helper class to set up the test environment
class TestEnvironmentSetup {
  /// Creates a test user in Cognito
  static Future<void> createTestUser(String email, String password, String username) async {
    try {
      // Check if user already exists
      try {
        final result = await Amplify.Auth.signIn(
          username: email,
          password: password,
        );
        
        if (result.isSignedIn) {
          safePrint('Test user already exists and can sign in');
          await Amplify.Auth.signOut();
          return;
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
      } else {
        safePrint('User creation requires confirmation');
        
        // In a real test environment, you would need to auto-confirm the user
        // This typically requires admin privileges or a custom Lambda function
      }
    } catch (e) {
      safePrint('Error creating test user: $e');
      rethrow;
    }
  }
  
  /// Sets up the entire test environment
  static Future<String> setupTestEnvironment(String email, String password, String username) async {
    try {
      // Create test user
      await createTestUser(email, password, username);
      
      // Sign in as the test user
      final signInResult = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      
      if (!signInResult.isSignedIn) {
        throw Exception('Failed to sign in as test user');
      }
      
      // Create test device
      final deviceId = await TestDeviceCreator.createTestDevice();
      
      // Sign out
      await Amplify.Auth.signOut();
      
      return deviceId;
    } catch (e) {
      safePrint('Error setting up test environment: $e');
      rethrow;
    }
  }
  
  /// Tears down the test environment
  static Future<void> tearDownTestEnvironment(String deviceId) async {
    try {
      // Sign in as admin or with sufficient permissions
      // This would typically be done with admin credentials
      
      // Delete test device
      await TestDeviceCreator.deleteTestDevice(deviceId);
      
      // In a real test environment, you would also delete the test user
      // This typically requires admin privileges
      
    } catch (e) {
      safePrint('Error tearing down test environment: $e');
      rethrow;
    }
  }
}