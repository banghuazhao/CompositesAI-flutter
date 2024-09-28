import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/home/more/feature_flag_provider.dart';

void main() {
  group('FeatureFlagProvider Tests', () {
    late FeatureFlagProvider featureFlagProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({}); // Initialize with no values
      featureFlagProvider = FeatureFlagProvider();
      await featureFlagProvider.loadFeatureFlags();
    });

    test('Initial feature flag values should be false', () async {
      expect(featureFlagProvider.getFeatureFlag('Chat'), false);
    });

    test('Feature flag toggles and persists the new value', () async {
      await featureFlagProvider.toggleFeatureFlag('Chat');

      expect(featureFlagProvider.getFeatureFlag('Chat'), true);
    });

    test('Loading feature flags from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'Chat': true});
      featureFlagProvider = FeatureFlagProvider();
      await featureFlagProvider.loadFeatureFlags();

      expect(featureFlagProvider.getFeatureFlag('Chat'), true);
    });
  });
}
