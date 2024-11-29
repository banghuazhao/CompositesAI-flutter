import 'package:domain/mocks/auth_usecase_mock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/presentation/settings/viewModels/login_view_model.dart';

void main() {
  group('LoginViewModel Tests', () {
    group('togglePasswordVisibility', () {
      test('should toggle obscureText and notify listeners', () {

        final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
        final LoginViewModel loginViewModel = LoginViewModel(authUseCase: mockAuthUseCase);

        // Initially true
        expect(loginViewModel.obscureText, true);

        // Toggle
        loginViewModel.togglePasswordVisibility();
        expect(loginViewModel.obscureText, false);

        // Toggle back
        loginViewModel.togglePasswordVisibility();
        expect(loginViewModel.obscureText, true);
      });
    });
  });


  group('updateButtonState', () {

    final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
    final LoginViewModel loginViewModel = LoginViewModel(authUseCase: mockAuthUseCase);

    test('should enable button when email and password are valid', () {
      loginViewModel.updateButtonState('test@example.com', 'password123');
      expect(loginViewModel.isButtonEnabled, true);
    });

    test('should disable button when email is invalid', () {
      loginViewModel.updateButtonState('invalid-email', 'password123');
      expect(loginViewModel.isButtonEnabled, false);
    });

    test('should disable button when password is empty', () {
      loginViewModel.updateButtonState('test@example.com', '');
      expect(loginViewModel.isButtonEnabled, false);
    });

    test('should disable button when password length is less than 6', () {
      loginViewModel.updateButtonState('test@example.com', '12345');
      expect(loginViewModel.isButtonEnabled, false);
    });
  });

  group('login', () {
    test('should set isLoading to true during login process', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final LoginViewModel loginViewModel = LoginViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const password = 'password123';
      when(mockAuthUseCase.login(email, password)).thenAnswer((_) async => 'accessToken');

      final future = loginViewModel.login(email, password);

      expect(loginViewModel.isLoading, true);
      await future;
      expect(loginViewModel.isLoading, false);
    });

    test('should return access token on successful login', () async {

      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final LoginViewModel loginViewModel = LoginViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const password = 'password123';
      const accessToken = 'accessToken';
      when(mockAuthUseCase.login(email, password)).thenAnswer((_) async => accessToken);

      final result = await loginViewModel.login(email, password);
      expect(result, accessToken);
      expect(loginViewModel.errorMessage, null);
    });

    test('should set error message on login failure', () async {

      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final LoginViewModel loginViewModel = LoginViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const password = 'password123';
      when(mockAuthUseCase.login(email, password)).thenThrow(Exception('Login error'));

      final result = await loginViewModel.login(email, password);
      expect(result, null);
      expect(loginViewModel.errorMessage, 'Login failed: Exception: Login error');
    });
  });

  group('validateGoogleToken', () {
    test('should return true when token validation is successful', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();

      const idToken = "1234567";

      when(mockAuthUseCase.validateGoogleToken(idToken)).thenAnswer((_) async => true);

      final result = await mockAuthUseCase.validateGoogleToken(idToken);

      expect(result, true);
      verify(mockAuthUseCase.validateGoogleToken(idToken)).called(1);
    });

    test('should return false when token validation fails', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();

      const idToken = "1234567";

      when(mockAuthUseCase.validateGoogleToken(idToken)).thenAnswer((_) async => false);

      final result = await mockAuthUseCase.validateGoogleToken(idToken);

      expect(result, false);
      verify(mockAuthUseCase.validateGoogleToken(idToken)).called(1);
    });

    test('should throw an exception on error during token validation', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();

      const idToken = "1234567";

      when(mockAuthUseCase.validateGoogleToken(idToken)).thenThrow(Exception('Validation error'));

      expect(
            () async => await mockAuthUseCase.validateGoogleToken(idToken),
        throwsA(isA<Exception>()),
      );
      verify(mockAuthUseCase.validateGoogleToken(idToken)).called(1);
    });
  });

  group('syncUser', () {
    test('should return access token when user data is synced successfully', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final LoginViewModel loginViewModel = LoginViewModel(authUseCase: mockAuthUseCase);

      const displayName = 'Test User';
      const email = 'test@example.com';
      const photoUrl = 'http://example.com/photo.jpg';

      when(mockAuthUseCase.syncUser(displayName, email, photoUrl))
          .thenAnswer((_) async => 'mockAccessToken');

      final result = await loginViewModel.syncUser(displayName, email, photoUrl);

      expect(result, 'mockAccessToken');
      verify(mockAuthUseCase.syncUser(displayName, email, photoUrl)).called(1);
    });

    test('should throw an exception when syncUser fails', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final LoginViewModel loginViewModel = LoginViewModel(authUseCase: mockAuthUseCase);

      const displayName = 'Test User';
      const email = 'test@example.com';
      const photoUrl = 'http://example.com/photo.jpg';

      when(mockAuthUseCase.syncUser(displayName, email, photoUrl))
          .thenThrow(Exception('Sync failed'));

      expect(
            () async => await loginViewModel.syncUser(displayName, email, photoUrl),
        throwsA(isA<Exception>()),
      );
      verify(mockAuthUseCase.syncUser(displayName, email, photoUrl)).called(1);
    });
  });


}