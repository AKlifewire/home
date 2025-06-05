import 'package:flutter_test/flutter_test.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:smart_home_flutter/core/services/graphql_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([AmplifyAPI])
import 'graphql_service_test.mocks.dart';

void main() {
  late GraphQLService graphQLService;
  late MockAmplifyAPI mockAmplifyAPI;

  setUp(() {
    mockAmplifyAPI = MockAmplifyAPI();
    graphQLService = GraphQLService();
    // Inject mock API
    graphQLService._api = mockAmplifyAPI;
  });

  group('GraphQLService', () {
    test('getUiLayout should return UiLayout when successful', () async {
      // Arrange
      final userId = 'user123';
      final deviceType = 'thermostat';
      
      final mockResponse = GraphQLResponse<dynamic>(
        data: {
          'getUiPage': {
            'success': true,
            'data': {
              'title': 'Thermostat',
              'layout': '[{"type":"gauge","id":"temp"}]'
            }
          }
        },
        errors: [],
        extensions: {},
      );
      
      when(mockAmplifyAPI.query(
        request: anyNamed('request'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await graphQLService.getUiLayout(
        userId: userId,
        deviceType: deviceType,
      );

      // Assert
      expect(result.title, 'Thermostat');
      verify(mockAmplifyAPI.query(
        request: anyNamed('request'),
      )).called(1);
    });

    test('getMyDevices should return list of devices when successful', () async {
      // Arrange
      final userId = 'user123';
      
      final mockResponse = GraphQLResponse<dynamic>(
        data: {
          'getMyDevices': {
            'success': true,
            'devices': [
              {
                'deviceId': 'device123',
                'deviceType': 'thermostat',
                'components': [
                  {
                    'type': 'gauge',
                    'id': 'temp',
                    'name': 'Temperature',
                    'capabilities': ['read'],
                    'config': {'min': 0, 'max': 100}
                  }
                ],
                'metadata': {
                  'name': 'Living Room Thermostat',
                  'location': 'Living Room',
                  'manufacturer': 'Acme',
                  'model': 'T1000',
                  'version': '1.0'
                }
              }
            ]
          }
        },
        errors: [],
        extensions: {},
      );
      
      when(mockAmplifyAPI.query(
        request: anyNamed('request'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await graphQLService.getMyDevices(
        userId: userId,
      );

      // Assert
      expect(result.length, 1);
      expect(result[0].deviceId, 'device123');
      expect(result[0].deviceType, 'thermostat');
      verify(mockAmplifyAPI.query(
        request: anyNamed('request'),
      )).called(1);
    });

    test('controlDevice should return true when successful', () async {
      // Arrange
      final deviceId = 'device123';
      final componentId = 'relay1';
      final parameters = {'state': true};
      
      final mockResponse = GraphQLResponse<dynamic>(
        data: {
          'controlRelay': {
            'success': true,
            'message': 'Device controlled successfully'
          }
        },
        errors: [],
        extensions: {},
      );
      
      when(mockAmplifyAPI.mutate(
        request: anyNamed('request'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await graphQLService.controlDevice(
        deviceId: deviceId,
        componentId: componentId,
        parameters: parameters,
      );

      // Assert
      expect(result, true);
      verify(mockAmplifyAPI.mutate(
        request: anyNamed('request'),
      )).called(1);
    });
  });
}