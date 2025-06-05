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
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.debug, message);
  }

  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.info, message);
  }

  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.warning, message);
  }

  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.error, message);
  }
}

/// Log an info message
void logInfo(String message) {
  getLogger('App').i(message);
}

/// Log a warning message
void logWarning(String message, [dynamic error]) {
  getLogger('App').w(message);
}

/// Log an error message
void logError(String message, [dynamic error, StackTrace? stackTrace]) {
  getLogger('App').e(message);
}

/// Log a debug message
void logDebug(String message) {
  getLogger('App').d(message);
}