import '../entities/user.dart';

abstract class UserRepository {
  Future<User> fetchMe();
  Future<void> updateMe(String newName);
  Future<void> deleteAccount();
  Future<String> submitApplication(String? reason);
}
