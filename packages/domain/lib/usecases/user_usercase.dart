
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
    await tokenProvider.deleteToken();
  }

  Future<String> submitApplication(String? reason) async{
    String result = await repository.submitApplication(reason);
    return result;
  }

  Future<User> getUserById(int userId) async {
    return await repository.getUserById(userId);
  }

  Future<void> becomeExpert(int userId) async {
    await repository.becomeExpert(userId);
  }
}
