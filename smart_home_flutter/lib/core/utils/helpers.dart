import 'package:intl/intl.dart';

class Formatters {
  static String formatDateTime(DateTime dateTime) {
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }

  static String formatNumber(num value, {int decimals = 1}) {
    return NumberFormat.decimalPattern().format(
      double.parse(value.toStringAsFixed(decimals)),
    );
  }

  static String formatPowerValue(num value) {
    if (value >= 1000) {
      return '${formatNumber(value / 1000)} kW';
    }
    return '${formatNumber(value)} W';
  }

  static String getDeviceStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
      case 'error':
        return 'Error';
      default:
        return 'Unknown';
    }
  }
}

class UiHelper {
  static Map<String, dynamic> processTemplateValues(
    Map<String, dynamic> properties,
    Map<String, dynamic> data,
  ) {
    final processed = <String, dynamic>{};

    properties.forEach((key, value) {
      if (value is String && value.startsWith('\${') && value.endsWith('}')) {
        // Extract path from ${device.status} format
        final path = value.substring(2, value.length - 1).split('.');
        var current = data;

        // Navigate through the path
        for (final segment in path) {
          if (current.containsKey(segment)) {
            current = current[segment];
          } else {
            current = null;
            break;
          }
        }

        processed[key] = current;
      } else if (value is Map<String, dynamic>) {
        processed[key] = processTemplateValues(value, data);
      } else {
        processed[key] = value;
      }
    });

    return processed;
  }

  static Map<String, String> getDeviceTypeColors(String type) {
    switch (type.toLowerCase()) {
      case 'energy-meter':
        return {'primary': '#4CAF50', 'secondary': '#81C784'};
      case 'relay':
        return {'primary': '#2196F3', 'secondary': '#64B5F6'};
      case 'sensor':
        return {'primary': '#FF9800', 'secondary': '#FFB74D'};
      default:
        return {'primary': '#9E9E9E', 'secondary': '#E0E0E0'};
    }
  }
}

class Logger {
  static void debug(String message) {
    print('DEBUG: $message');
  }

  static void info(String message) {
    print('INFO: $message');
  }

  static void warning(String message) {
    print('WARNING: $message');
  }

  static void error(String message, [dynamic error]) {
    print('ERROR: $message');
    if (error != null) {
      print('Error details: $error');
    }
  }
}
