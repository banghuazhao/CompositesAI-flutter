import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/settings/providers/feature_flag_provider.dart';
import 'package:swiftcomp/presentation/settings/views/reset_password_page.dart';
import 'package:swiftcomp/presentation/tools/page/tool_page.dart';

import 'chat/views/chat_screen.dart';
import 'settings/views/settings_page.dart';

class BottomNavigator extends StatefulWidget {
  const BottomNavigator({Key? key}) : super(key: key);

  @override
  _BottomNavigatorState createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  late final AppLinks _appLinks;
  final PageController _controller = PageController(
    initialPage: 0,
  );

  final _defaultColor = Colors.white;
  final _activeColor = Colors.green;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _handleWebLink();
    } else {
      _setupAppLinks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    return Consumer<FeatureFlagProvider>(
        builder: (context, featureFlagProvider, _) {
      bool isChatEnabled = featureFlagProvider.getFeatureFlag('Chat');
      if (!isChatEnabled && _currentIndex == 2) {
        _currentIndex = 1;
      }
      return Scaffold(
          body: PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              if (isChatEnabled) ChatScreen(),
              ToolPage(),
              SettingsPage()
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
              backgroundColor: Color.fromRGBO(51, 66, 78, 1),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedItemColor: _activeColor,
              unselectedItemColor: _defaultColor,
              currentIndex: _currentIndex,
              onTap: (index) {
                _controller.jumpToPage(index);
                setState(() {
                  _currentIndex = index;
                });
                if (_currentIndex == 0 && isChatEnabled) {
                  chatViewModel.checkAuthStatus();
                }
              },
              type: BottomNavigationBarType.fixed,
              items: [
                if (isChatEnabled) _bottomItem(Icons.chat, Icons.chat, "Chat"),
                _bottomItem(Icons.view_list, Icons.view_list, "Tools"),
                _bottomItem(Icons.more_horiz, Icons.more_horiz, "Settings"),
              ]));
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

  void _handleWebLink() {
    final uri = Uri.base;
    final pathSegments = uri.pathSegments;
    if (uri.host == 'compositesai.com' || uri.host == 'localhost') {
      if (uri.pathSegments.isNotEmpty && pathSegments[0] == 'reset-password') {
        final token = pathSegments[1];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToResetPasswordPage(token);
        });
      }
    }
  }

  void _setupAppLinks() async {
    _appLinks = AppLinks();

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        print(uri);
      }
    });

    _appLinks.uriLinkStream.listen((uri) {
      print(uri);
      final token =
          uri.pathSegments.length > 1 && uri.pathSegments[0] == 'reset-password'
              ? uri.pathSegments[1]
              : uri.queryParameters['token'];
      print(token);
      if (token != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToResetPasswordPage(token);
        });
      }
    });
  }

  void _navigateToResetPasswordPage(String token) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordPage(token: token),
      ),
    );
  }
}
