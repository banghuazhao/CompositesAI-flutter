import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/injection_container.dart';
import '../../chat/viewModels/chat_view_model.dart';
import '../viewModels/qa_settings_view_model.dart';

class QASettingsPage extends StatelessWidget {
  const QASettingsPage({super.key});

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
                children: _buildChild(viewModel, context),
              ));
        }));
  }

  List<Widget> _buildChild(
      QASettingsViewModel viewModel, BuildContext context) {
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
    final List<Widget> apiEnvironmentList = [
      RadioGroup<String>(
        groupValue: viewModel.currentEnvironment,
        onChanged: (String? value) async {
          if (value == null) return;

          await viewModel.changeEnvironment(value);
          if (context.mounted) {
            await context.read<ChatViewModel>().clearChatStateOnLogout();
          }
        },
        child: Column(
          children: const [
            ListTile(
              title: Text('Development'),
              leading: Radio<String>(value: 'development'),
            ),
            ListTile(
              title: Text('Production'),
              leading: Radio<String>(value: 'production'),
            ),
          ],
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

    result.add(Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('Daily Chat Count',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ));
    result.add(
      ListTile(
        title: Text('Current Count: ${viewModel.dailyChatCount}'),
        trailing: ElevatedButton(
          child: Text('Reset'),
          onPressed: () async {
            await viewModel.resetDailyChatCount();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Daily chat count reset")),
            );
          },
        ),
      ),
    );
    return result;
  }
}
