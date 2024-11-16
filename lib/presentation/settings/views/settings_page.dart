// lib/presentation/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:swiftcomp/presentation/settings/views/qa_settings_page.dart';
import 'package:swiftcomp/presentation/settings/views/user_profile_page.dart';
import 'package:launch_review/launch_review.dart';
import '../viewModels/settings_view_model.dart';
import 'login_page.dart';
import 'tool_setting_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = Provider.of<SettingsViewModel>(context, listen: false);
    viewModel.fetchAuthSessionNew();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>( // listen to changes in SettingsViewModel
      builder: (context, viewModel, _) {//If every part of the widget depends on the state or changes dynamically, there’s no need to pass a child. Let the Consumer rebuild the entire widget tree.
        return Scaffold(
          appBar: AppBar(title: const Text("Settings")),
          body: ProgressHUD(
            child: Builder(
              builder: (context) => ListView(
                children: [
                  if (!viewModel.isLoggedIn)
                    MoreRow(
                      title: "Login",
                      leadingIcon: Icons.person_rounded,
                      onTap: () async {
                        String? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                        if (result == "Log in Success") {
                          await viewModel.fetchAuthSessionNew();
                        }
                      },
                    ),
                  if (viewModel.isLoggedIn)
                    ListTile(
                      leading: Icon(
                        Icons.account_circle,
                        size: 45,
                        color: Colors.blueGrey,
                      ),
                      title: Text(
                        viewModel.user?.name ?? "",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(viewModel.user?.email ?? ""),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UserProfilePage()),
                        ).then((value) {
                          if (value == 'refresh') {
                            viewModel.fetchAuthSessionNew();
                          }
                        });
                      },
                    ),
                  MoreRow(
                    title: "Tools Settings",
                    leadingIcon: Icons.settings_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ToolSettingPage()),
                    ),
                  ),
                  MoreRow(
                    title: "Feedback",
                    leadingIcon: Icons.chat_rounded,
                    onTap: viewModel.openFeedback,
                  ),
                  MoreRow(
                    title: "Rate this App",
                    leadingIcon: Icons.thumb_up_rounded,
                    onTap: () {
                      print("Rate App button tapped"); // Debug print
                      viewModel.rateApp();
                    },
                  ),
                  MoreRow(
                    title: "Share this App",
                    leadingIcon: Icons.share_rounded,
                    onTap: () => viewModel.shareApp(context),
                  ),
                  GestureDetector(
                    onTap: () => viewModel.handleTap(
                      () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => QASettingsPage()),
                        );
                        viewModel.fetchAuthSessionNew();
                      },
                    ),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text("Version ${viewModel.version}"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MoreRow extends StatelessWidget {
  final IconData leadingIcon;
  final IconData trailingIcon;
  final String title;
  final void Function() onTap;

  MoreRow(
      {Key? key,
      this.trailingIcon = Icons.chevron_right_rounded,
      required this.leadingIcon,
      required this.title,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Ink(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          onTap: onTap,
          child: ListTile(
            leading: Icon(leadingIcon),
            trailing: Icon(trailingIcon),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
