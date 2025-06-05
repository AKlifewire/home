import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:convert';
import 'dart:io';

import 'helpers/test_runner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Device Config E2E Tests', () {
    final username = 'testuser@example.com';
    final password = 'TestPassword123';

    final configFiles = [
      'test_configs/test-relay.json',
      'test_configs/test-sensor.json',
      'test_configs/test-chart.json',
    ];

    for (final path in configFiles) {
      testWidgets('Run test config: $path', (tester) async {
        final raw = await File(path).readAsString();
        final config = json.decode(raw);
        await runDeviceFlowTest(
          tester: tester,
          username: username,
          password: password,
          testConfig: config,
        );
      });
    }
  });
}