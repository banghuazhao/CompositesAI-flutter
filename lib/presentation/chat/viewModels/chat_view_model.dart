import 'dart:async';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/domain.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../util/chat_limiter.dart';
import '../../../util/feedback_id_cache.dart';

class ChatViewModel extends ChangeNotifier {
  /// Matches backend: skip = (page - 1) * 60, limit 60 when page is set.
  static const int chatListPageSize = 60;
  static const int maxPendingAttachments = 10;

  final ChatUseCase _chatUseCase;
  final AuthUseCase _authUseCase;
  final UserUseCase _userUserCase;

  bool isLoggedIn = false;
  User? user;

  final ScrollController scrollController = ScrollController();

  /// Sidebar chat history list (separate from message [scrollController]).
  final ScrollController chatListScrollController = ScrollController();

  bool isSendingMessage = false;
  bool isLoadingMessages = false;
  bool isLoadingChats = false;
  bool isLoadingChatFilters = false;
  bool isLoadingTools = false;
  bool isLoadingKnowledge = false;
  bool isUploadingFile = false;

  /// Appending next page for GET /chats/?page=n (infinite scroll).
  bool isLoadingMoreChats = false;

  /// After first page: false if last page had [chatListPageSize] items (may have more).
  bool allChatsLoaded = true;
  int _nextChatListPage = 2;

  bool isSubmittingFeedback = false;
  final Set<String> _submittingFeedbackMessageIds = <String>{};

  List<Chat> chats = [];
  List<Chat> pinnedChats = [];
  List<Chat> filteredChats = [];
  List<Chat> archivedChats = [];
  List<ChatFolder> chatFolders = [];
  List<ChatTag> chatTags = [];
  List<ChatTool> tools = [];
  List<ChatModel> models = [];
  List<ChatKnowledge> knowledgeBases = [];
  List<ChatFile> pendingFiles = [];
  List<String> uploadingFileNames = [];
  // Local bytes cache for image previews; keyed by ChatFile.id.
  // Kept alive after sending so message bubbles can show thumbnails.
  Map<String, Uint8List> pendingImageBytes = {};
  ChatModel? selectedModel;
  String chatSearchQuery = '';
  ChatTag? selectedChatTag;
  ChatFolder? selectedChatFolder;
  bool showingArchivedChats = false;
  int _chatFilterRequestId = 0;
  int _selectedChatRequestId = 0;
  Set<String> selectedToolIds = <String>{};
  Chat? selectedChat;
  String? errorMessage;

  List<Message> messages = [];
  StreamController<Message> threadResponseController =
      StreamController.broadcast();

  String? copyingMessageId;

  final ChatLimiter _chatLimiter = ChatLimiter();

  final assistantId = "asst_pxUDI3A9Q8afCqT9cqgUkWQP";

  List<String> defaultQuestions = [
    "What is CompositesAI?",
    "What are the challenges for modeling composites?",
    "Can you tell me the early history of composites?",
    "What are common misconceptions of rules of mixtures?",
    // "Calculate laminate stress",
    // "Calculates the UDFRC properties by rules of mixture",
    // "Give me some math equations.",
  ];

  ChatViewModel({
    required ChatUseCase chatUseCase,
    required AuthUseCase authUseCase,
    required UserUseCase userUserCase,
  })  : _chatUseCase = chatUseCase,
        _authUseCase = authUseCase,
        _userUserCase = userUserCase {
    chatListScrollController.addListener(_onChatListScroll);
  }

