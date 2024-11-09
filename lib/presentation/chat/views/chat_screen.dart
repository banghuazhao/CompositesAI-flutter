import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/providers/feature_flag_provider.dart';

import '../../../injection_container.dart';
import '../../../main.dart';
import '../../settings/views/login_page.dart';
import '../viewModels/chat_view_model.dart';
import 'chat_message_list.dart';
import 'chat_session_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(builder: (context, viewModel, _) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chat")),
        drawer: (viewModel.isLoggedIn) ? ChatDrawer() : null,
        body: (viewModel.isLoggedIn)
            ? ChatMessageList()
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "You need to be logged in to use the chat feature.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        String? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const NewLoginPage()));
                        if (result == "Log in Success") {
                          await viewModel.checkAuthStatus();
                        }
                      },
                      child: const Text("Login to Chat"),
                    ),
                  ],
                ),
              ),
      );
    });
  }
}
