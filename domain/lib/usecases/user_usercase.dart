import '../entities/user.dart';
import '../repositories_abstract/user_repository.dart';

class UserUseCase {
  final UserRepository repository;

  UserUseCase({required this.repository});

  Future<User> fetchMe() async {
    return await repository.fetchMe();
  }
}
