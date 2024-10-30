// lib/presentation/viewmodels/feature_flag_view_model.dart

import 'package:flutter/material.dart';
import '../providers/feature_flag_provider.dart';

class FeatureFlagViewModel extends ChangeNotifier {
  final FeatureFlagProvider featureFlagProvider;

  FeatureFlagViewModel({required this.featureFlagProvider});

  Map<String, bool> get featureFlags => featureFlagProvider.allFeatureFlags();

  bool getFeatureFlag(String key) {
    return featureFlagProvider.getFeatureFlag(key);
  }

  void toggleFeatureFlag(String key) {
    featureFlagProvider.toggleFeatureFlag(key);
    notifyListeners();
  }
}
