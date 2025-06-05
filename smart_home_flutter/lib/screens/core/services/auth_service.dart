import 'dart:async';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/logger.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final _log = getLogger('AuthService');
  final _auth = Amplify.Auth;
  final _authStateController = StreamController<bool>.broadcast();

  Stream<bool> get onAuthStateChanged => _authStateController.stream;

  AuthService() {
    // Listen to auth hub events
    Amplify.Hub.listen(HubChannel.Auth, (hubEvent) {
      switch (hubEvent.payload.toString()) {
        case 'SIGNED_IN':
          _authStateController.add(true);
          break;
        case 'SIGNED_OUT':
          _authStateController.add(false);
          break;
      }
    });
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
        _authStateController.add(true);
      }
      return result;
    } catch (e) {
      _log.e('Error signing in: $e');
      rethrow;
    }
  }

  /// Signs up a new user with email and password
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {AuthUserAttributeKey.email: email},
        ),
      );
      return result;
    } catch (e) {
      _log.e('Error signing up: $e');
      rethrow;
    }
  }

  /// Confirms a user's signup with confirmation code
  Future<void> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );
    } catch (e) {
      _log.e('Error confirming sign up: $e');
      throw Exception('Error confirming sign up');
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
      throw Exception('Error resending verification code');
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
    } catch (e) {
      _log.e('Error initiating password reset: $e');
      throw Exception('Error initiating password reset');
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
    } catch (e) {
      _log.e('Error confirming password reset: $e');
      throw Exception('Error confirming password reset');
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
    } catch (e) {
      _log.e('Error changing password: $e');
      throw Exception('Error changing password');
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      _authStateController.add(false);
    } catch (e) {
      _log.e('Error signing out: $e');
      throw Exception('Error signing out');
    }
  }

  /// Disposes of the auth service
  void dispose() {
    _authStateController.close();
  }
}
