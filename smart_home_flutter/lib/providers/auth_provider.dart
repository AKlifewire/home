import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class MyAuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _userId;
  String? _username;
  String? _email;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  String? get username => _username;
  String? get email => _email;

  MyAuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      _isAuthenticated = session.isSignedIn;
      
      if (_isAuthenticated) {
        await _fetchUserAttributes();
      }
    } catch (e) {
      safePrint('Error checking auth status: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      for (final attribute in attributes) {
        if (attribute.userAttributeKey.key == 'sub') {
          _userId = attribute.value;
        } else if (attribute.userAttributeKey.key == 'email') {
          _email = attribute.value;
        } else if (attribute.userAttributeKey.key == 'preferred_username') {
          _username = attribute.value;
        }
      }
      
      // If no username is set, use email as fallback
      _username ??= _email;
    } catch (e) {
      safePrint('Error fetching user attributes: $e');
    }
  }

  Future<bool> signIn(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await Amplify.Auth.signIn(
        username: username,
        password: password,
      );
      
      _isAuthenticated = result.isSignedIn;
      
      if (_isAuthenticated) {
        await _fetchUserAttributes();
      }
      
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      safePrint('Error signing in: $e');
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String username) async {
    try {
      _isLoading = true;
      notifyListeners();
      
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
      
      _isLoading = false;
      notifyListeners();
      return result.isSignUpComplete;
    } catch (e) {
      safePrint('Error signing up: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> confirmSignUp(String email, String confirmationCode) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );
      
      _isLoading = false;
      notifyListeners();
      return result.isSignUpComplete;
    } catch (e) {
      safePrint('Error confirming sign up: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await Amplify.Auth.signOut();
      
      _isAuthenticated = false;
      _userId = null;
      _username = null;
      _email = null;
    } catch (e) {
      safePrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await Amplify.Auth.resetPassword(username: email);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      safePrint('Error resetting password: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> confirmResetPassword(
    String email,
    String newPassword,
    String confirmationCode,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      safePrint('Error confirming password reset: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}