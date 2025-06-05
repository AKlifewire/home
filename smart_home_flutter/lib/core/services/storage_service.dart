import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ui_layout.dart';
import '../utils/logger.dart';

/// Service for interacting with AWS S3 storage
class StorageService {
  final _logger = getLogger('StorageService');

  /// Get a file from S3 storage
  Future<String> getFile(String key) async {
    try {
      _logger.i('Fetching file from S3: $key');
      
      // Mock implementation for testing
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Return mock data based on the key
      if (key.contains('device-001')) {
        return '{"title":"Living Room Relay","layout":[{"type":"switch","id":"relay1","name":"Main Power","properties":{"deviceId":"device-001","initialValue":false}}]}';
      } else if (key.contains('device-002')) {
        return '{"title":"Kitchen Sensor","layout":[{"type":"gauge","id":"temperature","name":"Temperature","properties":{"value":22.5,"min":0,"max":40,"unit":"°C"}}]}';
      } else {
        return '{"title":"Unknown Device","layout":[{"type":"text","id":"status","name":"Status","properties":{"text":"Device configuration not found","style":"normal","fontSize":14.0,"color":"red"}}]}';
      }
    } catch (e) {
      _logger.e('Error downloading file from S3: $e');
      throw Exception('Failed to download file: $e');
    }
  }

  /// Upload a file to S3 storage
  Future<void> uploadFile(String key, String content) async {
    try {
      _logger.i('Uploading file to S3: $key');
      
      // Mock implementation for testing
      await Future.delayed(const Duration(milliseconds: 500));
      
      _logger.i('Successfully uploaded file: $key');
    } catch (e) {
      _logger.e('Error uploading file to S3: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// List files in a directory
  Future<List<Map<String, String>>> listFiles(String path) async {
    try {
      _logger.i('Listing files in S3 path: $path');
      
      // Mock implementation for testing
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Return mock file list
      return [
        {'key': '$path/device-001.json', 'size': '256'},
        {'key': '$path/device-002.json', 'size': '312'},
        {'key': '$path/device-003.json', 'size': '189'},
      ];
    } catch (e) {
      _logger.e('Error listing files in S3: $e');
      throw Exception('Failed to list files: $e');
    }
  }
  
  /// Get UI JSON for a device
  Future<UiLayout> getUiJson({
    required String userId,
    required String deviceId,
  }) async {
    try {
      _logger.i('Fetching UI JSON for device: $deviceId');
      
      final key = 'ui/$userId/$deviceId.json';
      final jsonData = await getFile(key);
      final data = json.decode(jsonData);
      
      return UiLayout.fromJson(data);
    } catch (e) {
      _logger.e('Error fetching UI JSON: $e');
      throw Exception('Failed to fetch UI JSON: $e');
    }
  }
}

// Provider
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);