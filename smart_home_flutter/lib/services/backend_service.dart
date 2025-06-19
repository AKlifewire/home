import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import 'mock_service.dart';

class BackendService {
  // Fetch all devices for the current user
  Future<List<Device>> fetchDevices() async {
    try {
      // GraphQL query to fetch user's devices
      const String query = '''
        query ListDevices {
          listDevices {
            items {
              id
              name
              type
              status
              owner
              createdAt
              updatedAt
            }
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
        return [];
      }

      final parsedData = jsonDecode(data);
      final List<dynamic> items = parsedData['listDevices']['items'];
      return items.map((item) => Device.fromJson(item)).toList();
    } catch (e) {
      safePrint('Error fetching devices: $e');
      
      // For demo purposes, return mock data if there's an error
      if (kIsWeb || !Amplify.isConfigured) {
        return MockService.getMockDevices();
      }
      
      rethrow;
    }
  }

  // Update device status
  Future<void> updateDeviceStatus(String deviceId, Map<String, dynamic> status) async {
    try {
      final statusJson = jsonEncode(status);
      final String mutation = '''
        mutation UpdateDeviceStatus {
          updateDeviceStatus(deviceId: "$deviceId", status: "$statusJson") {
            id
            status
            updatedAt
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: mutation,
      );
      
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        throw Exception(response.errors.first.message);
      }
    } catch (e) {
      safePrint('Error updating device status: $e');
      rethrow;
    }
  }

  // Register a new device
  Future<Device> registerDevice(String name, String type) async {
    try {
      final String mutation = '''
        mutation RegisterDevice {
          registerDevice(name: "$name", type: "$type") {
            id
            name
            type
            status
            owner
            createdAt
            updatedAt
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: mutation,
      );
      
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        throw Exception(response.errors.first.message);
      }

      final data = response.data;
      if (data == null) {
        throw Exception('No data returned');
      }

      final parsedData = jsonDecode(data);
      return Device.fromJson(parsedData['registerDevice']);
    } catch (e) {
      safePrint('Error registering device: $e');
      rethrow;
    }
  }

  // Test backend connection
  Future<bool> testConnection() async {
    try {
      const String query = '''
        query TestConnection {
          testConnection
        }
      ''';

      final request = GraphQLRequest<String>(
        document: query,
      );
      
      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        throw Exception(response.errors.first.message);
      }

      return true;
    } catch (e) {
      safePrint('Error testing connection: $e');
      return false;
    }
  }
}