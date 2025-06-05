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
);

/// Returns a logger instance with the specified tag
Logger getLogger(String tag) {
  return _logger;
}
