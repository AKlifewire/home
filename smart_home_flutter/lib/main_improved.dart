import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'config/amplifyconfiguration.dart';
import 'config/env_config.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home_screen_improved.dart';
import 'theme/app_theme.dart';

void main() {
  // Catch any uncaught errors in the Flutter framework
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // In production, log to a service like Sentry or Firebase Crashlytics
      print('Uncaught error: ${details.exception}');
    }
  };

  // Catch any errors not caught by the Flutter framework
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set environment based on compile-time constants or environment variables
    final String envName = const String.fromEnvironment('ENV_NAME', defaultValue: 'dev');
    EnvConfig.initFromString(envName);
    
    // Configure Amplify
    await configureAmplify();
    
    runApp(const MyApp());
  }, (error, stackTrace) {
    // Log any errors not caught by the Flutter framework
    print('Uncaught error: $error');
    print('Stack trace: $stackTrace');
  });
}

Future<void> configureAmplify() async {
  try {
    final auth = AmplifyAuthCognito();
    final api = AmplifyAPI();
    
    await Amplify.addPlugins([auth, api]);
    await Amplify.configure(amplifyConfig);
    
    print('Amplify configured successfully');
  } catch (e) {
    print('Error configuring Amplify: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isSignedIn = false;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    
    // Listen for auth events
    Amplify.Hub.listen(HubChannel.Auth, (event) {
      switch (event.eventName) {
        case 'SIGNED_IN':
          setState(() {
            _isSignedIn = true;
          });
          break;
        case 'SIGNED_OUT':
          setState(() {
            _isSignedIn = false;
          });
          break;
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      await Amplify.Auth.getCurrentUser();
      setState(() {
        _isSignedIn = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSignedIn = false;
        _isLoading = false;
      });
    }
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: _isLoading
          ? const _LoadingScreen()
          : _isSignedIn
              ? HomeScreen(onThemeToggle: _toggleTheme)
              : const AuthScreen(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.home, size: 80, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text('Loading your smart home...'),
          ],
        ),
      ),
    );
  }
}