import 'dart:async';

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

import '../controllers/chat_attachment_controller.dart';
import '../controllers/chat_conversation_controller.dart';
import '../model/chat_error.dart';

class ChatViewModel extends ChangeNotifier {
  /// Matches backend: skip = (page - 1) * 60, limit 60 when page is set.
  static const int chatListPageSize = 60;
  static const int suggestedQuestionCount = 5;
  static const String _nonAdminDefaultModelId = ChatModel.defaultModelId;
  static const String _fallbackDefaultModelId = 'gpt-4.1';
  static const List<String> _fallbackDefaultQuestions = [
    'What are the main differences between carbon-fiber and glass-fiber composites?',
    "How do I estimate a unidirectional composite's longitudinal Young's modulus using the rule of mixtures?",
    'What causes delamination in composite laminates, and how can it be prevented?',
    'How do fiber orientation and stacking sequence affect laminate performance?',
    'Which CompositesAI calculator should I use for my composite analysis?',
  ];

  final ChatUseCase _chatUseCase;
  final AuthUseCase _authUseCase;
  final UserUseCase _userUserCase;
  late final ChatConversationController _conversation;
  late final ChatAttachmentController _attachments;

  bool isLoggedIn = false;
  User? user;

  final ScrollController scrollController = ScrollController();

  /// Sidebar chat history list (separate from message [scrollController]).
  final ScrollController chatListScrollController = ScrollController();

  bool isLoadingChats = false;
  bool isLoadingChatFilters = false;
  bool isLoadingTools = false;

  /// Appending next page for GET /chats/?page=n (infinite scroll).
  bool isLoadingMoreChats = false;

  /// After first page: false if last page had [chatListPageSize] items (may have more).
  bool allChatsLoaded = true;
  int _nextChatListPage = 2;

  List<Chat> chats = [];
  List<Chat> pinnedChats = [];
  List<Chat> filteredChats = [];
  List<Chat> archivedChats = [];
  List<ChatFolder> chatFolders = [];
  List<ChatTool> tools = [];
  List<ChatModel> models = [];
  ChatModel? selectedModel;
  String chatSearchQuery = '';
  ChatFolder? selectedChatFolder;
  bool showingArchivedChats = false;
  int _chatFilterRequestId = 0;
  Set<String> selectedToolIds = <String>{};
  ChatConfiguration _chatConfiguration = const ChatConfiguration(
    defaultModelIds: [_fallbackDefaultModelId],
    defaultPrompts: _fallbackDefaultQuestions,
  );
  ChatErrorNotice? _activeError;
  AsyncCallback? _activeErrorRetry;
  int _nextErrorId = 0;
  bool _isDisposed = false;

  final assistantId = "asst_pxUDI3A9Q8afCqT9cqgUkWQP";

  List<String> defaultQuestions = List.of(_fallbackDefaultQuestions);

  ChatViewModel({
    required ChatUseCase chatUseCase,
    required AuthUseCase authUseCase,
    required UserUseCase userUserCase,
  })  : _chatUseCase = chatUseCase,
        _authUseCase = authUseCase,
        _userUserCase = userUserCase {
    _conversation = ChatConversationController(
      chatUseCase: chatUseCase,
      onChatCreated: updateNewChat,
      onError: _reportError,
      onScrollRequested: ({required force}) => scrollToBottom(force: force),
    )..addListener(_forwardConversationChange);
    _attachments = ChatAttachmentController(
      chatUseCase: chatUseCase,
      canUseChat: () => isLoggedIn,
      onError: _reportError,
    )..addListener(_forwardAttachmentChange);
    chatListScrollController.addListener(_onChatListScroll);
  }

  bool get isSendingMessage => _conversation.isSendingMessage;
  bool get isLoadingMessages => _conversation.isLoadingMessages;
  bool get isSubmittingFeedback => _conversation.isSubmittingFeedback;
  Chat? get selectedChat => _conversation.selectedChat;
  set selectedChat(Chat? value) => _conversation.selectedChat = value;
  List<Message> get messages => _conversation.messages;
  set messages(List<Message> value) => _conversation.messages = value;
  StreamController<Message> get threadResponseController =>
      _conversation.threadResponseController;
  String? get copyingMessageId => _conversation.copyingMessageId;
  bool get isLoadingKnowledge => _attachments.isLoadingKnowledge;
  bool get isUploadingFile => _attachments.isUploadingFile;
  List<ChatKnowledge> get knowledgeBases => _attachments.knowledgeBases;
  List<ChatFile> get pendingFiles => _attachments.pendingFiles;
  List<String> get uploadingFileNames => _attachments.uploadingFileNames;
  Map<String, Uint8List> get pendingImageBytes =>
      _attachments.imagePreviewBytes;
  ChatErrorNotice? get activeError => _activeError;
  String? get errorMessage => _activeError?.message;

