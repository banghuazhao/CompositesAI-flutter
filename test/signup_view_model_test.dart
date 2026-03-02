import 'package:domain/entities/auth_session.dart';
import 'package:domain/entities/domain_exceptions.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/mocks/auth_use_case_mock.dart';
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
        expect(viewModel.errorMessage, '邮箱已被注册');
      });
    });
  });
}

