import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:flutter/material.dart';
// Assuming your use cases are here

class UserProfileViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  final UserUseCase userUseCase;
  User? user;

  bool isLoading = false;
  bool isSignedIn = false;
  bool _disposed = false;
  int _profileRequestId = 0;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserProfileViewModel(
      {required this.authUseCase,
      required this.userUseCase,
      required this.user});

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _profileRequestId++;
    super.dispose();
  }

  Future<void> fetchUser() async {
    if (_disposed) return;
    final requestId = ++_profileRequestId;
    try {
      final fetchedUser = await userUseCase.fetchMe();
      if (_disposed || requestId != _profileRequestId) return;
      user = fetchedUser;
      notifyListeners();
    } catch (e) {
      if (_disposed || requestId != _profileRequestId) return;
      user = null; // Clear user data in case of an error
      notifyListeners(); // Ensure the UI is updated
    }
  }

  /// Returns true once the local session is removed, even if the page was left.
  Future<bool> logoutUser(BuildContext context) async {
    if (_disposed || isLoading) return false;
    _profileRequestId++;
    setLoading(true);
    try {
      await authUseCase.logout();
      user = null;
      isSignedIn = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.black,
          ),
        );
      }
      return true;
    } catch (_) {
      debugPrint('Logout failed.');
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logout failed. Please try again."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } finally {
      setLoading(false); // Ensure loading state is cleared
    }
  }

  Future<bool> deleteUser() async {
    _profileRequestId++;
    setLoading(true);
    _errorMessage = null;
    try {
      await userUseCase.deleteAccount();
      user = null;
      isSignedIn = false;
      notifyListeners();
      debugPrint("Account deleted successfully");
      return true;
    } catch (e) {
      _errorMessage = 'Delete failed: ${e.toString()}';
      return false;
    } finally {
      setLoading(false);
    }
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
      debugPrint("Failed to update user name: $error");
    }
  }
}