  void _forwardConversationChange() => notifyListeners();
  void _forwardAttachmentChange() => notifyListeners();

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  void _reportError(
    ChatFailure failure, {
    AsyncCallback? retry,
  }) {
    if (_isDisposed) return;
    final current = _activeError;
    if (current?.failure.type == failure.type &&
        current?.failure.operation == failure.operation &&
        current?.message == failure.message) {
      _activeErrorRetry = retry ?? _activeErrorRetry;
      return;
    }

    _activeErrorRetry = retry;
    _activeError = ChatErrorNotice(
      id: ++_nextErrorId,
      failure: failure,
      hasRetry: retry != null,
    );
    notifyListeners();
  }

  void clearErrorMessage(String displayedMessage) {
    final error = _activeError;
    if (error == null || error.message != displayedMessage) return;
    dismissError(error.id);
  }

  void dismissError(int errorId) {
    if (_activeError?.id != errorId) return;
    _activeError = null;
    _activeErrorRetry = null;
    notifyListeners();
  }

  Future<void> retryError(int errorId) async {
    if (_isDisposed) return;
    final notice = _activeError;
    final retry = _activeErrorRetry;
    if (notice?.id != errorId || retry == null) return;

    _activeError = null;
    _activeErrorRetry = null;
    notifyListeners();
    try {
      await retry();
    } catch (error) {
      _reportError(
        ChatErrorMapper.from(
          error,
          operation: notice!.failure.operation,
          fallbackMessage: notice.message,
        ),
        retry: retry,
      );
    }
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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.authenticate,
        ),
        retry: fetchAuthSessionNew,
      );
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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.authenticate,
        ),
        retry: fetchUser,
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    chatListScrollController.removeListener(_onChatListScroll);
    _conversation.removeListener(_forwardConversationChange);
    _attachments.removeListener(_forwardAttachmentChange);
    _conversation.dispose();
    _attachments.dispose();
    chatListScrollController.dispose();
    scrollController.dispose();
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
      try {
        _chatConfiguration = await _chatUseCase.fetchChatConfiguration();
      } catch (e) {
        _chatConfiguration = const ChatConfiguration(
          defaultModelIds: [_fallbackDefaultModelId],
          defaultPrompts: _fallbackDefaultQuestions,
        );
        if (kDebugMode) {
          debugPrint('fetchChatConfiguration error: $e');
        }
      }

      final toolsFuture = _chatUseCase.fetchTools();
      final modelsFuture = _chatUseCase.fetchModels();
      tools = await toolsFuture;
      models = await modelsFuture;
      selectedModel = _selectChatModel(
        models,
        preferredModelIds: isAdmin
            ? _chatConfiguration.defaultModelIds
            : const [_nonAdminDefaultModelId],
        requirePreferredModel: !isAdmin,
      );
      _updateDefaultQuestions();

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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.loadTools,
        ),
        retry: fetchTools,
      );
    } finally {
      isLoadingTools = false;
      notifyListeners();
    }
  }

  Future<void> fetchKnowledgeBases() async {
    await _attachments.fetchKnowledgeBases();
  }

  ChatModel _selectChatModel(
    List<ChatModel> models, {
    required List<String> preferredModelIds,
    bool requirePreferredModel = false,
  }) {
    if (models.isEmpty) {
      final fallbackId = preferredModelIds.isNotEmpty
          ? preferredModelIds.first
          : _fallbackDefaultModelId;
      return ChatModel.fallback(id: fallbackId, name: fallbackId);
    }

    for (final modelId in preferredModelIds) {
      for (final model in models) {
        if (model.id == modelId) return model;
      }
    }
    if (requirePreferredModel && preferredModelIds.isNotEmpty) {
      return ChatModel.fallback(
        id: preferredModelIds.first,
        name: 'CompositesAI',
      );
    }
    return models.first;
  }

  void _updateDefaultQuestions() {
    final configuredQuestions =
        selectedModel?.suggestionPrompts ?? _chatConfiguration.defaultPrompts;
    final questions = <String>[];
    final normalizedQuestions = <String>{};

    for (final question in [
      ...configuredQuestions,
      ..._fallbackDefaultQuestions,
    ]) {
      final trimmedQuestion = question.trim();
      if (trimmedQuestion.isEmpty ||
          !normalizedQuestions.add(trimmedQuestion.toLowerCase())) {
        continue;
      }
      questions.add(trimmedQuestion);
      if (questions.length == suggestedQuestionCount) break;
    }

    defaultQuestions = questions;
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
    _updateDefaultQuestions();
    notifyListeners();
  }

  Future<void> pickAndUploadFiles() async {
    await _attachments.pickAndUploadFiles();
  }

  Future<void> pickAndUploadImages(ImageSource source) async {
    await _attachments.pickAndUploadImages(source);
  }

  void clearPendingFiles() {
    _attachments.clearPendingFiles();
  }

  void removePendingFile(ChatFile file) {
    _attachments.removePendingFile(file);
  }

  void toggleKnowledgeCollection(ChatKnowledge knowledge) {
    _attachments.toggleKnowledgeCollection(knowledge);
  }

  void toggleKnowledgeFile(ChatFile file) {
    _attachments.toggleKnowledgeFile(file);
  }

  bool isKnowledgeSelected(String id) {
    return _attachments.isKnowledgeSelected(id);
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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.loadMoreChats,
        ),
        retry: loadMoreChats,
      );
    } finally {
      isLoadingMoreChats = false;
      notifyListeners();
    }
  }

  bool get hasActiveChatFilter =>
      chatSearchQuery.trim().isNotEmpty ||
      selectedChatFolder != null ||
      showingArchivedChats;

  String get activeChatFilterLabel {
    if (chatSearchQuery.trim().isNotEmpty) {
      return 'Search "${chatSearchQuery.trim()}"';
    }
    if (selectedChatFolder != null) return selectedChatFolder!.name;
    if (showingArchivedChats) return 'Archived';
    return 'Chats';
  }

  Future<void> refreshChatOrganization() async {
    if (!isLoggedIn) return;
    try {
      chatFolders = await _chatUseCase.fetchFolders();
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

  Future<void> filterChatsByFolder(ChatFolder folder) async {
    final requestId = ++_chatFilterRequestId;
    chatSearchQuery = '';
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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.loadFilters,
          fallbackMessage: 'Folder chats could not be loaded.',
        ),
        retry: () => filterChatsByFolder(folder),
      );
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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.loadFilters,
          fallbackMessage: 'Archived chats could not be loaded.',
        ),
        retry: showArchivedChats,
      );
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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.loadChats,
        ),
        retry: fetchChats,
      );
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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.loadChats,
          fallbackMessage: 'Pinned chats could not be loaded.',
        ),
        retry: fetchChats,
      );
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
    _conversation.startNewChat();
  }

  Future<void> deleteChat(Chat chat) async {
    try {
      await _chatUseCase.deleteChat(chat);
      _removeChatFromLists(chat.id);
      if (selectedChat?.id == chat.id) {
        onTapNewChat();
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.updateChat,
          fallbackMessage: 'The chat could not be deleted. Please try again.',
        ),
      );
    }
  }

  Future<void> updateChatTitle(Chat chat, String newTitle) async {
    try {
      final updated = await _chatUseCase.updateChatTitle(chat, newTitle);
      _replaceChatInLists(updated);
    } catch (e) {
      if (kDebugMode) debugPrint('Update error: $e');
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.updateChat,
          fallbackMessage: 'The chat could not be renamed. Please try again.',
        ),
      );
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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.updateChat,
          fallbackMessage:
              'The pin status could not be changed. Refresh and try again.',
        ),
      );
    }
  }

  Future<void> archiveChat(Chat chat) async {
    try {
      await _chatUseCase.archiveChat(chat);
      _removeChatFromLists(chat.id);
      if (selectedChat?.id == chat.id) {
        onTapNewChat();
      } else {
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Archive error: $e');
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.updateChat,
          fallbackMessage: 'The chat could not be archived. Please try again.',
        ),
      );
    }
  }

  Future<void> moveChatToFolder(Chat chat, String? folderId) async {
    try {
      final updated = await _chatUseCase.updateChatFolder(chat, folderId);
      _replaceChatInLists(updated);
      await refreshChatOrganization();
    } catch (e) {
      if (kDebugMode) debugPrint('Move chat error: $e');
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.updateChat,
          fallbackMessage: 'The chat could not be moved. Please try again.',
        ),
      );
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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.updateChat,
          fallbackMessage: 'The folder could not be created. Please try again.',
        ),
      );
    }
  }

  void _removeChatFromLists(String chatId) {
    chats.removeWhere((c) => c.id == chatId);
    pinnedChats.removeWhere((c) => c.id == chatId);
    filteredChats.removeWhere((c) => c.id == chatId);
    archivedChats.removeWhere((c) => c.id == chatId);
    chatFolders = [
      for (final folder in chatFolders)
        ChatFolder(
          id: folder.id,
          name: folder.name,
          parentId: folder.parentId,
          isExpanded: folder.isExpanded,
          chats: [
            for (final chat in folder.chats)
              if (chat.id != chatId) chat,
          ],
        ),
    ];
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
      _reportError(
        ChatErrorMapper.from(
          e,
          operation: ChatOperation.shareChat,
        ),
        retry: () async {
          await copyShareLink(chat);
        },
      );
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      isLoggedIn = await _authUseCase.isLoggedIn();
      if (kDebugMode) debugPrint('isLoggedIn: $isLoggedIn');
      if (isLoggedIn) {
        await fetchUser();
      } else {
        user = null;
      }
    } catch (error) {
      isLoggedIn = false;
      user = null;
      if (kDebugMode) debugPrint('checkAuthStatus error: $error');
      _reportError(
        ChatErrorMapper.from(
          error,
          operation: ChatOperation.authenticate,
        ),
        retry: checkAuthStatus,
      );
    } finally {
      notifyListeners();
    }
  }

  /// Clears chat UI state when the session ends (logout, account deletion, QA env switch).
  /// Call after auth token is invalidated so the next login does not see another user's thread.
  Future<void> clearChatStateOnLogout() async {
    await _conversation.reset();
    _attachments.reset();
    chats = [];
    pinnedChats = [];
    filteredChats = [];
    archivedChats = [];
    chatFolders = [];
    tools = [];
    models = [];
    selectedModel = null;
    selectedToolIds = <String>{};
    _chatConfiguration = const ChatConfiguration(
      defaultModelIds: [_fallbackDefaultModelId],
      defaultPrompts: _fallbackDefaultQuestions,
    );
    defaultQuestions = List.of(_fallbackDefaultQuestions);
    allChatsLoaded = true;
    _nextChatListPage = 2;
    isLoadingChats = false;
    isLoadingChatFilters = false;
    isLoadingMoreChats = false;
    _activeError = null;
    _activeErrorRetry = null;
    chatSearchQuery = '';
    selectedChatFolder = null;
    showingArchivedChats = false;

    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
    if (chatListScrollController.hasClients) {
      chatListScrollController.jumpTo(0);
    }

    notifyListeners();
  }

  void scrollToBottom({bool force = false}) {
    final shouldScroll = force ||
        !scrollController.hasClients ||
        scrollController.position.extentAfter < 180;
    if (!shouldScroll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final target = scrollController.position.maxScrollExtent;
        if (force) {
          scrollController.jumpTo(target);
        } else {
          scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> selectChat(Chat chat) async {
    await _conversation.selectChat(chat);
  }

  Future<void> sendInputMessage(
    String text, {
    VoidCallback? onMessageAccepted,
  }) async {
    if (isUploadingFile || isSendingMessage) return;
    final attachments = List<ChatFile>.from(pendingFiles);
    await _conversation.sendMessage(
      text: text,
      attachments: attachments,
      toolIds: selectedToolIds.toList(growable: false),
      model: selectedModel,
      onMessageAccepted: () {
        _attachments.markPendingFilesSent();
        onMessageAccepted?.call();
      },
    );
  }

  Future<void> onDefaultQuestionsTapped(int index) async {
    final question = defaultQuestions[index];
    await sendInputMessage(question);
  }

  void copyMessage(Message message) async {
    await Clipboard.setData(ClipboardData(text: message.content));
    _conversation.setCopyingMessage(message.id);
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (_conversation.copyingMessageId == message.id) {
        _conversation.setCopyingMessage(null);
      }
    });
  }

  bool isMessageCopying(Message message) {
    return _conversation.isMessageCopying(message);
  }

  bool isSubmittingFeedbackFor(Message message) {
    return _conversation.isSubmittingFeedbackFor(message);
  }

  Future<bool> submitMessageFeedback({
    required Message message,
    required int goodBadRating, // 1 for Good, -1 for Bad
    required int detailsRating, // 1..10 from dialog
    required List<String> reasons,
    String? comment,
    required int messageIndex,
  }) async {
    return _conversation.submitMessageFeedback(
      message: message,
      goodBadRating: goodBadRating,
      detailsRating: detailsRating,
      reasons: reasons,
      comment: comment,
      messageIndex: messageIndex,
    );
  }
}
