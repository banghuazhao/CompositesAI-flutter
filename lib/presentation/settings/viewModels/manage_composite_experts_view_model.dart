import 'package:domain/entities/application.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/usecases/composite_expert_usecase.dart';
import 'package:domain/usecases/user_usercase.dart';
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
}
