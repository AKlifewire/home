import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Import all test files
import 'dynamic_ui_test.dart' as dynamic_ui_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('All Integration Tests', () {
    dynamic_ui_test.main();
  });
}