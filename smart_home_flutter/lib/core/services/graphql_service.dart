import 'package:amplify_api/amplify_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_config.dart';
import '../models/ui_component.dart';

class GraphQLService {
  final _api = AmplifyAPI();

  // Get UI layout for a device
  Future<UiLayout> getUiLayout({
    required String userId,
    required String deviceType,
  }) async {
    const query = r'''
      query GetUiPage($userId: ID!, $deviceType: String) {
        getUiPage(userId: $userId, deviceType: $deviceType) {
          success
          data {
            title
            layout
          }
        }
      }
    ''';

    try {
      final response = _api.query(
        request: GraphQLRequest(
          document: query,
          variables: {'userId': userId, 'deviceType': deviceType},
        ),
      );

      if (response.data == null) {
        throw Exception('Failed to get UI layout');
      }

      return UiLayout.fromJson(response.data!['getUiPage']['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Get user's devices
  Future<List<DeviceConfig>> getMyDevices({required String userId}) async {
    const query = r'''
      query GetMyDevices($userId: ID!) {
        getMyDevices(userId: $userId) {
          success
          devices {
            deviceId
            deviceType
            components {
              type
              id
              name
              capabilities
              config
            }
            metadata {
              name
              location
              manufacturer
              model
              version
            }
          }
        }
      }
    ''';

    try {
      final response = _api.query(
        request: GraphQLRequest(document: query, variables: {'userId': userId}),
      );

      if (response.data == null) {
        throw Exception('Failed to get devices');
      }

      final devices = (response.data!['getMyDevices']['devices'] as List)
          .map((device) => DeviceConfig.fromJson(device))
          .toList();

      return devices;
    } catch (e) {
      rethrow;
    }
  }

  // Control device
  Future<bool> controlDevice({
    required String deviceId,
    required String componentId,
    required Map<String, dynamic> parameters,
  }) async {
    const mutation = r'''
      mutation ControlRelay($deviceId: ID!, $relayId: String!, $state: Boolean!) {
        controlRelay(deviceId: $deviceId, relayId: $relayId, state: $state) {
          success
          message
        }
      }
    ''';

    try {
      final response = _api.mutate(
        request: GraphQLRequest(
          document: mutation,
          variables: {
            'deviceId': deviceId,
            'relayId': componentId,
            'state': parameters['state'],
          },
        ),
      );

      if (response.data == null) {
        throw Exception('Failed to control device');
      }

      return response.data!['controlRelay']['success'];
    } catch (e) {
      rethrow;
    }
  }

  // Subscribe to device updates
  Stream<GraphQLResponse<dynamic>> subscribeToDeviceUpdates({
    required String deviceId,
  }) {
    const subscription = r'''
      subscription OnDeviceUpdate($deviceId: ID!) {
        onDeviceUpdate(deviceId: $deviceId) {
          deviceId
          state
          timestamp
        }
      }
    ''';

    return _api.subscribe(
      request: GraphQLRequest(
        document: subscription,
        variables: {'deviceId': deviceId},
      ),
    );
  }
}

// Provider
final graphQLServiceProvider = Provider<GraphQLService>(
  (ref) => GraphQLService(),
);
