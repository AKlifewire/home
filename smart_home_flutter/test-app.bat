@echo off
echo === Testing Flutter App ===
flutter test test/widget_test.dart
echo === Testing Backend Integration ===
flutter test test/backend_test.dart
echo === Testing Complete ===
