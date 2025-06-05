import 'package:logger/logger.dart';

/// Global logger instance with custom configuration
final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
  level: Level.debug,
);

/// Returns a logger instance with the specified tag
Logger getLogger(String tag) {
  return _logger;
}

/// Extension methods for Logger to match the logging interface
extension LoggerExtension on Logger {
  void d(dynamic message) {
    log(Level.debug, message);
  }

  void i(dynamic message) {
    log(Level.info, message);
  }

  void w(dynamic message) {
    log(Level.warning, message);
  }

  void e(dynamic message) {
    log(Level.error, message);
  }
}