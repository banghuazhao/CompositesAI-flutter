import 'dart:async';

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
      title: const Text('Share chat'),
      content: const Text(
        'Messages you send after creating your link won’t be shared. '
        'Anyone with the URL can view this chat.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.link, size: 18),
          label: const Text('Copy link'),
          onPressed: () async {
            final success = await viewModel.copyShareLink(chat);
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            if (!context.mounted || !success) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          },
        ),
      ],
    ),
  );
}

/// Returns the new title if the user confirms, or null if cancelled.
Future<String?> showRenameDialog(
  BuildContext context,
  String currentTitle,
) async {
  final controller = TextEditingController(text: currentTitle);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Rename chat'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) =>
            Navigator.of(dialogContext).pop(controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<bool> _confirmDeleteChat(BuildContext context, Chat chat) async {
  final title = chat.title.trim().isEmpty ? 'this chat' : '“${chat.title}”';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete chat?'),
      content: Text(
        'Delete $title? This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed == true;
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
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) =>
            Navigator.of(dialogContext).pop(controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
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
    builder: (sheetContext) {
      final folders = viewModel.chatFolders;
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
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
              leading: const Icon(Icons.folder_off_outlined),
              title: const Text('Remove from folder'),
              enabled: chat.folderId != null && chat.folderId!.isNotEmpty,
              onTap: () {
                Navigator.pop(sheetContext);
                viewModel.moveChatToFolder(chat, null);
              },
            ),
            const Divider(height: 24),
            if (folders.isEmpty)
              ListTile(
                enabled: false,
                title: Text(
                  'No folders yet',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...folders.map(
                (folder) => ListTile(
                  leading: Icon(
                    chat.folderId == folder.id
                        ? Icons.folder
                        : Icons.folder_outlined,
                  ),
                  title: Text(folder.name, overflow: TextOverflow.ellipsis),
                  trailing: chat.folderId == folder.id
                      ? Icon(
                          Icons.check_rounded,
                          color: Theme.of(sheetContext).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    viewModel.moveChatToFolder(chat, folder.id);
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({
    required this.chat,
    required this.isSelected,
    required this.isPinned,
    required this.onSelect,
    required this.onAction,
  });

  final Chat chat;
  final bool isSelected;
  final bool isPinned;
  final VoidCallback onSelect;
  final Future<void> Function(String action) onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      selected: isSelected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.45),
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: isPinned
          ? Icon(
              Icons.push_pin_rounded,
              size: 16,
              color: isSelected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            )
          : null,
      horizontalTitleGap: isPinned ? 8 : null,
      title: Text(
        chat.title.trim().isEmpty ? 'Untitled chat' : chat.title,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Chat options',
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert_rounded,
          color: scheme.onSurfaceVariant,
        ),
        onSelected: onAction,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'pin',
            child: _MenuRow(
              icon: Icons.push_pin_outlined,
              label: isPinned ? 'Unpin' : 'Pin',
            ),
          ),
          const PopupMenuItem(
            value: 'rename',
            child: _MenuRow(
              icon: Icons.edit_outlined,
              label: 'Rename',
            ),
          ),
          const PopupMenuItem(
            value: 'share',
            child: _MenuRow(
              icon: Icons.ios_share_outlined,
              label: 'Share',
            ),
          ),
          const PopupMenuItem(
            value: 'folder',
            child: _MenuRow(
              icon: Icons.drive_file_move_outline,
              label: 'Move to folder',
            ),
          ),
          const PopupMenuItem(
            value: 'archive',
            child: _MenuRow(
              icon: Icons.archive_outlined,
              label: 'Archive',
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: _MenuRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: scheme.error,
            ),
          ),
        ],
      ),
      onTap: onSelect,
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

Widget _chatSection({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  bool initiallyExpanded = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 8),
      collapsedIconColor: scheme.onSurfaceVariant,
      iconColor: scheme.onSurfaceVariant,
      title: Text(
        title,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ),
      initiallyExpanded: initiallyExpanded,
      children: children,
    ),
  );
}

Widget _emptySectionLabel(BuildContext context, String text) {
  return ListTile(
    dense: true,
    title: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 13,
      ),
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
  Timer? _searchDebounce;
  bool _syncingSearchText = false;
  String _lastRequestedSearch = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (_syncingSearchText) return;
    if (mounted) setState(() {});

    final query = _searchController.text;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _runSearch(query);
    });
  }

  void _runSearch(String query) {
    final trimmed = query.trim();
    if (trimmed == _lastRequestedSearch) return;
    _lastRequestedSearch = trimmed;
    context.read<ChatViewModel>().searchChatHistory(query);
  }

  void _submitSearch(String query) {
    _searchDebounce?.cancel();
    _lastRequestedSearch = query.trim();
    context.read<ChatViewModel>().searchChatHistory(query);
  }

  void _clearSearch(ChatViewModel chatViewModel) {
    _searchDebounce?.cancel();
    _lastRequestedSearch = '';
    _searchController.clear();
    chatViewModel.clearChatFilters();
  }

  void _syncSearchFromViewModel(ChatViewModel chatViewModel) {
    if (_searchController.text == chatViewModel.chatSearchQuery) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_searchController.text == chatViewModel.chatSearchQuery) return;
      _syncingSearchText = true;
      _searchController.text = chatViewModel.chatSearchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
      _lastRequestedSearch = chatViewModel.chatSearchQuery.trim();
      _syncingSearchText = false;
    });
  }

  Future<void> _handleChatAction(
    BuildContext context,
    ChatViewModel viewModel,
    Chat chat,
    String action,
  ) async {
    switch (action) {
      case 'delete':
        final confirmed = await _confirmDeleteChat(context, chat);
        if (!confirmed || !context.mounted) return;
        await viewModel.deleteChat(chat);
        break;
      case 'rename':
        final newTitle = await showRenameDialog(context, chat.title);
        if (newTitle != null && newTitle.isNotEmpty) {
          await viewModel.updateChatTitle(chat, newTitle);
        }
        break;
      case 'pin':
        await viewModel.togglePin(chat);
        break;
      case 'share':
        await showShareChatDialog(context, viewModel, chat);
        break;
      case 'folder':
        await _showMoveToFolderSheet(context, viewModel, chat);
        break;
      case 'archive':
        await viewModel.archiveChat(chat);
        break;
    }
  }

  Widget _buildChatTile(
    BuildContext context,
    ChatViewModel viewModel,
    Chat chat, {
    required bool isPinned,
  }) {
    return _ChatListTile(
      chat: chat,
      isSelected: viewModel.selectedChat?.id == chat.id,
      isPinned: isPinned,
      onSelect: () {
        viewModel.selectChat(chat);
        Navigator.pop(context);
      },
      onAction: (action) => _handleChatAction(context, viewModel, chat, action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = context.watch<ChatViewModel>();
    _syncSearchFromViewModel(chatViewModel);

    final scheme = Theme.of(context).colorScheme;
    final pinnedIds = chatViewModel.pinnedChats.map((c) => c.id).toSet();
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
    final hasAnyChats = chatViewModel.pinnedChats.isNotEmpty ||
        loosePreviousChats.isNotEmpty ||
        chatViewModel.chatFolders.any((folder) => folder.chats.isNotEmpty);

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        top: false,
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
                isSearching: chatViewModel.chatSearchQuery.trim().isNotEmpty &&
                    chatViewModel.isLoadingChatFilters,
                onSearch: _submitSearch,
                onClear: () => _clearSearch(chatViewModel),
              ),
              _ChatFilterBar(viewModel: chatViewModel),
              if (chatViewModel.isLoadingChats)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (chatViewModel.hasActiveChatFilter)
                _chatSection(
                  context: context,
                  title: chatViewModel.activeChatFilterLabel,
                  initiallyExpanded: true,
                  children: [
                    if (chatViewModel.isLoadingChatFilters)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (chatViewModel.filteredChats.isEmpty)
                      _emptySectionLabel(
                        context,
                        chatViewModel.chatSearchQuery.trim().isEmpty
                            ? 'No chats found'
                            : 'No matching chats',
                      )
                    else
                      ...chatViewModel.filteredChats.map(
                        (chat) => _buildChatTile(
                          context,
                          chatViewModel,
                          chat,
                          isPinned: pinnedIds.contains(chat.id),
                        ),
                      ),
                  ],
                )
              else if (!hasAnyChats)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 36,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No chats yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Start a new chat to begin a conversation.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (chatViewModel.pinnedChats.isNotEmpty)
                  _chatSection(
                    context: context,
                    title: 'Pinned',
                    initiallyExpanded: true,
                    children: chatViewModel.pinnedChats
                        .map(
                          (chat) => _buildChatTile(
                            context,
                            chatViewModel,
                            chat,
                            isPinned: true,
                          ),
                        )
                        .toList(),
                  ),
                if (chatViewModel.chatFolders.isNotEmpty)
                  ...chatViewModel.chatFolders.map(
                    (folder) => _chatSection(
                      context: context,
                      title: folder.name,
                      initiallyExpanded: folder.isExpanded,
                      children: [
                        if (folder.chats.isEmpty)
                          _emptySectionLabel(context, 'No chats in folder')
                        else
                          ...folder.chats.map(
                            (chat) => _buildChatTile(
                              context,
                              chatViewModel,
                              chat,
                              isPinned: pinnedIds.contains(chat.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                _chatSection(
                  context: context,
                  title: 'Chats',
                  initiallyExpanded: true,
                  children: [
                    if (loosePreviousChats.isEmpty)
                      _emptySectionLabel(context, 'No chats yet')
                    else
                      ...loosePreviousChats.map(
                        (chat) => _buildChatTile(
                          context,
                          chatViewModel,
                          chat,
                          isPinned: false,
                        ),
                      ),
                  ],
                ),
              ],
              if (chatViewModel.isLoadingMoreChats)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
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
    required this.isSearching,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search chats',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: onClear,
                    ),
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
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

class _ChatFilterBar extends StatelessWidget {
  const _ChatFilterBar({required this.viewModel});

  final ChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final folders = viewModel.chatFolders;
    final showBar = folders.isNotEmpty ||
        viewModel.hasActiveChatFilter ||
        viewModel.showingArchivedChats;
    if (!showBar) {
      return const SizedBox(height: 4);
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
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
            child: FilterChip(
              avatar: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Archived'),
              selected: viewModel.showingArchivedChats,
              onSelected: (selected) {
                if (selected) {
                  viewModel.showArchivedChats();
                } else {
                  viewModel.clearChatFilters();
                }
              },
            ),
          ),
          ...folders.map(
            (folder) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: const Icon(Icons.folder_outlined, size: 18),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                selected: viewModel.selectedChatFolder?.id == folder.id,
                onSelected: (selected) {
                  if (selected) {
                    viewModel.filterChatsByFolder(folder);
                  } else {
                    viewModel.clearChatFilters();
                  }
                },
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
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topInset + 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Chats',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'New chat',
              onPressed: onNewChat,
              icon: const Icon(Icons.add_rounded, size: 20),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(36),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
