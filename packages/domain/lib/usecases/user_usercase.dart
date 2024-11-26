import 'package:infrastructure/token_provider.dart';

import '../entities/user.dart';
import '../repositories_abstract/user_repository.dart';

class UserUseCase {
  final UserRepository repository;
  final TokenProvider tokenProvider;

  UserUseCase({required this.repository, required this.tokenProvider});

  Future<User> fetchMe() async {
    return await repository.fetchMe();
  }

  Future<void> updateMe(String newName) async {
    return await repository.updateMe(newName);
  }

  Future<void> deleteAccount() async {
    await repository.deleteAccount();
    tokenProvider.deleteToken();
  }
}
