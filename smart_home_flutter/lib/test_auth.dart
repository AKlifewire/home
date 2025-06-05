import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/auth_service.dart';
import 'core/utils/logger.dart';
import 'config/amplifyconfiguration.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AuthTestApp()));
}

class AuthTestApp extends StatefulWidget {
  const AuthTestApp({Key? key}) : super(key: key);

  @override
  State<AuthTestApp> createState() => _AuthTestAppState();
}

class _AuthTestAppState extends State<AuthTestApp> {
  final _log = getLogger('AuthTestApp');
  bool _isAmplifyConfigured = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      _log.i('Configuring Amplify');
      
      // Add Amplify plugins
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);

      // Configure Amplify
      await Amplify.configure(amplifyconfig);
      
      setState(() {
        _isAmplifyConfigured = true;
        _statusMessage = 'Amplify configured successfully';
      });
      _log.i('Successfully configured Amplify');
    } catch (e) {
      _log.e('Error configuring Amplify: $e');
      setState(() {
        _statusMessage = 'Error configuring Amplify: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _isAmplifyConfigured 
          ? const AuthTestScreen() 
          : Scaffold(
              appBar: AppBar(title: const Text('Initializing')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(_statusMessage),
                  ],
                ),
              ),
            ),
    );
  }
}

class AuthTestScreen extends ConsumerStatefulWidget {
  const AuthTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends ConsumerState<AuthTestScreen> {
  final _log = getLogger('AuthTestScreen');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isSigningIn = false;
  bool _isSigningUp = false;
  bool _isConfirming = false;
  bool _showConfirmation = false;
  String _statusMessage = '';
  AuthUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();
      setState(() {
        _currentUser = user;
        if (user != null) {
          _statusMessage = 'Logged in as: ${user.username}';
        }
      });
    } catch (e) {
      _log.e('Error checking current user: $e');
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isSigningIn = true;
      _statusMessage = 'Signing in...';
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _isSigningIn = false;
        _statusMessage = 'Sign in successful';
      });
      
      _checkCurrentUser();
    } catch (e) {
      _log.e('Error signing in: $e');
      setState(() {
        _isSigningIn = false;
        _statusMessage = 'Error signing in: $e';
      });
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isSigningUp = true;
      _statusMessage = 'Signing up...';
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _isSigningUp = false;
        _showConfirmation = true;
        _statusMessage = 'Sign up successful. Please confirm your account.';
      });
    } catch (e) {
      _log.e('Error signing up: $e');
      setState(() {
        _isSigningUp = false;
        _statusMessage = 'Error signing up: $e';
      });
    }
  }

  Future<void> _confirmSignUp() async {
    if (_emailController.text.isEmpty || _codeController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter email and confirmation code';
      });
      return;
    }

    setState(() {
      _isConfirming = true;
      _statusMessage = 'Confirming account...';
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.confirmSignUp(
        email: _emailController.text,
        confirmationCode: _codeController.text,
      );

      setState(() {
        _isConfirming = false;
        _showConfirmation = false;
        _statusMessage = 'Account confirmed. You can now sign in.';
      });
    } catch (e) {
      _log.e('Error confirming sign up: $e');
      setState(() {
        _isConfirming = false;
        _statusMessage = 'Error confirming account: $e';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      
      setState(() {
        _currentUser = null;
        _statusMessage = 'Signed out successfully';
      });
    } catch (e) {
      _log.e('Error signing out: $e');
      setState(() {
        _statusMessage = 'Error signing out: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentUser != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User ID: ${_currentUser!.userId}'),
                      Text('Username: ${_currentUser!.username}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _signOut,
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              if (!_showConfirmation) ...[
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSigningIn ? null : _signIn,
                        child: _isSigningIn
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSigningUp ? null : _signUp,
                        child: _isSigningUp
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmation Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isConfirming ? null : _confirmSignUp,
                  child: _isConfirming
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm Account'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showConfirmation = false;
                    });
                  },
                  child: const Text('Back to Sign In'),
                ),
              ],
            ],
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Card(
                color: _statusMessage.contains('Error')
                    ? Colors.red[100]
                    : Colors.green[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_statusMessage),
                ),
              ),
          ],
        ),
      ),
    );
  }
}