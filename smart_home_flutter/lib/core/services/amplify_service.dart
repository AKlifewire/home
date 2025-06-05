import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../config/amplifyconfiguration.dart';

class AmplifyService {
  static Future<void> configureAmplify() async {
    try {
      final auth = AmplifyAuthCognito();
      final api = AmplifyAPI();
      
      await Amplify.addPlugins([auth, api]);
      await Amplify.configure(amplifyConfig);
      
      print('Amplify configured successfully');
    } catch (e) {
      print('Error configuring Amplify: $e');
    }
  }

  static Future<AuthUser?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user;
    } catch (e) {
      return null;
    }
  }

  static Future<SignInResult> signIn(String email, String password) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  static Future<SignUpResult> signUp(String email, String password, String name) async {
    try {
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
            AuthUserAttributeKey.name: name,
          },
        ),
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> confirmSignUp(String email, String code) async {
    try {
      await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: code,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await Amplify.Auth.resetPassword(
        username: email,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> confirmResetPassword(
    String email,
    String newPassword,
    String confirmationCode,
  ) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      const query = '''
        query GetMyDevices {
          getMyDevices {
            id
            name
            type
            location
            status
            lastSeen
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

      final data = response.data != null 
          ? jsonDecode(response.data!) as Map<String, dynamic>
          : null;

      if (data == null || data['getMyDevices'] == null) {
        return [];
      }

      return List<Map<String, dynamic>>.from(data['getMyDevices']);
    } catch (e) {
      print('Error fetching devices: $e');
      return [];
    }
  }

  static Future<bool> registerDevice(
    String deviceId,
    String name,
    String location,
  ) async {
    try {
      const mutation = '''
        mutation RegisterDevice(\$deviceId: String!, \$name: String!, \$location: String!) {
          registerDevice(deviceId: \$deviceId, name: \$name, location: \$location) {
            statusCode
            success
            deviceId
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          'deviceId': deviceId,
          'name': name,
          'location': location,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;
      
      if (response.errors.isNotEmpty) {
        throw Exception(response.errors.first.message);
      }

      final data = response.data != null 
          ? jsonDecode(response.data!) as Map<String, dynamic>
          : null;

      return data?['registerDevice']?['success'] ?? false;
    } catch (e) {
      print('Error registering device: $e');
      return false;
    }
  }

  static Future<bool> controlDevice(
    String deviceId,
    String field,
    dynamic value,
  ) async {
    try {
      const mutation = '''
        mutation ControlRelay(\$deviceId: String!, \$relay: String!, \$state: Boolean!) {
          controlRelay(deviceId: \$deviceId, relay: \$relay, state: \$state) {
            statusCode
            success
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          'deviceId': deviceId,
          'relay': field,
          'state': value,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;
      
      if (response.errors.isNotEmpty) {
        throw Exception(response.errors.first.message);
      }

      final data = response.data != null 
          ? jsonDecode(response.data!) as Map<String, dynamic>
          : null;

      return data?['controlRelay']?['success'] ?? false;
    } catch (e) {
      print('Error controlling device: $e');
      return false;
    }
  }
}