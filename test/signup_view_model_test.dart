import 'dart:async';

import 'package:domain/auth/entities/auth_session.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/presentation/auth/signup_view_model.dart';

void main() {
  group('SignupViewModel Tests', () {
    group('toggleNewPasswordVisibility', () {
      test('should toggle obscureTextNewPassword', () {
        final mockAuthUseCase = MockAuthUseCase();
        final viewModel = SignupViewModel(authUseCase: mockAuthUseCase);

        expect(viewModel.obscureTextNewPassword, true);
        viewModel.toggleNewPasswordVisibility();
        expect(viewModel.obscureTextNewPassword, false);
      });
    });

    group('toggleConfirmPasswordVisibility', () {
      test('should toggle obscureTextConfirmPassword', () {
        final mockAuthUseCase = MockAuthUseCase();
        final viewModel = SignupViewModel(authUseCase: mockAuthUseCase);

        expect(viewModel.obscureTextConfirmPassword, true);
        viewModel.toggleConfirmPasswordVisibility();
        expect(viewModel.obscureTextConfirmPassword, false);
      });
    });

    group('signUp', () {
      test('should set loading and return user on success', () async {
        final mockAuthUseCase = MockAuthUseCase();
        final viewModel = SignupViewModel(authUseCase: mockAuthUseCase);

        const name = 'Test User';
        const email = 'test@example.com';
        const password = 'password123';

        when(
          mockAuthUseCase.signUp(
            name,
            email,
            password,
            profileImageUrl: anyNamed('profileImageUrl'),
          ),
        ).thenAnswer(
          (_) async => AuthSession(
            token: 'token',
            user: User(email: email, name: name),
          ),
        );

        final future = viewModel.signUp(name, email, password);
        expect(viewModel.isLoading, true);

        final user = await future;
        expect(viewModel.isLoading, false);

        expect(user?.email, email);
        expect(viewModel.isSignedUp, true);
        expect(viewModel.signedInUser?.email, email);
      });

      test('should map EMAIL_TAKEN to friendly message', () async {
        final mockAuthUseCase = MockAuthUseCase();
        final viewModel = SignupViewModel(authUseCase: mockAuthUseCase);

        const name = 'Test User';
        const email = 'test@example.com';
        const password = 'password123';

        when(
          mockAuthUseCase.signUp(
            name,
            email,
            password,
            profileImageUrl: anyNamed('profileImageUrl'),
          ),
        ).thenThrow(BadRequestException('EMAIL_TAKEN'));

        final user = await viewModel.signUp(name, email, password);
        expect(user, isNull);
        expect(viewModel.errorMessage,
            'This email is already registered. Please sign in instead.');
      });

      test('pending signup can finish after the page is disposed', () async {
        final authUseCase = MockAuthUseCase();
        final viewModel = SignupViewModel(authUseCase: authUseCase);
        final response = Completer<AuthSession>();
        when(authUseCase.signUp(
          'Test User',
          'test@example.com',
          'password123',
          profileImageUrl: anyNamed('profileImageUrl'),
        )).thenAnswer((_) => response.future);
        var notifications = 0;
        viewModel.addListener(() => notifications++);

        final signup = viewModel.signUp(
          'Test User',
          'test@example.com',
          'password123',
        );
        viewModel.dispose();
        response.complete(const AuthSession(token: 'session-token'));

        await expectLater(signup, completes);
        expect(notifications, 1);
      });

      final errors = <Object, String>{
        BadRequestException('This email is already registered.'):
            'This email is already registered. Please sign in instead.',
        BadRequestException('The email format you entered is invalid.'):
            'Please enter a valid email address.',
        InternalServerErrorException('Internal diagnostic'):
            'Server error. Please try again later.',
        Exception('SocketException: Connection failed'):
            'Network error. Please check your connection.',
        Exception('Private internal diagnostic'):
            'Could not create your account. Please try again.',
      };
      for (final entry in errors.entries) {
        test('signup failure explains recovery: ${entry.key.runtimeType}',
            () async {
          final authUseCase = MockAuthUseCase();
          final viewModel = SignupViewModel(authUseCase: authUseCase);
          when(authUseCase.signUp(
            'Test User',
            'test@example.com',
            'password123',
            profileImageUrl: anyNamed('profileImageUrl'),
          )).thenThrow(entry.key);

          final user = await viewModel.signUp(
            'Test User',
            'test@example.com',
            'password123',
          );

          expect(user, isNull);
          expect(viewModel.errorMessage, entry.value);
          expect(viewModel.isLoading, isFalse);
          expect(viewModel.isSignedUp, isFalse);
        });
      }
    });
  });
}
