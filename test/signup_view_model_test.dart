import 'package:domain/entities/user.dart';
import 'package:domain/mocks/auth_use_case_mock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/presentation/auth/signup_view_model.dart';

void main() {
  group('SignupViewModel Tests', () {
    group('toggleNewPasswordVisibility', () {
      test('should toggle obscureTextNewPassword and notify listeners', () {

        final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
        final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

        // Initially true
        expect(signupViewModel.obscureTextNewPassword, true);

        // Toggle
        signupViewModel.toggleNewPasswordVisibility();
        expect(signupViewModel.obscureTextNewPassword, false);

        // Toggle back
        signupViewModel.toggleNewPasswordVisibility();
        expect(signupViewModel.obscureTextNewPassword, true);
      });
    });

    group('toggleConfirmPasswordVisibility', () {
      test('should toggle obscureTextConfirmPassword and notify listeners', () {
        final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
        final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

        expect(signupViewModel.obscureTextConfirmPassword, true);

        // Toggle
        signupViewModel.toggleConfirmPasswordVisibility();
        expect(signupViewModel.obscureTextConfirmPassword, false);

        // Toggle back
        signupViewModel.toggleConfirmPasswordVisibility();
        expect(signupViewModel.obscureTextConfirmPassword, true);
      });
    });

    group('sendSignupVerificationCode', () {
      test('should call repository to send signup verification code with the correct email', () async {
        final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();

        const email = 'test@example.com';

        when(mockAuthUseCase.sendSignupVerificationCode(email))
            .thenAnswer((_) async {});

        await mockAuthUseCase.sendSignupVerificationCode(email);

        verify(mockAuthUseCase.sendSignupVerificationCode(email)).called(1);
      });

      test('should propagate errors thrown by repository', () async {
        final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();

        const email = 'test@example.com';
        const errorMessage = 'Failed to send verification code';

        when(mockAuthUseCase.sendSignupVerificationCode(email))
            .thenThrow(Exception(errorMessage));

        expect(
              () async => await mockAuthUseCase.sendSignupVerificationCode(email),
          throwsA(isA<Exception>()),
        );

        verify(mockAuthUseCase.sendSignupVerificationCode(email)).called(1);
      });
    });

  group('signup', () {
    test('should set isLoading to true during the signup process', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const password = 'password123';
      const verificationCode = '123456';
      const name = 'Test User';

      when(mockAuthUseCase.signup(email, password, verificationCode, name: name))
          .thenAnswer((_) async => User(name: name, email: email));

      final future = signupViewModel.signup(email, password, verificationCode, name: name);

      expect(signupViewModel.isLoading, true);
      await future;
      expect(signupViewModel.isLoading, false);
    });

    test('should return User on successful signup', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const password = 'password123';
      const verificationCode = '123456';
      const name = 'Test User';

      final user = User(name: name, email: email);

      when(mockAuthUseCase.signup(email, password, verificationCode, name: name))
          .thenAnswer((_) async => user);

      final result = await signupViewModel.signup(email, password, verificationCode, name: name);

      expect(result, user);
      expect(signupViewModel.errorMessage, isNull);
    });

    test('should set errorMessage on signup failure', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const password = 'password123';
      const verificationCode = '123456';

      when(mockAuthUseCase.signup(email, password, verificationCode))
          .thenThrow(Exception('Signup error'));

      final result = await signupViewModel.signup(email, password, verificationCode);

      expect(result, isNull);
      expect(signupViewModel.errorMessage, 'Signup failed: Exception: Signup error');
    });

    test('should reset isLoading and notifyListeners on failure', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const password = 'password123';
      const verificationCode = '123456';

      when(mockAuthUseCase.signup(email, password, verificationCode))
          .thenThrow(Exception('Signup error'));

      await signupViewModel.signup(email, password, verificationCode);

      expect(signupViewModel.isLoading, false);
    });
  });
  });

  group('signUpFor', () {
    test('should set isLoading to true and back to false during the process', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';

      when(mockAuthUseCase.sendSignupVerificationCode(email))
          .thenAnswer((_) async {});

      final future = signupViewModel.signUpFor(email);

      // Verify isLoading is true during the process
      expect(signupViewModel.isLoading, true);

      await future;

      // Verify isLoading is false after the process
      expect(signupViewModel.isLoading, false);
    });

    test('should call sendSignupVerificationCode with the correct email', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';

      when(mockAuthUseCase.sendSignupVerificationCode(email))
          .thenAnswer((_) async {});

      await signupViewModel.signUpFor(email);

      verify(mockAuthUseCase.sendSignupVerificationCode(email)).called(1);
    });

    test('should set isSignUp to true on successful signup', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';

      when(mockAuthUseCase.sendSignupVerificationCode(email))
          .thenAnswer((_) async {});

      await signupViewModel.signUpFor(email);

      expect(signupViewModel.isSignUp, true);
      expect(signupViewModel.errorMessage, '');
    });

    test('should set errorMessage on failure and not set isSignUp', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const errorMessage = 'Failed to send verification code';

      when(mockAuthUseCase.sendSignupVerificationCode(email))
          .thenThrow(Exception(errorMessage));

      await signupViewModel.signUpFor(email);

      expect(signupViewModel.isSignUp, false);
      expect(signupViewModel.errorMessage, contains(errorMessage));
    });

    test('should reset isLoading after failure', () async {
      final MockAuthUseCase mockAuthUseCase  = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';

      when(mockAuthUseCase.sendSignupVerificationCode(email))
          .thenThrow(Exception('Some error'));

      await signupViewModel.signUpFor(email);

      expect(signupViewModel.isLoading, false);
    });
  });

  group('login', () {
    test('should set isLoading to true during login process', () async {
      final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const password = 'password123';
      final user = User(email: email);
      when(mockAuthUseCase.login(email, password)).thenAnswer((_) async => user);

      final future = signupViewModel.login(email, password);

      expect(signupViewModel.isLoading, true);
      await future;
      expect(signupViewModel.isLoading, false);
    });

    test('should return access token on successful login', () async {
      final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const password = 'password123';
      final user = User(email: email);
      when(mockAuthUseCase.login(email, password)).thenAnswer((_) async => user);

      final result = await signupViewModel.login(email, password);
      expect(result, user);
      expect(signupViewModel.errorMessage, null);
    });

    test('should set error message on login failure', () async {
      final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
      final SignupViewModel signupViewModel = SignupViewModel(authUseCase: mockAuthUseCase);

      const email = 'test@example.com';
      const password = 'password123';
      when(mockAuthUseCase.login(email, password)).thenThrow(Exception('Login error'));

      final result = await signupViewModel.login(email, password);
      expect(result, null);
      expect(signupViewModel.loginErrorMessage, 'Login failed: Exception: Login error');
    });
  });
}
