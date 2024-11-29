import 'package:mockito/mockito.dart';

import '../entities/user.dart';
import '../usecases/user_usercase.dart';

class MockUserUseCase extends Mock implements UserUseCase {
  @override
  Future<String> login(String email, String password) =>
      super.noSuchMethod(Invocation.method(#login, [email, password]),
          returnValue: Future.value(''),
          returnValueForMissingStub: Future.value(''));


}