import '../entities/user.dart';

abstract class UserRepository {
  Future<User> fetchMe();
  Future<void> deleteAccount();
}
