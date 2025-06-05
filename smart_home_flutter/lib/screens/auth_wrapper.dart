import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../core/utils/logger.dart';
import 'auth/signin_screen.dart';
import 'landing_page.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  final _log = getLogger('AuthWrapper');
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    
    // Listen for auth state changes
    final authService = ref.read(authServiceProvider);
    authService.onAuthStateChanged.listen((isAuthenticated) {
      setState(() {
        _isAuthenticated = isAuthenticated;
        _isLoading = false;
      });
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();
      setState(() {
        _isAuthenticated = user != null;
        _isLoading = false;
      });
    } catch (e) {
      _log.e('Error checking auth status: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isAuthenticated ? const LandingPage() : const SignInScreen();
  }
}