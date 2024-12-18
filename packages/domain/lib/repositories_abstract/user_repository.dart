
import '../entities/user.dart';

abstract class UserRepository {
  Future<User> fetchMe();
  Future<void> updateMe(String newName);
  Future<void> deleteAccount();
  Future<String> submitApplication(String? reason, String? link);
  Future<User> getUserById(int userId);
  Future<void> becomeExpert(int userId);
}
