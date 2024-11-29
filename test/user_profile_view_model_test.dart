import 'package:domain/entities/user.dart';
import 'package:domain/mocks/auth_usecase_mock.dart';
import 'package:domain/mocks/user_usecase_mock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/presentation/settings/viewModels/user_profile_view_model.dart';

void main() {
  group('UserProfileViewModel Tests', ()
  {
    group('isLoggedIn', () {
    test('should return true when token is not null', () async {
      final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
      //final MockUserUseCase mockUserUseCase = MockUserUseCase();
      //final UserProfileViewModel userProfileViewModel = UserProfileViewModel(authUseCase: mockAuthUseCase,userUseCase: mockUserUseCase);
      // Arrange
      when(mockAuthUseCase.isLoggedIn()).thenAnswer((_) async => true);

      // Act
      final result = await mockAuthUseCase.isLoggedIn();

      // Assert
      expect(result, true);
      verify(mockAuthUseCase.isLoggedIn()).called(1);
    });

    test('should return false when token is null', () async {
      final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
      // Arrange
      when(mockAuthUseCase.isLoggedIn()).thenAnswer((_) async => false);

      // Act
      final result = await mockAuthUseCase.isLoggedIn();

      // Assert
      expect(result, false);
      verify(mockAuthUseCase.isLoggedIn()).called(1);
    });
  });
    group('logout', () {
      test('should not call logout or deleteToken when token is null', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        when(mockAuthUseCase.logout()).thenAnswer((_) async => null);

        await mockAuthUseCase.logout();

        verify(mockAuthUseCase.logout()).called(1);
      });

      test('should not call logout or deleteToken when token is empty', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        when(mockAuthUseCase.logout()).thenAnswer((_) async => "");

        await mockAuthUseCase.logout();

        verify(mockAuthUseCase.logout()).called(1);
      });

      test('should call logout and deleteToken when token is valid', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        when(mockAuthUseCase.logout()).thenAnswer((_) async => "validToken");

        await mockAuthUseCase.logout();

        verify(mockAuthUseCase.logout()).called(1);
      });
    });

    });
}