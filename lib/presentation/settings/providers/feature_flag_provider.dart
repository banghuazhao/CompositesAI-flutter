import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlagProvider extends ChangeNotifier {
  Map<String, bool> _featureFlags = {
    'Chat': false
  };

  FeatureFlagProvider() {
    loadFeatureFlags();
  }

  bool getFeatureFlag(String feature) {
    return _featureFlags[feature] ?? false;
  }

  Map<String, bool> allFeatureFlags() {
    return _featureFlags;
  }

  Future<void> loadFeatureFlags() async {
    final prefs = await SharedPreferences.getInstance();
    _featureFlags.forEach((key, value) {
      _featureFlags[key] = prefs.getBool(key) ?? false;
    });
    notifyListeners();
  }

  Future<void> toggleFeatureFlag(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    _featureFlags[feature] = !_featureFlags[feature]!;
    prefs.setBool(feature, _featureFlags[feature]!);
    notifyListeners();
  }
}
