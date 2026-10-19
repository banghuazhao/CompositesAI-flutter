import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/material.dart';
// Assuming your use cases are here

class UserProfileViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  final UserUseCase userUseCase;
  final bool Function()? isCurrentSession;
  User? user;

  bool isLoading = false;
  bool isSignedIn = false;
  bool isRefreshingProfile = false;
  bool isSessionExpired = false;
  String? profileRefreshError;
  bool _disposed = false;
  int _profileRequestId = 0;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserProfileViewModel(
      {required this.authUseCase,
      required this.userUseCase,
      required this.user,
      this.isCurrentSession}) {
    isSignedIn = user != null;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _invalidateProfileRefresh();
    super.dispose();
  }

  Future<void> fetchUser() async {
    if (_disposed || isLoading || isRefreshingProfile || isSessionExpired) {
      return;
    }
    if (!(isCurrentSession?.call() ?? true)) {
      _expireProfile();
      notifyListeners();
      return;
    }
    final requestId = ++_profileRequestId;
    final cachedUser = user;
    isRefreshingProfile = true;
    profileRefreshError = null;
    notifyListeners();
    try {
      final fetchedUser = await userUseCase.fetchMe();
      if (_disposed || requestId != _profileRequestId) return;
      if (!(isCurrentSession?.call() ?? true) ||
          (cachedUser != null && !_sameAccount(cachedUser, fetchedUser))) {
        _expireProfile();
        return;
      }
      user = fetchedUser;
      isSignedIn = true;
      isSessionExpired = false;
    } catch (error) {
      if (_disposed || requestId != _profileRequestId) return;
      if (error is UnauthorizedException ||
          !(isCurrentSession?.call() ?? true)) {
        _expireProfile();
      } else {
        profileRefreshError =
            'Could not refresh your profile. Please try again.';
      }
    } finally {
      if (!_disposed && requestId == _profileRequestId) {
        isRefreshingProfile = false;
        notifyListeners();
      }
    }
  }

  static bool _sameAccount(User previous, User current) {
    final previousId = previous.id?.trim();
    final currentId = current.id?.trim();
    if (previousId != null &&
        previousId.isNotEmpty &&
        currentId != null &&
        currentId.isNotEmpty) {
      return previousId == currentId;
    }
    return previous.email.trim().toLowerCase() ==
        current.email.trim().toLowerCase();
  }

  void _expireProfile() {
    user = null;
    isSignedIn = false;
    isSessionExpired = true;
    profileRefreshError = 'Your session has expired. Please sign in again.';
  }

  void _invalidateProfileRefresh() {
    _profileRequestId++;
    isRefreshingProfile = false;
    profileRefreshError = null;
  }

  void applyConfirmedName(String name) {
    if (_disposed || user == null) return;
    final confirmedName = name.trim();
    if (confirmedName.isEmpty) return;
    _invalidateProfileRefresh();
    user!.name = confirmedName;
    notifyListeners();
  }

  /// Returns true once the local session is removed, even if the page was left.
  Future<bool> logoutUser(BuildContext context) async {
    if (_disposed || isLoading) return false;
    _invalidateProfileRefresh();
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
    _invalidateProfileRefresh();
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
