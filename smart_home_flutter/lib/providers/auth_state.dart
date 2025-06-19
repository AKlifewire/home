import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Auth state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? userId;
  final String? username;
  final String? email;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.userId,
    this.username,
    this.email,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userId,
    String? username,
    String? email,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      error: error,  // Null if not provided
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState(isLoading: true)) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final isSignedIn = await _authService.isSignedIn();
      
      if (isSignedIn) {
        await _fetchUserAttributes();
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: 'Failed to check authentication status',
      );
    }
  }

  Future<void> _fetchUserAttributes() async {
    try {
      final attributes = await _authService.getCurrentUserAttributes();
      final userId = attributes['sub'];
      final email = attributes['email'];
      final username = attributes['preferred_username'] ?? email;
      
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        userId: userId,
        username: username,
        email: email,
      );
    } catch (e) {
      debugPrint('Error fetching user attributes: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch user details',
      );
    }
  }

  Future<bool> signIn(String username, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final isSignedIn = await _authService.signIn(username, password);
      
      if (isSignedIn) {
        await _fetchUserAttributes();
        return true;
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: 'Failed to sign in: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String username) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final result = await _authService.signUp(email, password, username);
      
      state = state.copyWith(isLoading: false);
      return result.isSignUpComplete;
    } catch (e) {
      debugPrint('Error signing up: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign up: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> confirmSignUp(String email, String confirmationCode) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final result = await _authService.confirmSignUp(email, confirmationCode);
      
      state = state.copyWith(isLoading: false);
      return result.isSignUpComplete;
    } catch (e) {
      debugPrint('Error confirming sign up: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to confirm sign up: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _authService.signOut();
      
      state = AuthState(isLoading: false);
    } catch (e) {
      debugPrint('Error signing out: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign out: ${e.toString()}',
      );
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _authService.resetPassword(email);
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reset password: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> confirmResetPassword(
    String email,
    String newPassword,
    String confirmationCode,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _authService.confirmResetPassword(
        email,
        newPassword,
        confirmationCode,
      );
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Error confirming password reset: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to confirm password reset: ${e.toString()}',
      );
      return false;
    }
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});