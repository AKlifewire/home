import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'config/amplifyconfiguration.dart';
import 'screens/auth_wrapper.dart';
import 'theme/app_theme.dart';
import 'core/services/mqtt_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app
  runApp(
    const ProviderScope(
      child: SmartHomeApp(),
    ),
  );
}

class SmartHomeApp extends ConsumerStatefulWidget {
  const SmartHomeApp({Key? key}) : super(key: key);

  @override
  ConsumerState<SmartHomeApp> createState() => _SmartHomeAppState();
}

class _SmartHomeAppState extends ConsumerState<SmartHomeApp> {
  bool _isAmplifyConfigured = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      // Configure Amplify plugins
      final auth = AmplifyAuthCognito();
      final api = AmplifyAPI();
      final storage = AmplifyStorageS3();
      
      await Amplify.addPlugins([auth, api, storage]);
      await Amplify.configure(amplifyconfig);
      
      // Initialize MQTT service after authentication
      await _initializeMqttService();
      
      setState(() {
        _isAmplifyConfigured = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to configure Amplify: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeMqttService() async {
    try {
      final mqttService = ref.read(mqttServiceProvider);
      
      // Get current auth session
      final session = await Amplify.Auth.fetchAuthSession();
      
      if (session.isSignedIn) {
        // Get IoT credentials from Cognito
        final credentials = await Amplify.Auth.fetchAuthSession(
          options: const FetchAuthSessionOptions(forceRefresh: true),
        ) as CognitoAuthSession;
        
        // Get IoT endpoint from API
        final request = RestOptions(
          path: '/iot/endpoint',
          apiName: 'SmartHomeApi',
        );
        
        final response = await Amplify.API.rest(request);
        final endpoint = response.body;
        
        // Initialize MQTT service
        await mqttService.initialize(
          host: endpoint,
          port: 8883,
          clientId: credentials.userPoolTokens?.idToken ?? 'anonymous',
          useTls: true,
        );
      }
    } catch (e) {
      print('Failed to initialize MQTT service: $e');
      // Don't block app startup if MQTT fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _isLoading
          ? const _LoadingScreen()
          : _error != null
              ? _ErrorScreen(error: _error!)
              : const AuthWrapper(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing app...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(error),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SmartHomeApp(),
                    ),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}