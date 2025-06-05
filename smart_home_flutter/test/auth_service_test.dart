import 'package:flutter_test/flutter_test.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:smart_home_flutter/core/services/auth_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([AmplifyClass])
import 'auth_service_test.mocks.dart';

void main() {
  late AuthService authService;
  late MockAmplifyClass mockAmplify;

  setUp(() {
    mockAmplify = MockAmplifyClass();
    Amplify.Auth = mockAmplify;
    authService = AuthService();
  });

  group('AuthService', () {
    test('signIn should call Amplify.Auth.signIn with correct parameters', () async {
      // Arrange
      final email = 'test@example.com';
      final password = 'password123';
      
      when(mockAmplify.signIn(
        username: email,
        password: password,
      )).thenAnswer((_) async => SignInResult(isSignedIn: true));

      // Act
      final result = await authService.signIn(
        email: email,
        password: password,
      );

      // Assert
      expect(result.isSignedIn, true);
      verify(mockAmplify.signIn(
        username: email,
        password: password,
      )).called(1);
    });

    test('signUp should call Amplify.Auth.signUp with correct parameters', () async {
      // Arrange
      final email = 'test@example.com';
      final password = 'password123';
      
      when(mockAmplify.signUp(
        username: email,
        password: password,
        options: anyNamed('options'),
      )).thenAnswer((_) async => SignUpResult(
        isSignUpComplete: false,
        nextStep: AuthSignUpStep(
          signUpStep: 'CONFIRM_SIGN_UP_STEP',
          additionalInfo: {},
          codeDeliveryDetails: AuthCodeDeliveryDetails(
            destination: email,
            deliveryMedium: 'EMAIL',
            attributeName: 'email',
          ),
        ),
      ));

      // Act
      final result = await authService.signUp(
        email: email,
        password: password,
      );

      // Assert
      expect(result.isSignUpComplete, false);
      expect(result.nextStep.signUpStep, 'CONFIRM_SIGN_UP_STEP');
      verify(mockAmplify.signUp(
        username: email,
        password: password,
        options: anyNamed('options'),
      )).called(1);
    });

    test('confirmSignUp should call Amplify.Auth.confirmSignUp with correct parameters', () async {
      // Arrange
      final email = 'test@example.com';
      final confirmationCode = '123456';
      
      when(mockAmplify.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      )).thenAnswer((_) async => SignUpResult(
        isSignUpComplete: true,
        nextStep: AuthSignUpStep.done(),
      ));

      // Act
      await authService.confirmSignUp(
        email: email,
        confirmationCode: confirmationCode,
      );

      // Assert
      verify(mockAmplify.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      )).called(1);
    });

    test('signOut should call Amplify.Auth.signOut', () async {
      // Arrange
      when(mockAmplify.signOut()).thenAnswer((_) async => SignOutResult());

      // Act
      await authService.signOut();

      // Assert
      verify(mockAmplify.signOut()).called(1);
    });
  });
}