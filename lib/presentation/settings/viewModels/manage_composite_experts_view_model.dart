
import 'package:domain/entities/composite_expert_request.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/use_cases/composite_expert_use_case.dart';
import 'package:domain/use_cases/user_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ManageCompositeExpertsViewModel extends ChangeNotifier {
  final UserUseCase userUseCase;
  final CompositeExpertUseCase compositeExpertUseCase;
  final User user;
  List<CompositeExpertRequest> applications = [];

  bool isLoading = false;
  bool isSignedIn = false;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  ManageCompositeExpertsViewModel(
      {required this.userUseCase, required this.compositeExpertUseCase, required this.user});

  Future<void> getAllApplications() async {
    _setLoading(true);
    try {
      applications = await compositeExpertUseCase.getAllApplications();
    } catch (e) {
      applications = [];
      _errorMessage = "Failed to fetch applications: $e";
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
  Future<User> getUserById(int userId) async {
    try {
      // Call the use case to fetch user by ID
      User user = await userUseCase.getUserById(userId);
      return user;
    } catch (e) {
      // Log the error for debugging
      print("Error fetching user: $e");

      // Re-throw the error or handle it appropriately
      throw Exception("Failed to fetch user with ID: $userId");
    }
  }

  Future<void> approveExpert(int userId) async {
    try {
      // First step: Make user an expert
      await userUseCase.becomeExpert(userId);
      // Second step: Delete the user's application
      await compositeExpertUseCase.deleteApplication(userId);
      // Update the list by removing the approved application
      applications.removeWhere((app) => app.userId == userId);
      // Notify listeners about the state change
      notifyListeners();
    } catch (e) {
      print("Error in approveExpert: $e");
      throw Exception("Failed to approve expert with user ID: $userId.");
    }
  }

  Future<void> disapproveExpert(int userId) async {
    try {
      await compositeExpertUseCase.deleteApplication(userId);
      applications.removeWhere((app) => app.userId == userId);
      notifyListeners();
    } catch (e) {
      print("Error in disapprove Expert: $e");
      throw Exception("Failed to disapprove expert with user ID: $userId.");
    }
  }

}
