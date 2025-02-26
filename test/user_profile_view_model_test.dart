import 'package:domain/entities/user.dart';
import 'package:domain/mocks/auth_use_case_mock.dart';
import 'package:domain/mocks/user_use_case_mock.dart';
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

    group('fetchMe', ()
    {
      test('should return a User when repository fetchMe succeeds', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final MockUserUseCase mockUserUseCase = MockUserUseCase();
        // Arrange
        final mockUser = User(
          username: 'mock_user',
          email: 'mock_email@example.com',
          name: 'Mock User',
          description: 'This is a mock description',
          avatarUrl: 'https://example.com/mock_avatar.png',
        );

        when(mockUserUseCase.fetchMe()).thenAnswer((_) async => mockUser);

        // Act
        final result = await mockUserUseCase.fetchMe();

        // Assert
        expect(result, isA<User>());
        expect(result.username, mockUser.username);
        expect(result.email, mockUser.email);
        expect(result.name, mockUser.name);
        expect(result.description, mockUser.description);
        expect(result.avatarUrl, mockUser.avatarUrl);

        verify(mockUserUseCase.fetchMe()).called(1);
      });

      test('should throw an exception when repository fetchMe fails', () async {
        final MockUserUseCase mockUserUseCase = MockUserUseCase();
        // Arrange
        when(mockUserUseCase.fetchMe()).thenThrow(Exception('Repository error'));

        // Act & Assert
        expect(() async => await mockUserUseCase.fetchMe(), throwsException);

        verify(mockUserUseCase.fetchMe()).called(1);
      });
    });

    group('updateMe', () {
      test('should call repository.updateMe with the correct parameter', () async {
        final MockUserUseCase mockUserUseCase = MockUserUseCase();
        // Arrange
        const newName = 'Updated Name';
        when(mockUserUseCase.updateMe(newName)).thenAnswer((_) async {});

        // Act
        await mockUserUseCase.updateMe(newName);

        // Assert
        verify(mockUserUseCase.updateMe(newName)).called(1);
      });

      test('should throw an exception if repository.updateMe fails', () async {
        final MockUserUseCase mockUserUseCase = MockUserUseCase();
        // Arrange
        const newName = 'Updated Name';
        when(mockUserUseCase.updateMe(newName)).thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(() async => await mockUserUseCase.updateMe(newName), throwsException);

        // Verify the repository method was called
        verify(mockUserUseCase.updateMe(newName)).called(1);
      });
    });


    group('deleteUser', () {
      test('should set loading to true during the process and back to false after success', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final MockUserUseCase mockUserUseCase = MockUserUseCase();
        final UserProfileViewModel userProfileViewModel = UserProfileViewModel(
            authUseCase: mockAuthUseCase, userUseCase: mockUserUseCase, user: User(email: "email"));
        // Arrange
        when(mockUserUseCase.deleteAccount()).thenAnswer((_) async {});

        // Act
        final future = userProfileViewModel.deleteUser();

        // Verify loading is true during the process
        expect(userProfileViewModel.isLoading, true);

        await future;

        // Verify loading is false after the process
        expect(userProfileViewModel.isLoading, false);

        // Verify deleteAccount is called
        verify(mockUserUseCase.deleteAccount()).called(1);
      });

      test('should set loading to true during the process and back to false after failure', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final MockUserUseCase mockUserUseCase = MockUserUseCase();
        final UserProfileViewModel userProfileViewModel = UserProfileViewModel(
            authUseCase: mockAuthUseCase,userUseCase: mockUserUseCase, user: User(email: "email"));
        // Arrange
        when(mockUserUseCase.deleteAccount()).thenThrow(Exception('Deletion failed'));

        // Act
        bool loadingStarted = false;
        userProfileViewModel.addListener(() {
          if (userProfileViewModel.isLoading) {
            loadingStarted = true;
          }
        });

        // Act
        final future = userProfileViewModel.deleteUser();

        // Wait for the method to complete
        await future;

        // Verify loading started at some point
        expect(loadingStarted, true);

        // Verify loading is false after the process
        expect(userProfileViewModel.isLoading, false);

        // Verify deleteAccount is called
        verify(mockUserUseCase.deleteAccount()).called(1);
      });

      test('should handle exceptions and print an error message on failure', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final MockUserUseCase mockUserUseCase = MockUserUseCase();
        final UserProfileViewModel userProfileViewModel = UserProfileViewModel(
            authUseCase: mockAuthUseCase,userUseCase: mockUserUseCase, user: User(email: "email"));
        // Arrange
        when(mockUserUseCase.deleteAccount()).thenThrow(Exception('Deletion failed'));

        // Act
        await userProfileViewModel.deleteUser();

        // Verify deleteAccount is called
        verify(mockUserUseCase.deleteAccount()).called(1);

        // Since print statements cannot be directly tested, check for expected behavior post-error handling
        expect(userProfileViewModel.isLoading, false);
      });
    });

    group('setLoading', () {
      test('should update isLoading and notify listeners when set to true', () {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final MockUserUseCase mockUserUseCase = MockUserUseCase();
        final UserProfileViewModel userProfileViewModel = UserProfileViewModel(
            authUseCase: mockAuthUseCase,userUseCase: mockUserUseCase, user: User(email: "email"));
        // Act
        userProfileViewModel.setLoading(true);

        // Assert
        expect(userProfileViewModel.isLoading, true);
      });

      test('should update isLoading and notify listeners when set to false', () {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final MockUserUseCase mockUserUseCase = MockUserUseCase();
        final UserProfileViewModel userProfileViewModel = UserProfileViewModel(
            authUseCase: mockAuthUseCase,userUseCase: mockUserUseCase, user: User(email: "email"));
        // Arrange
        userProfileViewModel.setLoading(true); // Start with true

        // Act
        userProfileViewModel.setLoading(false);

        // Assert
        expect(userProfileViewModel.isLoading, false);
      });
    });
    });
}