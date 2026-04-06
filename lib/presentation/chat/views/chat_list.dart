import 'package:domain/chat/entities/chat.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewModels/chat_view_model.dart';

/// Shows Share Chat dialog. Copy Link button calls [viewModel].copyShareLink([chat]).
Future<void> showShareChatDialog(
  BuildContext context,
  ChatViewModel viewModel,
  Chat chat,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Share Chat'),
      content: const Text(
        'Messages you send after creating your link won\'t be shared. '
        'Users with the URL will be able to view the shared chat.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.grey.shade800,
          ),
          icon: const Icon(Icons.link, size: 20),
          label: const Text('Copy Link'),
          onPressed: () async {
            final success = await viewModel.copyShareLink(chat);
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            }
          },
        ),
      ],
    ),
  );
}

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

Widget _chatListTile(
  BuildContext context,
  ChatViewModel chatViewModel,
  Chat chat, {
  required bool pinMenuAsUnpin,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.only(left: 16, right: 8),
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
          case 'share':
            await showShareChatDialog(context, chatViewModel, chat);
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
              Text(pinMenuAsUnpin ? 'Unpin' : 'Pin'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 8),
              Text('Share'),
            ],
          ),
        ),
      ],
    ),
    title: Text(
      chat.title,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
    onTap: () {
      chatViewModel.selectChat(chat);
      Navigator.pop(context);
    },
  );
}

/// Collapsible section (chevron + grey title), matching Pinned / Previous chats.
Widget _chatSectionExpansionTile({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  bool initiallyExpanded = false,
}) {
  return Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: EdgeInsets.zero,
      collapsedIconColor: Colors.grey.shade500,
      iconColor: Colors.grey.shade500,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      initiallyExpanded: initiallyExpanded,
      children: children,
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
        onRefresh: chatViewModel.fetchChats,
        child: ListView(
          controller: chatViewModel.chatListScrollController,
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
          if (!chatViewModel.isLoadingChats)
            Builder(
              builder: (context) {
                // Pinned titles only appear under Pinned; exclude those ids from Previous.
                final pinnedIds =
                    chatViewModel.pinnedChats.map((c) => c.id).toSet();
                final previousChats = chatViewModel.chats
                    .where((c) => !pinnedIds.contains(c.id))
                    .toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _chatSectionExpansionTile(
                      context: context,
                      title: 'Pinned',
                      initiallyExpanded: false,
                      children: [
                        if (chatViewModel.pinnedChats.isEmpty)
                          ListTile(
                            dense: true,
                            title: Text(
                              'No pinned chats',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...chatViewModel.pinnedChats.map(
                            (chat) => _chatListTile(
                              context,
                              chatViewModel,
                              chat,
                              pinMenuAsUnpin: true,
                            ),
                          ),
                      ],
                    ),
                    _chatSectionExpansionTile(
                      context: context,
                      title: 'Previous chats',
                      initiallyExpanded: true,
                      children: [
                        if (previousChats.isEmpty)
                          ListTile(
                            dense: true,
                            title: Text(
                              'No previous chats',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...previousChats.map(
                            (chat) => _chatListTile(
                              context,
                              chatViewModel,
                              chat,
                              pinMenuAsUnpin: false,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          if (chatViewModel.isLoadingChats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          if (chatViewModel.isLoadingMoreChats)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
