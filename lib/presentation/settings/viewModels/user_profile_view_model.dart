import 'package:domain/entities/user.dart';
import 'package:domain/usecases/user_usercase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Assuming your use cases are here

class UserProfileViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  final UserUseCase userUseCase;

  bool isLoading = false;
  User? user;
  bool isSignedIn = false;
  bool isLoggedIn = false;
  String errorMessage = '';

  UserProfileViewModel({required this.authUseCase, required this.userUseCase}) {
    fetchAuthSessionNew();
  }

  Future<void> fetchAuthSessionNew() async {
    try {
      isLoggedIn = await authUseCase.isLoggedIn();
      if (isLoggedIn) {
        await fetchUser(); // Fetch user only if logged in
      } else {
        user = null; // Clear user data when not logged in
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      isLoggedIn = false;
      user = null; // Ensure user data is cleared on error
    }
    notifyListeners(); // Notify listeners about state changes
  }

  Future<void> fetchUser() async {
    try {
      user = await userUseCase.fetchMe();
      notifyListeners();
    } catch (e) {
      isLoggedIn = false;
      user = null; // Clear user data in case of an error
      notifyListeners(); // Ensure the UI is updated
    }
  }

  Future<void> logoutUser() async {
    setLoading(true);
    try {
      await authUseCase.logout();
      Fluttertoast.showToast(
        msg: "Logged out",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      isLoggedIn = false; // Explicitly set isLoggedIn to false
      user = null; // Clear user data
      notifyListeners();
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

  void _setLoadingState(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
