import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';

import '../presentation/chat/views/chat_screen.dart';
import '../presentation/settings/views/settings_page.dart';

class BottomNavigator extends StatefulWidget {
  const BottomNavigator({super.key});

  @override
  _BottomNavigatorState createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  @override
  void initState() {
    super.initState();
    // Schedule a post-frame callback to handle redirect back after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleRedirectBack();
    });
  }

  /// Handles the redirect back to your app after LinkedIn authentication.
  Future<void> handleRedirectBack() async {
    final Uri uri = Uri.base;

    if (uri.queryParameters.containsKey('code')) {
      final String? code = uri.queryParameters['code'];
      if (!mounted) return;
      final settingsViewModel =
          Provider.of<SettingsViewModel>(context, listen: false);
      await settingsViewModel.handleAuthorizationCodeFromLinked(code);
      if (!mounted) return;
      await context.read<ChatViewModel>().checkAuthStatus();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ChatScreen();
  }
}
