import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mock_service.dart';

class LayoutService {
  // Cache expiration time (24 hours)
  static const int cacheExpirationMs = 86400000;

  // Fetch layout for a specific device
  Future<Map<String, dynamic>> fetchDeviceLayout(String deviceId, String deviceType) async {
    try {
      // Try to get from cache first
      final cachedLayout = await _getLayoutFromCache(deviceId);
      if (cachedLayout != null) {
        safePrint('Using cached layout for device $deviceId');
        return cachedLayout;
      }

      // Try S3 first
      try {
        final layout = await _fetchLayoutFromS3(deviceId);
        await _cacheLayout(deviceId, layout);
        return layout;
      } catch (e) {
        safePrint('S3 fetch failed, trying API: $e');
        // Fallback to API
        final layout = await _fetchLayoutFromApi(deviceId, deviceType);
        await _cacheLayout(deviceId, layout);
        return layout;
      }
    } catch (e) {
      safePrint('Error fetching layout: $e');
      
      // If all fails, use a default layout based on device type
      final defaultLayout = MockService.getMockLayout(deviceType);
      return defaultLayout;
    }
  }

  // Fetch layout from S3
  Future<Map<String, dynamic>> _fetchLayoutFromS3(String deviceId) async {
    final key = 'devices/$deviceId/layout.json';
    
    final result = await Amplify.Storage.downloadData(
      key: key,
      options: const StorageDownloadDataOptions(
        accessLevel: StorageAccessLevel.private,
      ),
    ).result;

    final layoutJson = utf8.decode(result.bytes);
    return jsonDecode(layoutJson);
  }

  // Fetch layout from AppSync API
  Future<Map<String, dynamic>> _fetchLayoutFromApi(String deviceId, String deviceType) async {
    final String query = '''
      query GetDeviceLayout {
        getDeviceLayout(deviceId: "$deviceId", deviceType: "$deviceType") {
          layout
        }
      }
    ''';

    final request = GraphQLRequest<String>(
      document: query,
    );
    
    final response = await Amplify.API.query(request: request).response;

    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }

    final data = response.data;
    if (data == null) {
      throw Exception('No layout data returned');
    }

    final parsedData = jsonDecode(data);
    return jsonDecode(parsedData['getDeviceLayout']['layout']);
  }

  // Get layout from cache
  Future<Map<String, dynamic>?> _getLayoutFromCache(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'device_layout_$deviceId';
    
    final cachedLayout = prefs.getString(cacheKey);
    if (cachedLayout == null) return null;
    
    final cachedTimestamp = prefs.getInt('${cacheKey}_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if cache is expired
    if (now - cachedTimestamp > cacheExpirationMs) {
      return null;
    }
    
    return jsonDecode(cachedLayout);
  }

  // Cache layout
  Future<void> _cacheLayout(String deviceId, Map<String, dynamic> layout) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'device_layout_$deviceId';
    
    await prefs.setString(cacheKey, jsonEncode(layout));
    await prefs.setInt(
      '${cacheKey}_timestamp', 
      DateTime.now().millisecondsSinceEpoch
    );
  }
}