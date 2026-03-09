import 'package:domain/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewModels/chat_view_model.dart';

/// Returns the new title if user confirms, null if cancelled.
Future<String?> showRenameDialog(BuildContext context, String currentTitle) async {
  final controller = TextEditingController(text: currentTitle);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename chat'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class ChatList extends StatelessWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    if (chatViewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(chatViewModel.errorMessage!))
        );
        chatViewModel.errorMessage = null;
      });
    }

    return Drawer(
      child: RefreshIndicator(
        onRefresh: () => chatViewModel.fetchChats(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
          ...(() {
            final sorted = List<Chat>.from(chatViewModel.chats)
              ..sort((a, b) => (b.pinned ? 1 : 0).compareTo(a.pinned ? 1 : 0));
            return sorted.map((chat) => ListTile(
              contentPadding: EdgeInsets.only(left: 16, right: 8),
              trailing: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  switch (value) {
                    case 'delete':
                      chatViewModel.deleteChat(chat);
                      break;
                    case 'rename':
                      final newTitle = await showRenameDialog(context, chat.title);
                      if (newTitle != null && newTitle.isNotEmpty) {
                        await chatViewModel.updateChatTitle(chat, newTitle);
                      }
                      break;
                    case 'pin':
                      chatViewModel.togglePin(chat);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        const Icon(Icons.push_pin, size: 20),
                        const SizedBox(width: 8),
                        Text(chat.pinned ? 'Unpin' : 'Pin'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: const [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: const [
                        Icon(Icons.delete, size: 20),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
              title: Text(
                chat.title,
                overflow: TextOverflow.ellipsis, // Truncate with ...
                maxLines: 1, // Limit to one line
              ),
              onTap: () {
                chatViewModel.selectChat(chat);
                Navigator.pop(context);
              },
            ));
          }()),
          ],
        ),
      ),
    );
  }
}
