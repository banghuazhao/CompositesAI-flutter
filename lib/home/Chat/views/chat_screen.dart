import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../injection_container.dart';
import '../viewModels/chat_view_model.dart';
import 'chat_message_list.dart';
import 'chat_session_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = sl<ChatViewModel>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          viewModel.initializeSession();
        });
        return viewModel;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Chat")),
        drawer: ChatDrawer(),
        body: ChatMessageList(),
      ),
    );
  }
}
