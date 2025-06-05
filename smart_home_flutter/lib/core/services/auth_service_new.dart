import 'dart:async';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final _log = getLogger('AuthService');
  final _authStateController = StreamController<bool>.broadcast();

  Stream<bool> get onAuthStateChanged => _authStateController.stream;

  AuthService() {
    // Listen to auth hub events
    Amplify.Hub.listen(HubChannel.Auth, (hubEvent) {
      final event = hubEvent.payload;
      if (event is AuthHubEvent) {
        final authEvent = event as AuthHubEvent;
        switch (authEvent.type) {
          case AuthHubEventType.signedIn:
            _authStateController.add(true);
            break;
          case AuthHubEventType.signedOut:
            _authStateController.add(false);
            break;
          default:
            break;
        }
      }
    });

    // Initialize auth state
    isSignedIn().then((signedIn) {
      _authStateController.add(signedIn);
    });
  }

  /// Gets the current authenticated user
  Future<AuthUser?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user;
    } catch (e) {
      _log.i('No authenticated user');
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

      _log.i('Sign in successful: ${result.isSignedIn}');
      return result;
    } on AuthException catch (e) {
      _log.e('Sign in failed');
      rethrow;
    }
  }

  /// Signs up a new user
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final options = SignUpOptions(
        userAttributes: {AuthUserAttributeKey.email: email},
      );

      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: options,
      );

      _log.i('Sign up successful: ${result.isSignUpComplete}');
      return result;
    } on AuthException catch (e) {
      _log.e('Sign up failed');
      rethrow;
    }
  }

  /// Confirms sign up with verification code
  Future<SignUpResult> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );

      _log.i('Confirm sign up successful: ${result.isSignUpComplete}');
      return result;
    } on AuthException catch (e) {
      _log.e('Confirm sign up failed');
      rethrow;
    }
  }

  /// Resends the sign up code
  Future<ResendSignUpCodeResult> resendSignUpCode({
    required String email,
  }) async {
    try {
      final result = await Amplify.Auth.resendSignUpCode(username: email);
      _log.i('Resend code successful');
      return result;
    } on AuthException catch (e) {
      _log.e('Resend code failed');
      rethrow;
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      _log.i('Sign out successful');
    } on AuthException catch (e) {
      _log.e('Sign out failed');
      rethrow;
    }
  }

  /// Checks if a user is currently signed in
  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } on AuthException catch (e) {
      _log.e('Failed to check sign in status');
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _authStateController.close();
  }
}