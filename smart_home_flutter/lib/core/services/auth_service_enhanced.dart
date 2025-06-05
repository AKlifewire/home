import 'dart:async';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

final authServiceProvider = Provider((ref) => AuthServiceEnhanced());

class AuthServiceEnhanced {
  final _log = getLogger('AuthService');
  final _authStateController = StreamController<AuthState>.broadcast();

  Stream<AuthState> get onAuthStateChanged => _authStateController.stream;
  
  AuthServiceEnhanced() {
    // Listen to auth hub events
    Amplify.Hub.listen(HubChannel.Auth, (event) {
      final eventName = event.eventName;
      switch (eventName) {
        case 'SIGNED_IN':
          _authStateController.add(AuthState.signedIn);
          break;
        case 'SIGNED_OUT':
          _authStateController.add(AuthState.signedOut);
          break;
        case 'SESSION_EXPIRED':
          _authStateController.add(AuthState.needsLogin);
          break;
      }
    });
    
    // Check initial auth state
    _checkInitialAuthState();
  }
  
  Future<void> _checkInitialAuthState() async {
    try {
      await Amplify.Auth.getCurrentUser();
      _authStateController.add(AuthState.signedIn);
    } catch (e) {
      _authStateController.add(AuthState.signedOut);
    }
  }

