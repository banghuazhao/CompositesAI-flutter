import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:infrastructure/feature_flag_provider.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/presentation/tools/page/tool_page.dart';

import '../presentation/chat/views/chat_screen.dart';
import '../presentation/settings/views/settings_page.dart';

class BottomNavigator extends StatefulWidget {
  const BottomNavigator({Key? key}) : super(key: key);

  @override
  _BottomNavigatorState createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  final PageController _controller = PageController(
    initialPage: 0,
  );

  final _defaultColor = Colors.white;
  final _activeColor = Colors.green;
  int _currentIndex = 0;

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
      changeIndex(2);
      final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);
      await settingsViewModel.handleAuthorizationCodeFromLinked(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    return Consumer<FeatureFlagProvider>(
        builder: (context, featureFlagProvider, _) {
      return Scaffold(
          body: PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ChatScreen(),
              ToolPage(),
              SettingsPage()
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
              backgroundColor: Colors.grey.shade800,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedItemColor: _activeColor,
              unselectedItemColor: _defaultColor,
              currentIndex: _currentIndex,
              onTap: (index) {
                changeIndex(index);
                if (_currentIndex == 0) {
                  chatViewModel.checkAuthStatus();
                }
              },
              type: BottomNavigationBarType.fixed,
              items: [
                _bottomItem(Icons.chat, Icons.chat, "Chat"),
                _bottomItem(Icons.view_list, Icons.view_list, "Tools"),
                _bottomItem(Icons.more_horiz, Icons.more_horiz, "Settings"),
              ]));
    });
  }

  void changeIndex(int index) {
    _controller.jumpToPage(index);
    setState(() {
      _currentIndex = index;
    });
  }

  _bottomItem(IconData defaultIcon, IconData activeIcon, String title) {
    return BottomNavigationBarItem(
        icon: Icon(
          defaultIcon,
        ),
        activeIcon: Icon(
          activeIcon,
        ),
        label: title);
  }
}