  void _onChatListScroll() {
    if (!chatListScrollController.hasClients) return;
    final pos = chatListScrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 120) return;
    loadMoreChats();
  }

  Future<void> fetchAuthSessionNew() async {
    try {
      isLoggedIn = await _authUseCase.isLoggedIn();
      if (isLoggedIn) {
        await fetchUser();
      } else {
        user = null; // Ensure user is null if not logged in
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$e');
      }
      isLoggedIn = false;
      user = null; // Ensure proper reset
    }
    notifyListeners();
  }

  Future<void> fetchUser() async {
    try {
      user = await _userUserCase.fetchMe();
      isLoggedIn = true; // Ensure isLoggedIn is updated correctly
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$e');
      }
      isLoggedIn = false; // Handle fetch user failure
      user = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    chatListScrollController.removeListener(_onChatListScroll);
    chatListScrollController.dispose();
    scrollController.dispose();
    threadResponseController.close();
    super.dispose();
  }

  /// Pull-to-refresh / init: GET /chats/?page=1 (replace list) + GET /chats/pinned.
  Future<void> fetchChats() async {
    await _loadChatLists(showLoading: true);
    await refreshChatOrganization();
  }

  Future<void> fetchTools() async {
    if (!isLoggedIn) return;

    isLoadingTools = true;
    notifyListeners();
    try {
      final toolsFuture = _chatUseCase.fetchTools();
      final modelsFuture = _chatUseCase.fetchModels();
      tools = await toolsFuture;
      models = await modelsFuture;
      selectedModel = _selectChatModel(models);

      final availableIds = tools.map((tool) => tool.id).toSet();
      selectedToolIds = selectedModel?.toolIds
              .where((toolId) => availableIds.contains(toolId))
              .toSet() ??
          <String>{};
      if (kDebugMode) {
        debugPrint(
          'fetchTools: available=${tools.length} '
          'model=${selectedModel?.id} '
          'modelToolIds=${selectedModel?.toolIds ?? []} '
          'selectedToolIds=$selectedToolIds',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchTools error: $e');
      }
      tools = [];
      models = [];
      selectedModel = null;
      selectedToolIds = <String>{};
    } finally {
      isLoadingTools = false;
      notifyListeners();
    }
  }

  Future<void> fetchKnowledgeBases() async {
    if (!isLoggedIn) return;

    isLoadingKnowledge = true;
    notifyListeners();
    try {
      knowledgeBases = await _chatUseCase.fetchKnowledgeBases();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchKnowledgeBases error: $e');
      }
      knowledgeBases = [];
    } finally {
      isLoadingKnowledge = false;
      notifyListeners();
    }
  }

  ChatModel _selectChatModel(List<ChatModel> models) {
    if (models.isEmpty) return ChatModel.fallback();

    return models.firstWhere(
      (model) => model.id == 'composites-ai-2026-02-23',
      orElse: () => models.first,
    );
  }

  bool get shouldShowModelSelector =>
      user?.isAdmin == true && (isLoadingTools || models.isNotEmpty);

  bool get isAdmin => user?.isAdmin == true;

  bool get canSelectModels => user?.isAdmin == true && models.isNotEmpty;

  void selectModel(ChatModel model) {
    selectedModel = model;
    final availableIds = tools.map((tool) => tool.id).toSet();
    selectedToolIds =
        model.toolIds.where((toolId) => availableIds.contains(toolId)).toSet();
    notifyListeners();
  }

  Future<void> pickAndUploadFiles() async {
    if (!isLoggedIn || isUploadingFile) return;

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;

      isUploadingFile = true;
      notifyListeners();

      var skipped = 0;
      for (final file in result.files) {
        if (pendingFiles.length >= maxPendingAttachments) {
          skipped++;
          break;
        }
        if (file.size <= 0) {
          skipped++;
          continue;
        }

        uploadingFileNames.add(file.name);
        notifyListeners();
        try {
          final uploaded = await _chatUseCase.uploadChatFile(
            name: file.name,
            size: file.size,
            path: file.path,
            bytes: file.bytes,
          );
          _addPendingAttachment(uploaded);
        } finally {
          uploadingFileNames.remove(file.name);
          notifyListeners();
        }
      }
      if (skipped > 0) {
        errorMessage = pendingFiles.length >= maxPendingAttachments
            ? 'Attachment limit reached ($maxPendingAttachments).'
            : 'Some empty files were skipped.';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('pickAndUploadFiles error: $e');
      }
      errorMessage = 'Failed to upload file. Please try again.';
    } finally {
      isUploadingFile = false;
      notifyListeners();
    }
  }

  Future<void> pickAndUploadImages(ImageSource source) async {
    if (!isLoggedIn || isUploadingFile) return;

    try {
      final picker = ImagePicker();
      final List<XFile> images = source == ImageSource.camera
          ? await picker
              .pickImage(source: ImageSource.camera, imageQuality: 85)
              .then((f) => f != null ? [f] : <XFile>[])
          : await picker.pickMultiImage(imageQuality: 85);

      if (images.isEmpty) return;

      isUploadingFile = true;
      notifyListeners();

      var skipped = 0;
      for (final image in images) {
        if (pendingFiles.length >= maxPendingAttachments) {
          skipped++;
          break;
        }
        final bytes = await image.readAsBytes();
        if (bytes.isEmpty) {
          skipped++;
          continue;
        }
        uploadingFileNames.add(image.name);
        notifyListeners();
        try {
          final uploaded = await _chatUseCase.uploadChatFile(
            name: image.name,
            size: bytes.length,
            bytes: bytes,
          );
          _addPendingAttachment(uploaded);
          pendingImageBytes[uploaded.id] = bytes;
        } finally {
          uploadingFileNames.remove(image.name);
          notifyListeners();
        }
      }
      if (skipped > 0) {
        errorMessage = pendingFiles.length >= maxPendingAttachments
            ? 'Attachment limit reached ($maxPendingAttachments).'
            : 'Some empty images were skipped.';
      }
    } catch (e) {
      debugPrint('pickAndUploadImages error: $e');
      errorMessage = 'Failed to upload image. Please try again.';
    } finally {
      isUploadingFile = false;
      notifyListeners();
    }
  }

  void _addPendingAttachment(ChatFile attachment) {
    final key = _attachmentKey(attachment);
    final existingIndex =
        pendingFiles.indexWhere((file) => _attachmentKey(file) == key);
    if (existingIndex >= 0) {
      pendingImageBytes.remove(pendingFiles[existingIndex].id);
      pendingFiles[existingIndex] = attachment;
      return;
    }
    pendingFiles.add(attachment);
  }

  String _attachmentKey(ChatFile file) {
    if (file.isKnowledgeCollection) return 'collection:${file.id}';
    if (file.isKnowledgeFile) return 'knowledge-file:${file.id}';
    return 'upload:${file.name}:${file.size}';
  }

  void clearPendingFiles() {
    pendingFiles = [];
    pendingImageBytes.clear();
    notifyListeners();
  }

  void removePendingFile(ChatFile file) {
    pendingFiles.removeWhere((item) => item.id == file.id);
    pendingImageBytes.remove(file.id);
    notifyListeners();
  }

  void toggleKnowledgeCollection(ChatKnowledge knowledge) {
    _togglePendingAttachment(knowledge.toCollectionAttachment());
  }

  void toggleKnowledgeFile(ChatFile file) {
    _togglePendingAttachment(file);
  }

  bool isKnowledgeSelected(String id) {
    return pendingFiles.any((file) => file.id == id);
  }

  void _togglePendingAttachment(ChatFile attachment) {
    final key = _attachmentKey(attachment);
    final index =
        pendingFiles.indexWhere((file) => _attachmentKey(file) == key);
    if (index >= 0) {
      final removed = pendingFiles.removeAt(index);
      pendingImageBytes.remove(removed.id);
    } else {
      if (pendingFiles.length >= maxPendingAttachments) {
        errorMessage = 'Attachment limit reached ($maxPendingAttachments).';
        notifyListeners();
        return;
      }
      _addPendingAttachment(attachment);
    }
    notifyListeners();
  }

  /// GET /chats/{chatId}/pinned — use when you need server truth for Pin vs Unpin.
  Future<bool> fetchChatPinned(String chatId) {
    return _chatUseCase.fetchChatPinned(chatId);
  }

  /// Next page for GET /chats/?page=n; append to [chats]. Stops when empty or short page (see [chatListPageSize]).
  Future<void> loadMoreChats() async {
    if (!isLoggedIn) return;
    if (hasActiveChatFilter) return;
    if (allChatsLoaded || isLoadingMoreChats || isLoadingChats) return;

    isLoadingMoreChats = true;
    notifyListeners();
    try {
      final list = await _chatUseCase.fetchChats(page: _nextChatListPage);
      if (kDebugMode) {
        debugPrint(
            'loadMoreChats: page $_nextChatListPage returned ${list.length} chats');
      }
      if (list.isEmpty) {
        allChatsLoaded = true;
      } else {
        final existingIds = chats.map((c) => c.id).toSet();
        for (final c in list) {
          if (!existingIds.contains(c.id)) {
            chats.add(c);
            existingIds.add(c.id);
          }
        }
        if (list.length < chatListPageSize) {
          allChatsLoaded = true;
        } else {
          _nextChatListPage++;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('loadMoreChats error: $e');
      }
      errorMessage = 'Failed to load more chats.';
    } finally {
      isLoadingMoreChats = false;
      notifyListeners();
    }
  }

  bool get hasActiveChatFilter =>
      chatSearchQuery.trim().isNotEmpty ||
      selectedChatTag != null ||
      selectedChatFolder != null ||
      showingArchivedChats;

  String get activeChatFilterLabel {
    if (chatSearchQuery.trim().isNotEmpty) {
      return 'Search "${chatSearchQuery.trim()}"';
    }
    if (selectedChatTag != null) return '#${selectedChatTag!.name}';
    if (selectedChatFolder != null) return selectedChatFolder!.name;
    if (showingArchivedChats) return 'Archived';
    return 'Previous chats';
  }

  Future<void> refreshChatOrganization() async {
    if (!isLoggedIn) return;
    try {
      final tagsFuture = _chatUseCase.fetchAllTags();
      final foldersFuture = _chatUseCase.fetchFolders();
      chatTags = await tagsFuture;
      chatFolders = await foldersFuture;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('refreshChatOrganization error: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> searchChatHistory(String query) async {
    final trimmed = query.trim();
    _chatFilterRequestId++;
    chatSearchQuery = trimmed;
    selectedChatTag = null;
    selectedChatFolder = null;
    showingArchivedChats = false;
    isLoadingChatFilters = false;
    if (trimmed.isEmpty) {
      filteredChats = [];
      notifyListeners();
      return;
    }

    filteredChats = _localSearchChats(trimmed);
    notifyListeners();
  }

  Future<void> filterChatsByTag(ChatTag tag) async {
    final requestId = ++_chatFilterRequestId;
    chatSearchQuery = '';
    selectedChatTag = tag;
    selectedChatFolder = null;
    showingArchivedChats = false;
    isLoadingChatFilters = true;
    notifyListeners();
    try {
      final chats = await _chatUseCase.fetchChatsByTag(tag.name);
      if (requestId != _chatFilterRequestId) return;
      filteredChats = chats;
    } catch (e) {
      if (requestId != _chatFilterRequestId) return;
      if (kDebugMode) debugPrint('filterChatsByTag error: $e');
      errorMessage = 'Failed to load tagged chats.';
      filteredChats = [];
    } finally {
      if (requestId == _chatFilterRequestId) {
        isLoadingChatFilters = false;
        notifyListeners();
      }
    }
  }

  Future<void> filterChatsByFolder(ChatFolder folder) async {
    final requestId = ++_chatFilterRequestId;
    chatSearchQuery = '';
    selectedChatTag = null;
    selectedChatFolder = folder;
    showingArchivedChats = false;
    isLoadingChatFilters = true;
    notifyListeners();
    try {
      final chats = await _chatUseCase.fetchChatsByFolder(folder.id);
      if (requestId != _chatFilterRequestId) return;
      filteredChats = chats;
    } catch (e) {
      if (requestId != _chatFilterRequestId) return;
      if (kDebugMode) debugPrint('filterChatsByFolder error: $e');
      errorMessage = 'Failed to load folder chats.';
      filteredChats = [];
    } finally {
      if (requestId == _chatFilterRequestId) {
        isLoadingChatFilters = false;
        notifyListeners();
      }
    }
  }

  Future<void> showArchivedChats() async {
    final requestId = ++_chatFilterRequestId;
    chatSearchQuery = '';
    selectedChatTag = null;
    selectedChatFolder = null;
    showingArchivedChats = true;
    isLoadingChatFilters = true;
    notifyListeners();
    try {
      final chats = await _chatUseCase.fetchArchivedChats();
      if (requestId != _chatFilterRequestId) return;
      archivedChats = chats;
      filteredChats = archivedChats;
    } catch (e) {
      if (requestId != _chatFilterRequestId) return;
      if (kDebugMode) debugPrint('showArchivedChats error: $e');
      errorMessage = 'Failed to load archived chats.';
      filteredChats = [];
    } finally {
      if (requestId == _chatFilterRequestId) {
        isLoadingChatFilters = false;
        notifyListeners();
      }
    }
  }

  void clearChatFilters() {
    _chatFilterRequestId++;
    chatSearchQuery = '';
    selectedChatTag = null;
    selectedChatFolder = null;
    showingArchivedChats = false;
    filteredChats = [];
    notifyListeners();
  }

  List<Chat> _localSearchChats(String query) {
    final normalized = query.toLowerCase();
    final allKnownChats = _mergeUniqueChats([
      ...pinnedChats,
      ...chats,
      ...chatFolders.expand((folder) => folder.chats),
      ...filteredChats,
    ]);
    return allKnownChats
        .where((chat) => chat.title.toLowerCase().contains(normalized))
        .toList();
  }

  List<Chat> _mergeUniqueChats(Iterable<Chat> source) {
    final seenIds = <String>{};
    final merged = <Chat>[];
    for (final chat in source) {
      if (chat.id.isEmpty || seenIds.contains(chat.id)) continue;
      seenIds.add(chat.id);
      merged.add(chat);
    }
    return merged;
  }

  Future<void> _loadChatLists({required bool showLoading}) async {
    isLoadingMoreChats = false;
    if (showLoading) {
      isLoadingChats = true;
      notifyListeners();
    }
    allChatsLoaded = true;
    try {
      final list = await _chatUseCase.fetchChats(page: 1);
      if (kDebugMode) {
        debugPrint('fetchChats page=1: API returned ${list.length} chats');
      }
      chats = list;
      if (list.isEmpty || list.length < chatListPageSize) {
        allChatsLoaded = true;
      } else {
        allChatsLoaded = false;
        _nextChatListPage = 2;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchChats error: $e');
      }
      chats = [];
      allChatsLoaded = true;
    }
    try {
      pinnedChats = await _chatUseCase.fetchPinnedChats();
      if (kDebugMode) {
        debugPrint(
            'fetchPinnedChats: API returned ${pinnedChats.length} pinned');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchPinnedChats error: $e');
      }
      pinnedChats = [];
    } finally {
      if (showLoading) {
        isLoadingChats = false;
      }
      notifyListeners();
    }
  }

  Future<void> updateNewChat(Chat newChat) async {
    await fetchChats();
    final index = chats.indexWhere((chat) => chat.id == newChat.id);
    if (index >= 0) {
      selectedChat = chats[index];
    } else {
      chats.insert(0, newChat);
      selectedChat = newChat;
      notifyListeners();
    }
  }

  void onTapNewChat() {
    _selectedChatRequestId++;
    selectedChat = null;
    messages = [];
    notifyListeners();
  }

  Future<void> deleteChat(Chat chat) async {
    try {
      await _chatUseCase.deleteChat(chat);
      chats.removeWhere((c) => c.id == chat.id);
      pinnedChats.removeWhere((c) => c.id == chat.id);
      filteredChats.removeWhere((c) => c.id == chat.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete error: $e');
      errorMessage = 'Failed to delete chat. Please try again.';
      notifyListeners();
    }
  }

  Future<void> updateChatTitle(Chat chat, String newTitle) async {
    try {
      final updated = await _chatUseCase.updateChatTitle(chat, newTitle);
      _replaceChatInLists(updated);
    } catch (e) {
      if (kDebugMode) debugPrint('Update error: $e');
      errorMessage = 'Failed to rename chat. Please try again.';
      notifyListeners();
    }
  }

  /// POST /api/v1/chats/{id}/pin (no body, server toggles). On success, reloads
  /// [chats] and [pinnedChats] from GET /chats and GET /chats/pinned.
  Future<void> togglePin(Chat chat) async {
    try {
      await _chatUseCase.togglePin(chat);
      await _loadChatLists(showLoading: false);
    } catch (e) {
      if (kDebugMode) debugPrint('Pin/Unpin error: $e');
      errorMessage = 'Failed to operate. Please try again.';
      notifyListeners();
    }
  }

  Future<void> archiveChat(Chat chat) async {
    try {
      await _chatUseCase.archiveChat(chat);
      chats.removeWhere((c) => c.id == chat.id);
      pinnedChats.removeWhere((c) => c.id == chat.id);
      filteredChats.removeWhere((c) => c.id == chat.id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Archive error: $e');
      errorMessage = 'Failed to archive chat. Please try again.';
      notifyListeners();
    }
  }

  Future<void> moveChatToFolder(Chat chat, String? folderId) async {
    try {
      final updated = await _chatUseCase.updateChatFolder(chat, folderId);
      _replaceChatInLists(updated);
      await refreshChatOrganization();
    } catch (e) {
      if (kDebugMode) debugPrint('Move chat error: $e');
      errorMessage = 'Failed to move chat. Please try again.';
      notifyListeners();
    }
  }

  Future<void> createFolderAndMoveChat(Chat chat, String folderName) async {
    final trimmed = folderName.trim();
    if (trimmed.isEmpty) return;
    try {
      final folder = await _chatUseCase.createFolder(trimmed);
      await moveChatToFolder(chat, folder.id);
    } catch (e) {
      if (kDebugMode) debugPrint('Create folder error: $e');
      errorMessage = 'Failed to create folder. Please try again.';
      notifyListeners();
    }
  }

  Future<void> addTagToChat(Chat chat, String tagName) async {
    final trimmed = tagName.trim();
    if (trimmed.isEmpty) return;
    try {
      await _chatUseCase.addChatTag(chat.id, trimmed);
      await refreshChatOrganization();
    } catch (e) {
      if (kDebugMode) debugPrint('Add tag error: $e');
      errorMessage = 'Failed to add tag. Please try again.';
      notifyListeners();
    }
  }

  Future<List<ChatTag>> fetchTagsForChat(Chat chat) {
    return _chatUseCase.fetchChatTags(chat.id);
  }

  Future<void> removeTagFromChat(Chat chat, ChatTag tag) async {
    try {
      await _chatUseCase.removeChatTag(chat.id, tag.name);
      await refreshChatOrganization();
      if (selectedChatTag?.id == tag.id) {
        clearChatFilters();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Remove tag error: $e');
      errorMessage = 'Failed to remove tag. Please try again.';
      notifyListeners();
    }
  }

  void _replaceChatInLists(Chat updated) {
    void replaceIn(List<Chat> list) {
      final index = list.indexWhere((chat) => chat.id == updated.id);
      if (index >= 0) list[index] = updated;
    }

    replaceIn(chats);
    replaceIn(pinnedChats);
    replaceIn(filteredChats);
    if (selectedChat?.id == updated.id) selectedChat = updated;
    notifyListeners();
  }

  /// Calls share API, copies link to clipboard. Returns true if success. No need to store the link.
  Future<bool> copyShareLink(Chat chat) async {
    try {
      final link = await _chatUseCase.shareChat(chat);
      await Clipboard.setData(ClipboardData(text: link));
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Share error: $e');
      errorMessage = 'Failed to create share link. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    isLoggedIn = await _authUseCase.isLoggedIn();
    debugPrint("isLoggedIn: $isLoggedIn");
    if (isLoggedIn) {
      await fetchUser();
    } else {
      user = null; // Ensure user is null if not logged in
    }
    notifyListeners();
  }

  /// Clears chat UI state when the session ends (logout, account deletion, QA env switch).
  /// Call after auth token is invalidated so the next login does not see another user's thread.
  Future<void> clearChatStateOnLogout() async {
    selectedChat = null;
    messages = [];
    chats = [];
    pinnedChats = [];
    filteredChats = [];
    archivedChats = [];
    chatFolders = [];
    chatTags = [];
    tools = [];
    models = [];
    knowledgeBases = [];
    selectedModel = null;
    pendingFiles = [];
    uploadingFileNames = [];
    pendingImageBytes.clear();
    selectedToolIds = <String>{};
    allChatsLoaded = true;
    _nextChatListPage = 2;
    isLoadingMessages = false;
    isLoadingChats = false;
    isLoadingChatFilters = false;
    isLoadingKnowledge = false;
    isLoadingMoreChats = false;
    isSendingMessage = false;
    errorMessage = null;
    copyingMessageId = null;
    chatSearchQuery = '';
    selectedChatTag = null;
    selectedChatFolder = null;
    showingArchivedChats = false;
    _submittingFeedbackMessageIds.clear();
    isSubmittingFeedback = false;

    if (!threadResponseController.isClosed) {
      await threadResponseController.close();
    }
    threadResponseController = StreamController<Message>.broadcast();

    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
    if (chatListScrollController.hasClients) {
      chatListScrollController.jumpTo(0);
    }

    notifyListeners();
  }

  void setSendingMessage(bool value) {
    isSendingMessage = value;
    notifyListeners();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> selectChat(Chat chat) async {
    final requestId = ++_selectedChatRequestId;
    selectedChat = chat;
    isLoadingMessages = true;
    notifyListeners();
    try {
      final loadedMessages = await _chatUseCase.fetchMessages(chat);
      if (requestId != _selectedChatRequestId) return;

      // Restore feedbackId from local cache so update calls are reliable
      // even after page rebuild / app restart.
      for (final m in loadedMessages) {
        final cached = FeedbackIdCache.getFeedbackId(chat.id, m.id);
        if (cached != null) {
          m.feedbackId = cached;
        }
      }
      messages = loadedMessages;
    } catch (e) {
      if (requestId != _selectedChatRequestId) return;
      if (kDebugMode) debugPrint('selectChat error: $e');
      messages = [];
      errorMessage = 'Failed to load chat messages. Please try again.';
    } finally {
      if (requestId == _selectedChatRequestId) {
        isLoadingMessages = false;
        notifyListeners();
        scrollToBottom();
      }
    }
  }

  Future<bool> reachChatLimit() async {
    return _chatLimiter.reachChatLimit();
  }

  Future<void> sendInputMessage(String text) async {
    if (isUploadingFile || isSendingMessage) return;
    if (await _chatLimiter.reachChatLimit()) {
      errorMessage = 'Daily chat limit reached (50/day)';
      notifyListeners();
      return;
    }

    final attachments = List<ChatFile>.from(pendingFiles);
    final prompt =
        text.trim().isEmpty ? _attachmentOnlyPrompt(attachments) : text.trim();
    if (prompt.isEmpty) return;

    final userMessage = Message(
      role: 'user',
      content: prompt,
      files: attachments,
    );
    pendingFiles = [];

    if (selectedChat != null && messages.isNotEmpty) {
      userMessage.parentId = messages.last.id;
      messages.last.childrenIds = [userMessage.id];
    }
    messages.add(userMessage);
    setSendingMessage(true);
    scrollToBottom();

    try {
      if (selectedChat == null) {
        final newChat = await _chatUseCase.createChat(userMessage);
        selectedChat = newChat;
        await updateNewChat(newChat);
      }

      final messagesForRequest = List<Message>.from(messages);
      final toolIdsForRequest = selectedToolIds.toList(growable: false);
      final sendId = Uuid().v4();

      streamBuilder() => _chatUseCase.sendMessages(
            messagesForRequest,
            selectedChat!,
            sendId,
            toolIds: toolIdsForRequest,
            model: selectedModel,
          );

      await _processResponseStream(streamBuilder, sendId);
    } catch (e) {
      if (kDebugMode) debugPrint('sendInputMessage error: $e');
      setSendingMessage(false);
      errorMessage = 'Failed to send message. Please try again.';
      notifyListeners();
    }
  }

  String _attachmentOnlyPrompt(List<ChatFile> attachments) {
    if (attachments.isEmpty) return '';
    final names = attachments
        .map((file) => file.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) return 'Please review the attached file(s).';
    return 'Please review the attached file(s): ${names.join(', ')}.';
  }

  Future<void> _processResponseStream(
      Stream<ChatStreamEvent> Function() streamBuilder, String sendId) async {
    threadResponseController = StreamController<Message>.broadcast();
    Message assistantMessage = Message(role: 'assistant', content: '');
    if (selectedModel != null) {
      assistantMessage.model = selectedModel!.id;
      assistantMessage.modelName = selectedModel!.name;
    }
    if (messages.isNotEmpty) {
      assistantMessage.parentId = messages.last.id;
      messages.last.childrenIds = [assistantMessage.id];
    }
    messages.add(assistantMessage);

    selectedChat?.updatedAt = DateTime.now().microsecondsSinceEpoch ~/ 1000;
    try {
      final stream = streamBuilder();

      await for (final response in stream) {
        if (response.error != null) {
          throw Exception(response.error);
        }

        if (response.status != null && !response.status!.hidden) {
          assistantMessage.statusHistory.add(response.status!);
        }

        if (response.hasContent) {
          if (response.replacesContent) {
            assistantMessage.content = response.content;
          } else {
            assistantMessage.content += response.content;
          }
          threadResponseController.add(Message(
            role: 'assistant',
            content: response.content,
            parentId: messages.last.id,
          ));
        }
        notifyListeners();
        scrollToBottom();
      }
      if (assistantMessage.content.trim().isEmpty &&
          assistantMessage.statusHistory.isEmpty) {
        throw Exception('No response received from the chat service.');
      }
      await _chatLimiter.incrementChatCount();
      assistantMessage.thinkingElapsed = math.max(
          0,
          (DateTime.now().millisecondsSinceEpoch -
                  assistantMessage.timestamp) ~/
              1000);
      assistantMessage.isDone = true;
      selectedChat?.updatedAt = DateTime.now().microsecondsSinceEpoch ~/ 1000;
      await _chatUseCase.updateChatMessage(assistantMessage, selectedChat!);
      await _chatUseCase.persistMessages(messages, selectedChat!);
    } catch (error) {
      if (assistantMessage.content.trim().isEmpty &&
          assistantMessage.statusHistory.isEmpty) {
        messages.removeWhere((message) => message.id == assistantMessage.id);
        final parentId = assistantMessage.parentId;
        if (parentId != null) {
          final parentIndex =
              messages.indexWhere((message) => message.id == parentId);
          if (parentIndex >= 0) {
            messages[parentIndex].childrenIds = [];
          }
        }
      }
      errorMessage = 'Failed to receive response. Please try again.';
      threadResponseController.addError(error);
      if (kDebugMode) debugPrint('Error receiving messages: $error');
      notifyListeners();
    } finally {
      await threadResponseController.close();
      setSendingMessage(false);
    }
  }

  Future<void> onDefaultQuestionsTapped(int index) async {
    final question = defaultQuestions[index];
    await sendInputMessage(question);
  }

  void copyMessage(Message message) async {
    await Clipboard.setData(ClipboardData(text: message.content));
    copyingMessageId = message.id;
    notifyListeners();
    Future.delayed(Duration(seconds: 1), () {
      copyingMessageId = null;
      notifyListeners();
    });
  }

  bool isMessageCopying(Message message) {
    return copyingMessageId == message.id;
  }

  bool isSubmittingFeedbackFor(Message message) {
    return _submittingFeedbackMessageIds.contains(message.id);
  }

  Future<bool> submitMessageFeedback({
    required Message message,
    required int goodBadRating, // 1 for Good, -1 for Bad
    required int detailsRating, // 1..10 from dialog
    required List<String> reasons,
    String? comment,
    required int messageIndex,
  }) async {
    if (selectedChat == null) return false;
    if (_submittingFeedbackMessageIds.contains(message.id)) return false;

    _submittingFeedbackMessageIds.add(message.id);

    isSubmittingFeedback = true;
    notifyListeners();
    try {
      final feedbackId = await _chatUseCase.submitMessageFeedback(
        chat: selectedChat!,
        message: message,
        goodBadRating: goodBadRating,
        detailsRating: detailsRating,
        reasons: reasons,
        comment: comment,
        messageIndex: messageIndex,
      );
      message.feedbackId = feedbackId;
      message.feedbackRating = goodBadRating;
      message.feedbackDetailsRating = detailsRating;
      message.feedbackReasons = List<String>.from(reasons);
      message.feedbackComment = comment;
      await FeedbackIdCache.setFeedbackId(
        selectedChat!.id,
        message.id,
        feedbackId,
      );
      await _chatUseCase.persistMessages(messages, selectedChat!);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('submitMessageFeedback error: $e');
      errorMessage = 'Failed to submit feedback. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _submittingFeedbackMessageIds.remove(message.id);
      isSubmittingFeedback = _submittingFeedbackMessageIds.isEmpty;
      notifyListeners();
    }
  }
}