  /// Gets the current authenticated user
  Future<AuthUser?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user;
    } catch (e) {
      _log.w('No authenticated user');
      return null;
    }
  }

  /// Gets the current authenticated user ID
  Future<String?> getCurrentUserId() async {
    try {
      final user = await getCurrentUser();
      return user?.userId;
    } catch (e) {
      _log.e('Failed to get user ID');
      return null;
    }
  }

  /// Gets the current user's attributes
  Future<Map<AuthUserAttributeKey, String>> getUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final attributeMap = <AuthUserAttributeKey, String>{};
      
      for (final attribute in attributes) {
        attributeMap[attribute.userAttributeKey] = attribute.value;
      }
      
      return attributeMap;
    } catch (e) {
      _log.e('Failed to get user attributes: $e');
      return {};
    }
  }

  /// Signs in a user with email and password
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      if (result.isSignedIn) {
        _authStateController.add(AuthState.signedIn);
      }
      return result;
    } on NotAuthorizedException catch (e) {
      _log.e('Invalid credentials: $e');
      throw AuthException(
        message: 'Invalid email or password',
        recoverySuggestion: 'Please check your email and password and try again',
      );
    } on UserNotConfirmedException catch (e) {
      _log.e('User not confirmed: $e');
      _authStateController.add(AuthState.needsConfirmation);
      throw AuthException(
        message: 'Account not confirmed',
        recoverySuggestion: 'Please check your email for a confirmation code',
      );
    } catch (e) {
      _log.e('Error signing in: $e');
      throw AuthException(
        message: 'Failed to sign in',
        recoverySuggestion: 'Please try again later',
      );
    }
  }

  /// Signs up a new user with email and password
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    Map<AuthUserAttributeKey, String>? additionalAttributes,
  }) async {
    try {
      final userAttributes = {AuthUserAttributeKey.email: email};
      
      // Add any additional attributes if provided
      if (additionalAttributes != null) {
        userAttributes.addAll(additionalAttributes);
      }
      
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: userAttributes,
        ),
      );
      
      if (!result.isSignUpComplete) {
        _authStateController.add(AuthState.needsConfirmation);
      }
      
      return result;
    } on UsernameExistsException catch (e) {
      _log.e('Username exists: $e');
      throw AuthException(
        message: 'An account with this email already exists',
        recoverySuggestion: 'Try signing in or use a different email',
      );
    } on InvalidPasswordException catch (e) {
      _log.e('Invalid password: $e');
      throw AuthException(
        message: 'Password does not meet requirements',
        recoverySuggestion: 'Password must be at least 8 characters and include uppercase, lowercase, numbers, and special characters',
      );
    } catch (e) {
      _log.e('Error signing up: $e');
      throw AuthException(
        message: 'Failed to sign up',
        recoverySuggestion: 'Please try again later',
      );
    }
  }

  /// Confirms a user's signup with confirmation code
  Future<void> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );
      
      if (result.isSignUpComplete) {
        _authStateController.add(AuthState.needsLogin);
      }
    } on CodeMismatchException catch (e) {
      _log.e('Code mismatch: $e');
      throw AuthException(
        message: 'Invalid confirmation code',
        recoverySuggestion: 'Please check the code and try again',
      );
    } on ExpiredCodeException catch (e) {
      _log.e('Expired code: $e');
      throw AuthException(
        message: 'Confirmation code has expired',
        recoverySuggestion: 'Please request a new code',
      );
    } catch (e) {
      _log.e('Error confirming sign up: $e');
      throw AuthException(
        message: 'Failed to confirm sign up',
        recoverySuggestion: 'Please try again later',
      );
    }
  }

  /// Resends the sign up code to the user's email
  Future<void> resendSignUpCode({
    required String email,
  }) async {
    try {
      await Amplify.Auth.resendSignUpCode(
        username: email,
      );
    } catch (e) {
      _log.e('Error resending sign up code: $e');
      throw AuthException(
        message: 'Failed to resend verification code',
        recoverySuggestion: 'Please try again later',
      );
    }
  }

  /// Initiates the forgot password flow
  Future<void> forgotPassword({
    required String email,
  }) async {
    try {
      await Amplify.Auth.resetPassword(
        username: email,
      );
      _authStateController.add(AuthState.resetPassword);
    } catch (e) {
      _log.e('Error initiating password reset: $e');
      throw AuthException(
        message: 'Failed to initiate password reset',
        recoverySuggestion: 'Please try again later',
      );
    }
  }

  /// Confirms the new password with the confirmation code
  Future<void> confirmForgotPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
      _authStateController.add(AuthState.needsLogin);
    } on CodeMismatchException catch (e) {
      _log.e('Code mismatch: $e');
      throw AuthException(
        message: 'Invalid confirmation code',
        recoverySuggestion: 'Please check the code and try again',
      );
    } on InvalidPasswordException catch (e) {
      _log.e('Invalid password: $e');
      throw AuthException(
        message: 'Password does not meet requirements',
        recoverySuggestion: 'Password must be at least 8 characters and include uppercase, lowercase, numbers, and special characters',
      );
    } catch (e) {
      _log.e('Error confirming password reset: $e');
      throw AuthException(
        message: 'Failed to confirm password reset',
        recoverySuggestion: 'Please try again later',
      );
    }
  }

  /// Changes the password for an authenticated user
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await Amplify.Auth.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } on NotAuthorizedException catch (e) {
      _log.e('Not authorized: $e');
      throw AuthException(
        message: 'Current password is incorrect',
        recoverySuggestion: 'Please check your current password and try again',
      );
    } on InvalidPasswordException catch (e) {
      _log.e('Invalid password: $e');
      throw AuthException(
        message: 'New password does not meet requirements',
        recoverySuggestion: 'Password must be at least 8 characters and include uppercase, lowercase, numbers, and special characters',
      );
    } catch (e) {
      _log.e('Error changing password: $e');
      throw AuthException(
        message: 'Failed to change password',
        recoverySuggestion: 'Please try again later',
      );
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      _authStateController.add(AuthState.signedOut);
    } catch (e) {
      _log.e('Error signing out: $e');
      throw AuthException(
        message: 'Failed to sign out',
        recoverySuggestion: 'Please try again later',
      );
    }
  }

  /// Gets the current auth session
  Future<AuthSession> getSession() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session;
    } catch (e) {
      _log.e('Error getting session: $e');
      throw AuthException(
        message: 'Failed to get auth session',
        recoverySuggestion: 'Please try signing in again',
      );
    }
  }

  /// Gets the current ID token
  Future<String?> getIdToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(getAWSCredentials: true),
      ) as CognitoAuthSession;
      
      return session.userPoolTokens?.idToken;
    } catch (e) {
      _log.e('Error getting ID token: $e');
      return null;
    }
  }

  /// Disposes of the auth service
  void dispose() {
    _authStateController.close();
  }
}

/// Enum representing the different authentication states
enum AuthState {
  signedOut,
  signedIn,
  needsConfirmation,
  needsLogin,
  resetPassword,
}

/// Custom auth exception
class AuthException implements Exception {
  final String message;
  final String recoverySuggestion;
  
  AuthException({
    required this.message,
    required this.recoverySuggestion,
  });
  
  @override
  String toString() => '$message: $recoverySuggestion';
}