import 'package:mockito/mockito.dart';

import '../entities/user.dart';
import '../use_cases/user_use_case.dart';

class MockUserUseCase extends Mock implements UserUseCase {
  @override
  Future<User> fetchMe() =>
      super.noSuchMethod(
          Invocation.method(#fetchMe, []),
          returnValue: Future.value(User(
            username: 'mock_username',
            email: 'mock_email@example.com',
            name: 'Mock User',
            description: 'This is a mock description',
            avatarUrl: 'https://example.com/mock_avatar.png',
          ),),
          returnValueForMissingStub: Future.value( User(
            username: 'default',
            email: 'default_email@example.com',
          )));

@override
Future<void> updateMe(String newName) =>
    super.noSuchMethod(
      Invocation.method(#updateMe, [newName]),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );

@override
Future<void> deleteAccount() =>
    super.noSuchMethod(
      Invocation.method(#deleteAccount, []),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );

}