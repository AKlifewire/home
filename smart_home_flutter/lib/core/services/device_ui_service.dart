import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/ui_layout.dart';
import 'graphql_service.dart';
import 'storage_service.dart';

final deviceUiServiceProvider = Provider((ref) => DeviceUIService(ref));

/// Service for fetching and caching device UI layouts
class DeviceUIService {
  final Ref _ref;
  final Map<String, UiLayout> _uiCache = {};
  
  DeviceUIService(this._ref);
  
  /// Get UI layout for a single device
  Future<UiLayout> getDeviceUI(String deviceId) async {
    // Check cache first
    if (_uiCache.containsKey(deviceId)) {
      return _uiCache[deviceId]!;
    }
    
    try {
      // Try to get from GraphQL
      final result = await _ref.read(graphQLServiceProvider).query(
        query: r'''
          query GetDeviceUI($deviceId: String!) {
            getDeviceUI(deviceId: $deviceId) {
              deviceId
              uiJson
              statusCode
              error
            }
          }
        ''',
        variables: {'deviceId': deviceId},
      );
      
      if (result.hasException) {
        throw Exception('GraphQL error: ${result.exception.toString()}');
      }
      
      final data = result.data?['getDeviceUI'];
      if (data == null || data['statusCode'] != 200) {
        throw Exception('Failed to get UI: ${data?['error'] ?? 'Unknown error'}');
      }
      
      final uiJson = data['uiJson'];
      final uiLayout = UiLayout.fromJson(uiJson);
      
      // Cache the result
      _uiCache[deviceId] = uiLayout;
      
      return uiLayout;
    } catch (e) {
      // Fallback to S3 direct access
      try {
        final storageService = _ref.read(storageServiceProvider);
        final uiJsonString = await storageService.getDeviceUI(deviceId);
        final uiJson = jsonDecode(uiJsonString);
        final uiLayout = UiLayout.fromJson(uiJson);
        
        // Cache the result
        _uiCache[deviceId] = uiLayout;
        
        return uiLayout;
      } catch (storageError) {
        // Return a minimal fallback UI
        return UiLayout(
          title: 'Device $deviceId',
          deviceId: deviceId,
          deviceType: 'unknown',
          components: [
            {
              'type': 'text',
              'field': 'error',
              'label': 'Failed to load UI for this device'
            },
            {
              'type': 'status',
              'field': 'connection',
              'label': 'Connection Status'
            }
          ],
        );
      }
    }
  }
  
  /// Batch fetch UI layouts for multiple devices
  Future<Map<String, UiLayout>> batchGetDeviceUIs(List<String> deviceIds) async {
    // Filter out devices we already have in cache
    final devicesToFetch = deviceIds.where((id) => !_uiCache.containsKey(id)).toList();
    
    if (devicesToFetch.isEmpty) {
      // Return cached results
      return Map.fromEntries(
        deviceIds.map((id) => MapEntry(id, _uiCache[id]!))
      );
    }
    
    try {
      // Try to get from GraphQL
      final result = await _ref.read(graphQLServiceProvider).query(
        query: r'''
          query BatchGetDeviceUIs($deviceIds: [String!]!) {
            batchGetDeviceUIs(deviceIds: $deviceIds) {
              deviceId
              uiJson
              statusCode
              error
            }
          }
        ''',
        variables: {'deviceIds': devicesToFetch},
      );
      
      if (result.hasException) {
        throw Exception('GraphQL error: ${result.exception.toString()}');
      }
      
      final data = result.data?['batchGetDeviceUIs'];
      if (data == null) {
        throw Exception('Failed to get UI layouts');
      }
      
      // Process results
      for (final item in data) {
        if (item['statusCode'] == 200 && item['uiJson'] != null) {
          final deviceId = item['deviceId'];
          final uiJson = item['uiJson'];
          final uiLayout = UiLayout.fromJson(uiJson);
          
          // Cache the result
          _uiCache[deviceId] = uiLayout;
        }
      }
    } catch (e) {
      // Fallback to individual fetches
      await Future.wait(
        devicesToFetch.map((id) => getDeviceUI(id))
      );
    }
    
    // Return all requested devices (from cache now)
    return Map.fromEntries(
      deviceIds.map((id) => MapEntry(id, _uiCache[id] ?? _createFallbackUI(id)))
    );
  }
  
  /// Clear the cache for a specific device
  void invalidateCache(String deviceId) {
    _uiCache.remove(deviceId);
  }
  
  /// Clear the entire cache
  void clearCache() {
    _uiCache.clear();
  }
  
  /// Create a fallback UI for a device
  UiLayout _createFallbackUI(String deviceId) {
    return UiLayout(
      title: 'Device $deviceId',
      deviceId: deviceId,
      deviceType: 'unknown',
      components: [
        {
          'type': 'text',
          'field': 'error',
          'label': 'Failed to load UI for this device'
        },
        {
          'type': 'status',
          'field': 'connection',
          'label': 'Connection Status'
        }
      ],
    );
  }
}