import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/injection_container.dart';
import '../viewModels/qa_settings_view_model.dart';

class QASettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => sl<QASettingsViewModel>(),
        child: Consumer<QASettingsViewModel>(builder: (context, viewModel, _) {
          return Scaffold(
              appBar: AppBar(
                title: Text('QA Settings'),
              ),
              body: ListView(
                children: _buildChild(viewModel),
              ));
        }));
  }

  List<Widget> _buildChild(QASettingsViewModel viewModel) {
    List<Widget> result = [];
    result.add(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Feature Flags List',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
    List<Widget> featureFlagsList = viewModel.featureFlags.keys.map((feature) {
      return SwitchListTile(
        title: Text(feature),
        value: viewModel.getFeatureFlag(feature),
        onChanged: (bool value) {
          viewModel.toggleFeatureFlag(feature);
        },
      );
    }).toList();
    result.addAll(featureFlagsList);
    result.add(Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('Select API Environment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ));
    List<Widget> apiEnvironmentList = [
      ListTile(
        title: Text('Development'),
        leading: Radio<String>(
          value: 'development',
          groupValue: viewModel.currentEnvironment,
          onChanged: (String? value) {
            if (value != null) {
              viewModel.changeEnvironment(value);
            }
          },
        ),
      ),
      ListTile(
        title: Text('Production'),
        leading: Radio<String>(
          value: 'production',
          groupValue: viewModel.currentEnvironment,
          onChanged: (String? value) {
            if (value != null) {
              viewModel.changeEnvironment(value);
            }
          },
        ),
      ),
    ];
    if (viewModel.isLoading) {
      result.add(Container(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ));
    } else {
      result.addAll(apiEnvironmentList);
    }
    return result;
  }
}
