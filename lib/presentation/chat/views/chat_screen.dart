import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/injection_container.dart';
import '../../settings/views/login_page.dart';
import '../../settings/views/user_profile_page.dart';
import '../viewModels/chat_view_model.dart';
import 'chat_message_list.dart';
import 'chat_session_drawer.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;

  late ChatViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = Provider.of<ChatViewModel>(context, listen: false);
    _initializeChatSessions();
    _fetchAuthSession();
  }

  Future<void> _fetchAuthSession() async {
    await viewModel.fetchAuthSessionNew();
    setState(() {});
  }

  Future<void> _initializeChatSessions() async {
    await viewModel.initializeChatSessions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Ensure AutomaticKeepAliveClientMixin works
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Chat"),
            actions: [
              Builder(
                builder: (context) {
                  if (!viewModel.isLoggedIn) {
                    // If the user is not logged in, show login icon
                    return IconButton(
                      icon: const Icon(Icons.manage_accounts),
                      color: Colors.white,
                      tooltip: "Sign In",
                      onPressed: () async {
                        String? result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                        if (result == "Log in Success") {
                          await viewModel.checkAuthStatus();
                          setState(() {}); // Trigger UI rebuild
                        }
                      },
                    );
                  } else {
                    // If the user is logged in, show profile info
                    return Row(
                      mainAxisSize: MainAxisSize.min, // Keep it compact
                      children: [
                        GestureDetector(
                          onTap: () async {
                            String? result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfilePage(),
                              ),
                            );
                            if (result == "refresh") {
                              await viewModel.checkAuthStatus(); // Refresh the authentication status
                              setState(() {}); // Rebuild the UI
                            }
                          },
                          child: viewModel.user?.avatarUrl != null
                              ? CircleAvatar(
                            backgroundImage: NetworkImage(viewModel.user!.avatarUrl!),
                            radius: 16, // Adjust radius to fit in the app bar
                          )
                              : const Icon(
                            Icons.account_circle,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
          drawer: viewModel.isLoggedIn ? ChatDrawer() : null,
          body: Stack(
            children: [
              // Main content (ChatMessageList or Login prompt)
              ChatMessageList(),

              // Blur effect applied when the user is not logged in and there are more than 6 messages
              if (!viewModel.isLoggedIn && viewModel.messages.length > 6)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Adjust blur intensity
                  child: Container(
                    color: Colors.black.withOpacity(0.2), // Semi-transparent overlay
                  ),
                ),

              // Foreground content (Text & Button) remains fully visible
              if (!viewModel.isLoggedIn && viewModel.messages.length > 6)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 100,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Please sign in to access the chat and continue your learning experience.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black, // Keep text fully visible
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () async {
                          String? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                          if (result == "Log in Success") {
                            await viewModel.checkAuthStatus();
                            setState(() {}); // Trigger UI rebuild
                          }
                        },
                        icon: const Icon(Icons.manage_accounts, size: 22),
                        label: const Text(
                          "Login to Chat",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),


        );
      },
    );
  }
}