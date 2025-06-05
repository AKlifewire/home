@echo off
REM Full stack test script for both backend and Flutter app

echo === Testing Backend Services ===
call test-e2e.bat

echo === Testing Flutter App ===
cd smart_home_flutter
flutter test test/widget_test.dart

echo === Running Integration Tests ===
REM Note: This requires a connected device or emulator
flutter test integration_test/backend_integration_test.dart -d chrome

echo === Testing Complete ===