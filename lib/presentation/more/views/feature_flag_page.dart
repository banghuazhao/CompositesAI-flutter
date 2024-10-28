import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/more/providers/feature_flag_provider.dart';

import '../../../injection_container.dart';
import '../viewModels/feature_flag_view_model.dart';

class FeatureFlagPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => sl<FeatureFlagViewModel>(),
        child: Consumer<FeatureFlagViewModel>(builder: (context, viewModel, _) {
          return Scaffold(
              appBar: AppBar(
                title: Text('Feature Flags'),
              ),
              body: ListView(
                children: viewModel.featureFlags.keys.map((feature) {
                  return SwitchListTile(
                    title: Text(feature),
                    value: viewModel.getFeatureFlag(feature),
                    onChanged: (bool value) {
                      viewModel.toggleFeatureFlag(feature);
                    },
                  );
                }).toList(),
              ));
        }));
  }
}
