import 'dart:html' as html;

class WebAmplifySecureStorage {
  static Future<void> write(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  static Future<String?> read(String key) async {
    return html.window.localStorage[key];
  }

  static Future<void> delete(String key) async {
    html.window.localStorage.remove(key);
  }

  static Future<void> deleteAll() async {
    html.window.localStorage.clear();
  }
}
