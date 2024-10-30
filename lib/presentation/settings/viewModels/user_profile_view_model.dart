import 'package:domain/entities/user.dart';
import 'package:domain/usecases/user_usercase.dart';
import 'package:flutter/material.dart';
import 'package:domain/usecases/auth_usecase.dart'; // Assuming your use cases are here

class UserProfileViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  final UserUseCase userUseCase;

  bool isLoading = false;
  User? user;

  UserProfileViewModel({required this.authUseCase, required this.userUseCase}) {
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    setLoading(true);
    try {
      user = await userUseCase.fetchMe(); // Assuming a getUser method
    } catch (e) {
      print("Failed to fetch user details: $e");
    }
    setLoading(false);
  }

  Future<void> logoutUser() async {
    setLoading(true);
    try {
      await authUseCase.logout();
    } catch (e) {
      print("Logout failed: $e");
    }
    setLoading(false);
  }

  Future<void> deleteUser() async {
    setLoading(true);
    try {
      await userUseCase.deleteAccount();
      print("Account deleted successfully");
    } catch (e) {
      print("Account deletion failed: $e");
    }
    setLoading(false);
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
