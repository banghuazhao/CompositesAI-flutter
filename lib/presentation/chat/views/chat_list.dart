import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewModels/chat_view_model.dart';

class ChatList extends StatelessWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
            ),
            child: Text(
              'Chats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('New Chat'),
            onTap: () {
              chatViewModel.onTapNewChat();
              Navigator.pop(context);
            },
          ),
          ...chatViewModel.chats.map((chat) {
            return ListTile(
              title: Text(
                chat.title,
                overflow: TextOverflow.ellipsis, // Truncate with ...
                maxLines: 1, // Limit to one line
              ),
              onTap: () {
                chatViewModel.selectChat(chat);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
