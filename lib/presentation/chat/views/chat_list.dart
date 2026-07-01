import 'dart:async';

import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_tag.dart';
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
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ChatTagsSheet(
      viewModel: viewModel,
      chat: chat,
    ),
  );
}

class _ChatTagsSheet extends StatefulWidget {
  const _ChatTagsSheet({
    required this.viewModel,
    required this.chat,
  });

  final ChatViewModel viewModel;
  final Chat chat;

  @override
  State<_ChatTagsSheet> createState() => _ChatTagsSheetState();
}

class _ChatTagsSheetState extends State<_ChatTagsSheet> {
  final TextEditingController _tagController = TextEditingController();
  List<ChatTag> _tags = const [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final tags = await widget.viewModel.fetchTagsForChat(widget.chat);
      if (!mounted) return;
      setState(() => _tags = tags);
    } catch (_) {
      if (!mounted) return;
      setState(() => _tags = const []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addTag(String value) async {
    final name = value.trim();
    if (name.isEmpty || _isSaving) return;
    if (_tags.any((tag) => tag.name.toLowerCase() == name.toLowerCase())) {
      _tagController.clear();
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.viewModel.addTagToChat(widget.chat, name);
      if (!mounted) return;
      _tagController.clear();
      await _loadTags();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeTag(ChatTag tag) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.viewModel.removeTagFromChat(widget.chat, tag);
      if (!mounted) return;
      await _loadTags();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentNames = _tags.map((tag) => tag.name.toLowerCase()).toSet();
    final suggestions = widget.viewModel.chatTags
        .where((tag) => !currentNames.contains(tag.name.toLowerCase()))
        .toList();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 540),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Manage tags',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_isSaving)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Add a tag',
                  prefixIcon: const Icon(Icons.sell_outlined),
                  suffixIcon: IconButton(
                    tooltip: 'Add tag',
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _addTag(_tagController.text),
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _addTag,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          _TagSection(
                            title: 'On this chat',
                            emptyText: 'No tags yet',
                            children: _tags
                                .map(
                                  (tag) => InputChip(
                                    avatar: const Icon(Icons.tag, size: 16),
                                    label: _ChipLabel(tag.name),
                                    onDeleted: () => _removeTag(tag),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 18),
                          _TagSection(
                            title: 'Suggested tags',
                            emptyText: 'No other tags available',
                            children: suggestions
                                .map(
                                  (tag) => ActionChip(
                                    avatar: const Icon(
                                      Icons.add_rounded,
                                      size: 16,
                                    ),
                                    label: _ChipLabel(tag.name),
                                    onPressed: () => _addTag(tag.name),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Text(
            emptyText,
            style: TextStyle(color: Colors.grey.shade500),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
      ],
    );
  }
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

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    if (_searchController.text != chatViewModel.chatSearchQuery) {
      _syncingSearchText = true;
      _searchController.text = chatViewModel.chatSearchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
      _lastRequestedSearch = chatViewModel.chatSearchQuery.trim();
      _syncingSearchText = false;
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
              isSearching: chatViewModel.chatSearchQuery.trim().isNotEmpty &&
                  chatViewModel.isLoadingChatFilters,
              onSearch: _submitSearch,
              onClear: () => _clearSearch(chatViewModel),
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
    required this.isSearching,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final bool isSearching;

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
                label: _ChipLabel(folder.name),
                selected: viewModel.selectedChatFolder?.id == folder.id,
                onSelected: (selected) => selected
                    ? viewModel.filterChatsByFolder(folder)
                    : viewModel.clearChatFilters(),
              ),
            ),
          ),
          ...viewModel.chatTags.map(
            (tag) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: const Icon(Icons.tag, size: 18),
                label: _ChipLabel(tag.name),
                selected: viewModel.selectedChatTag?.id == tag.id,
                onSelected: (selected) => selected
                    ? viewModel.filterChatsByTag(tag)
                    : viewModel.clearChatFilters(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
