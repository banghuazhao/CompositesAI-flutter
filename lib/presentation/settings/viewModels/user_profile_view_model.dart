import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/usecases/user_usercase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:domain/usecases/auth_usecase.dart'; // Assuming your use cases are here

class UserProfileViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  final UserUseCase userUseCase;


  bool isLoading = false;
  User? user;
  bool isSignedIn = false;
  bool isLoggedIn = false;

  UserProfileViewModel({required this.authUseCase, required this.userUseCase}) {
    fetchUserDetails();
    fetchAuthSessionNew();
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

  Future<void> fetchAuthSessionNew() async {
    try {
      isLoggedIn = await authUseCase.isLoggedIn();
      notifyListeners();
      if (isLoggedIn) {
        fetchUser();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      isLoggedIn = false;
    }
  }

  Future<void> fetchUser() async {
    try {
      user = await userUseCase.fetchMe();
      print(user);
      notifyListeners();
    } catch (e) {
      isLoggedIn = false;
    }
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
  Future<void> updateUserName(String newName) async {
    try {
      // Call the update method in userUserCase to update the name in the backend or database
      await userUseCase.updateMe(newName);

      // Update the local user object if it exists
      if (user != null) {
        user!.name = newName; // Update the user’s name
        notifyListeners(); // Notify the UI to refresh
      }
    } catch (error) {
      // Handle any errors that may occur
      print("Failed to update user name: $error");
    }
  }
}
