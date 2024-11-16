// lib/presentation/viewmodels/feature_flag_view_model.dart

import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter/material.dart';
import '../providers/feature_flag_provider.dart';
import "package:domain/usecases/api_env_usecase.dart";

class QASettingsViewModel extends ChangeNotifier {
  final FeatureFlagProvider featureFlagProvider;
  final APIEnvironmentUseCase apiEnvironmentUseCase;
  final AuthUseCase authUseCase;

  String? currentEnvironment;
  bool isLoading = false;

  QASettingsViewModel(
      {required this.featureFlagProvider,
      required this.apiEnvironmentUseCase,
      required this.authUseCase}) {
    _loadCurrentEnvironment();
  }

  Map<String, bool> get featureFlags => featureFlagProvider.allFeatureFlags();

  bool getFeatureFlag(String key) {
    return featureFlagProvider.getFeatureFlag(key);
  }

  void toggleFeatureFlag(String key) {
    featureFlagProvider.toggleFeatureFlag(key);
    notifyListeners();
  }

  Future<void> _loadCurrentEnvironment() async {
    currentEnvironment = await apiEnvironmentUseCase.getCurrentAPIEnvironment();
    notifyListeners();
  }

  Future<void> changeEnvironment(String environment) async {
    isLoading = true;
    notifyListeners();
    try {
      await authUseCase.logout();
    } catch (e) {
      print('Error during logout: $e');
    }
    await apiEnvironmentUseCase.changeAPIEnvironment(environment);
    currentEnvironment = environment;
    isLoading = false;
    notifyListeners();
  }
}
