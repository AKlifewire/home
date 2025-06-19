import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';

/// Helper class to create test devices in the backend for integration testing
class TestDeviceCreator {
  /// Creates a test device in the backend
  static Future<String> createTestDevice() async {
    try {
      // GraphQL mutation to create a test device
      const String mutation = '''
        mutation CreateTestDevice {
          createDevice(input: {
            name: "Test Smart Irrigation",
            type: "smart-irrigation",
            status: {
              waterPump: false,
              duration: 10,
              soilMoisture: 45,
              lastWatered: "2023-01-01T00:00:00.000Z"
            }
          }) {
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
      final deviceId = parsedData['createDevice']['id'];
      
      safePrint('Created test device with ID: $deviceId');
      return deviceId;
    } catch (e) {
      safePrint('Error creating test device: $e');
      rethrow;
    }
  }

  /// Deletes a test device from the backend
  static Future<void> deleteTestDevice(String deviceId) async {
    try {
      // GraphQL mutation to delete a test device
      final String mutation = '''
        mutation DeleteTestDevice {
          deleteDevice(id: "$deviceId") {
            id
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

      safePrint('Deleted test device with ID: $deviceId');
    } catch (e) {
      safePrint('Error deleting test device: $e');
      rethrow;
    }
  }
}