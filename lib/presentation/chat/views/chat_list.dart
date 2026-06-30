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
Future<String?> showRenameDialog(
    BuildContext context, String currentTitle) async {
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

Future<String?> _showTextInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
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

Future<void> _showMoveToFolderSheet(
  BuildContext context,
  ChatViewModel viewModel,
  Chat chat,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const ListTile(
            title: Text(
              'Move to folder',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder_outlined),
            title: const Text('New folder'),
            onTap: () async {
              Navigator.pop(sheetContext);
              final name = await _showTextInputDialog(
                context,
                title: 'New folder',
                label: 'Folder name',
              );
              if (name != null && name.trim().isNotEmpty) {
                await viewModel.createFolderAndMoveChat(chat, name);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move_outline),
            title: const Text('No folder'),
            onTap: () {
              Navigator.pop(sheetContext);
              viewModel.moveChatToFolder(chat, null);
            },
          ),
          const Divider(),
          if (viewModel.chatFolders.isEmpty)
            ListTile(
              enabled: false,
              title: Text(
                'No folders yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            ...viewModel.chatFolders.map(
              (folder) => ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name, overflow: TextOverflow.ellipsis),
                trailing: chat.folderId == folder.id
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  viewModel.moveChatToFolder(chat, folder.id);
                },
              ),
            ),
        ],
      ),
    ),
  );
}

Future<void> _showTagsSheet(
  BuildContext context,
  ChatViewModel viewModel,
  Chat chat,
) async {
  final tags = await viewModel.fetchTagsForChat(chat);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const ListTile(
            title: Text(
              'Tags',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: const Text('Add tag'),
            onTap: () async {
              Navigator.pop(sheetContext);
              final tag = await _showTextInputDialog(
                context,
                title: 'Add tag',
                label: 'Tag name',
              );
              if (tag != null && tag.trim().isNotEmpty) {
                await viewModel.addTagToChat(chat, tag);
              }
            },
          ),
          const Divider(),
          if (tags.isEmpty)
            ListTile(
              enabled: false,
              title: Text(
                'No tags on this chat',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            ...tags.map(
              (tag) => ListTile(
                leading: const Icon(Icons.tag),
                title: Text(tag.name, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: 'Remove tag',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    viewModel.removeTagFromChat(chat, tag);
                  },
                ),
              ),
            ),
        ],
      ),
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
          case 'tags':
            await _showTagsSheet(context, chatViewModel, chat);
            break;
          case 'folder':
            await _showMoveToFolderSheet(context, chatViewModel, chat);
            break;
          case 'archive':
            chatViewModel.archiveChat(chat);
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
          value: 'tags',
          child: Row(
            children: [
              Icon(Icons.sell_outlined, size: 20),
              SizedBox(width: 8),
              Text('Tags'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'folder',
          child: Row(
            children: [
              Icon(Icons.folder_outlined, size: 20),
              SizedBox(width: 8),
              Text('Move to folder'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_outlined, size: 20),
              SizedBox(width: 8),
              Text('Archive'),
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

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    if (_searchController.text != chatViewModel.chatSearchQuery) {
      _searchController.text = chatViewModel.chatSearchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
    if (chatViewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || chatViewModel.errorMessage == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(chatViewModel.errorMessage!)),
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
            _ChatDrawerHeader(
              onNewChat: () {
                chatViewModel.onTapNewChat();
                Navigator.pop(context);
              },
            ),
            _ChatSearchField(
              controller: _searchController,
              onSearch: chatViewModel.searchChatHistory,
              onClear: chatViewModel.clearChatFilters,
            ),
            _ChatFilterChips(viewModel: chatViewModel),
            if (!chatViewModel.isLoadingChats)
              Builder(
                builder: (context) {
                  // Pinned titles only appear under Pinned; exclude those ids from Previous.
                  final pinnedIds =
                      chatViewModel.pinnedChats.map((c) => c.id).toSet();
                  final previousChats = chatViewModel.chats
                      .where((c) => !pinnedIds.contains(c.id))
                      .where((c) => c.folderId == null || c.folderId!.isEmpty)
                      .toList();
                  final folderChatIds = chatViewModel.chatFolders
                      .expand((folder) => folder.chats)
                      .map((chat) => chat.id)
                      .toSet();
                  final loosePreviousChats = previousChats
                      .where((chat) => !folderChatIds.contains(chat.id))
                      .toList();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (chatViewModel.hasActiveChatFilter)
                        _chatSectionExpansionTile(
                          context: context,
                          title: chatViewModel.activeChatFilterLabel,
                          initiallyExpanded: true,
                          children: [
                            if (chatViewModel.isLoadingChatFilters)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            else if (chatViewModel.filteredChats.isEmpty)
                              ListTile(
                                dense: true,
                                title: Text(
                                  'No chats found',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ...chatViewModel.filteredChats.map(
                                (chat) => _chatListTile(
                                  context,
                                  chatViewModel,
                                  chat,
                                  pinMenuAsUnpin: pinnedIds.contains(chat.id),
                                ),
                              ),
                          ],
                        )
                      else ...[
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
                        if (chatViewModel.chatFolders.isNotEmpty)
                          ...chatViewModel.chatFolders.map(
                            (folder) => _chatSectionExpansionTile(
                              context: context,
                              title: folder.name,
                              initiallyExpanded: folder.isExpanded,
                              children: [
                                if (folder.chats.isEmpty)
                                  ListTile(
                                    dense: true,
                                    title: Text(
                                      'No chats in folder',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                else
                                  ...folder.chats.map(
                                    (chat) => _chatListTile(
                                      context,
                                      chatViewModel,
                                      chat,
                                      pinMenuAsUnpin:
                                          pinnedIds.contains(chat.id),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        _chatSectionExpansionTile(
                          context: context,
                          title: 'Previous chats',
                          initiallyExpanded: true,
                          children: [
                            if (loosePreviousChats.isEmpty)
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
                              ...loosePreviousChats.map(
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

class _ChatSearchField extends StatelessWidget {
  const _ChatSearchField({
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search chats',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: onSearch,
      ),
    );
  }
}

class _ChatFilterChips extends StatelessWidget {
  const _ChatFilterChips({required this.viewModel});

  final ChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        viewModel.chatTags.isNotEmpty || viewModel.chatFolders.isNotEmpty;
    if (!hasFilters && !viewModel.hasActiveChatFilter) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          if (viewModel.hasActiveChatFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Clear'),
                onPressed: viewModel.clearChatFilters,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Archived'),
              onPressed: viewModel.showArchivedChats,
            ),
          ),
          ...viewModel.chatFolders.map(
            (folder) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: const Icon(Icons.folder_outlined, size: 18),
                label: Text(folder.name, overflow: TextOverflow.ellipsis),
                selected: viewModel.selectedChatFolder?.id == folder.id,
                onSelected: (_) => viewModel.filterChatsByFolder(folder),
              ),
            ),
          ),
          ...viewModel.chatTags.map(
            (tag) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: const Icon(Icons.tag, size: 18),
                label: Text(tag.name, overflow: TextOverflow.ellipsis),
                selected: viewModel.selectedChatTag?.id == tag.id,
                onSelected: (_) => viewModel.filterChatsByTag(tag),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatDrawerHeader extends StatelessWidget {
  const _ChatDrawerHeader({required this.onNewChat});

  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topInset + 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Chats',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'New Chat',
            onPressed: onNewChat,
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              minimumSize: const Size.square(36),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
