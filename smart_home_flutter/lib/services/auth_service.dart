import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class AuthService {
  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      
      return result.isSignedIn;
    } catch (e) {
      safePrint('Error signing in: $e');
      rethrow;
    }
  }

  // Sign up with email, password, and username
  Future<SignUpResult> signUp(String email, String password, String username) async {
    try {
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
      
      return result;
    } catch (e) {
      safePrint('Error signing up: $e');
      rethrow;
    }
  }

  // Confirm sign up with confirmation code
  Future<SignUpResult> confirmSignUp(String email, String confirmationCode) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );
      
      return result;
    } catch (e) {
      safePrint('Error confirming sign up: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('Error signing out: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await Amplify.Auth.resetPassword(username: email);
    } catch (e) {
      safePrint('Error resetting password: $e');
      rethrow;
    }
  }

  // Confirm reset password
  Future<void> confirmResetPassword(
    String email,
    String newPassword,
    String confirmationCode,
  ) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } catch (e) {
      safePrint('Error confirming password reset: $e');
      rethrow;
    }
  }

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      safePrint('Error checking auth status: $e');
      return false;
    }
  }

  // Get current user attributes
  Future<Map<String, String>> getCurrentUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final Map<String, String> userAttributes = {};
      
      for (final attribute in attributes) {
        userAttributes[attribute.userAttributeKey.key] = attribute.value;
      }
      
      return userAttributes;
    } catch (e) {
      safePrint('Error fetching user attributes: $e');
      return {};
    }
  }

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      for (final attribute in attributes) {
        if (attribute.userAttributeKey.key == 'sub') {
          return attribute.value;
        }
      }
      return null;
    } catch (e) {
      safePrint('Error getting user ID: $e');
      return null;
    }
  }
}