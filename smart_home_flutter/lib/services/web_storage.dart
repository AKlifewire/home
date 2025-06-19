// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'storage_interface.dart';

class WebStorage implements StorageInterface {
  @override
  Future<void> saveValue(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<String?> getValue(String key) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> deleteValue(String key) async {
    html.window.localStorage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    html.window.localStorage.clear();
  }
}
