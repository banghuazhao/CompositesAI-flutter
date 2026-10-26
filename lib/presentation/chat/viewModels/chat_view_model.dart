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
import '../controllers/chat_composer_controller.dart';
import '../controllers/chat_conversation_controller.dart';
import '../model/chat_error.dart';
import '../../../util/chat_limiter.dart';

/// An opaque snapshot of the source question and the draft it may replace.
class ChatDraftReuseRequest {
  const ChatDraftReuseRequest._({
    required Object session,
    required int selection,
    required String chatId,
    required Message source,
    required String text,
    required ChatComposerTicket composer,
  })  : _session = session,
        _selection = selection,
        _chatId = chatId,
        _source = source,
        _text = text,
        _composer = composer;

  final Object _session;
  final int _selection;
  final String _chatId;
  final Message _source;
  final String _text;
  final ChatComposerTicket _composer;

  bool get replacesDraft => _composer.value.text.isNotEmpty;
}

/// One temporary, revision-scoped snapshot for undoing an explicit draft clear.
class ChatDraftClearUndo {
  const ChatDraftClearUndo._(
    this._session,
    this._selection,
    this._chatId,
    this._original,
    this._cleared,
  );

  final Object _session;
  final int _selection;
  final String? _chatId;
  final TextEditingValue _original;
  final ChatComposerTicket _cleared;
}

/// A starting question and the exact unsent draft it is allowed to replace.
class ChatSuggestedDraftRequest {
  const ChatSuggestedDraftRequest._(
    this._session,
    this._selection,
    this._index,
    this._text,
    this._composer,
  );

  final Object _session;
  final int _selection;
  final int _index;
  final String _text;
  final ChatComposerTicket _composer;

  bool get replacesDraft => _composer.value.text.isNotEmpty;
}

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
  final _composer = ChatComposerController();
  Object? _composerSessionKey;
  final _disposalNotifier = ValueNotifier(false);
  int _composerReplacementRevision = 0;
  ChatDraftClearUndo? _draftClearUndo;

  bool get isDisposed => _isDisposed;
  ValueListenable<bool> get disposalListenable => _disposalNotifier;
  int get composerReplacementRevision => _composerReplacementRevision;

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
  int _authRequestId = 0;
  int _sessionGeneration = 0;
  String? _sessionOwner;

  final assistantId = "asst_pxUDI3A9Q8afCqT9cqgUkWQP";

  List<String> defaultQuestions = List.of(_fallbackDefaultQuestions);

  ChatViewModel({
    required ChatUseCase chatUseCase,
    required AuthUseCase authUseCase,
    required UserUseCase userUserCase,
    ChatLimiter? chatLimiter,
  })  : _chatUseCase = chatUseCase,
        _authUseCase = authUseCase,
        _userUserCase = userUserCase {
    _conversation = ChatConversationController(
      chatUseCase: chatUseCase,
      onChatCreated: updateNewChat,
      onError: _reportError,
      onScrollRequested: ({required force}) => scrollToBottom(force: force),
      chatLimiter: chatLimiter,
    )..addListener(_forwardConversationChange);
    _attachments = ChatAttachmentController(
      chatUseCase: chatUseCase,
      canUseChat: () => isLoggedIn,
      onError: _reportError,
    )..addListener(_forwardAttachmentChange);
    chatListScrollController.addListener(_onChatListScroll);
    _composerSessionKey = chatSessionKey;
    _composer.textController.addListener(_onComposerDraftEdited);
  }

  bool get isSendingMessage => _conversation.isSendingMessage;
  bool get isLoadingMessages => _conversation.isLoadingMessages;
  bool get isSubmittingFeedback => _conversation.isSubmittingFeedback;
  Chat? get selectedChat => _conversation.selectedChat;
  set selectedChat(Chat? value) {
    if (_isDisposed) return;
    _syncComposerSession();
    if (selectedChat?.id != value?.id) _draftClearUndo = null;
    _conversation.selectedChat = value;
    _composer.selectChat(value?.id);
  }

  /// Value equality is stable within the same account/session, including for
  /// test fakes that assign public authentication fields directly.
  Object get chatSessionKey =>
      (_sessionGeneration, isLoggedIn, _userIdentity(user));

  /// Invalidates UI scoped to a selection even after a switch away and back.
  int get chatSelectionRevision => _conversation.selectionRevision;

  TextEditingController get composerTextController {
    if (!_isDisposed) _syncComposerState();
    return _composer.textController;
  }

  Listenable get draftChanges => _composer.draftChanges;

  bool hasDraft(String? chatId) =>
      !_isDisposed &&
      isLoggedIn &&
      _composerSessionKey == chatSessionKey &&
      _composer.hasDraft(chatId);

  void _syncComposerSession() {
    final key = chatSessionKey;
    if (_composerSessionKey == key) return;
    _composerSessionKey = key;
    _draftClearUndo = null;
    _composer.clear();
  }

  void _syncComposerState() {
    _syncComposerSession();
    _composer.selectChat(selectedChat?.id);
  }

  bool get canClearComposerDraft =>
      !_isDisposed &&
      isLoggedIn &&
      !isSendingMessage &&
      !isLoadingMessages &&
      _composerSessionKey == chatSessionKey &&
      _composer.textController.text.isNotEmpty;

  void _onComposerDraftEdited() {
    final undo = _draftClearUndo;
    if (undo != null && !isDraftClearUndoCurrent(undo)) _draftClearUndo = null;
  }

  ChatDraftClearUndo? clearComposerDraft() {
    if (!canClearComposerDraft) return null;
    _syncComposerState();
    final session = chatSessionKey;
    final selection = chatSelectionRevision;
    final chatId = selectedChat?.id;
    final original = _composer.takeTicket();
    _draftClearUndo = null;
    _composerReplacementRevision++;
    if (!_composer.replaceIfCurrent(original, '')) return null;
    if (_isDisposed ||
        chatSessionKey != session ||
        chatSelectionRevision != selection ||
        selectedChat?.id != chatId) {
      return null;
    }
    final undo = ChatDraftClearUndo._(
      session,
      selection,
      chatId,
      original.value,
      _composer.takeTicket(),
    );
    _draftClearUndo = undo;
    notifyListeners();
    return isDraftClearUndoCurrent(undo) ? undo : null;
  }

  bool isDraftClearUndoCurrent(ChatDraftClearUndo undo) =>
      !_isDisposed &&
      identical(_draftClearUndo, undo) &&
      isLoggedIn &&
      !isSendingMessage &&
      !isLoadingMessages &&
      chatSessionKey == undo._session &&
      chatSelectionRevision == undo._selection &&
      selectedChat?.id == undo._chatId &&
      _composerSessionKey == chatSessionKey &&
      _composer.isCurrent(undo._cleared);

  bool undoClearComposerDraft(ChatDraftClearUndo undo) {
    if (!isDraftClearUndoCurrent(undo)) return false;
    _draftClearUndo = null;
    _composerReplacementRevision++;
    if (!_composer.replaceValueIfCurrent(undo._cleared, undo._original)) {
      return false;
    }
    notifyListeners();
    return true;
  }

  void discardDraftClearUndo(ChatDraftClearUndo undo) {
    if (identical(_draftClearUndo, undo)) _draftClearUndo = null;
  }

  bool canUseMessageAsDraft(Message message) =>
      !_isDisposed &&
      isLoggedIn &&
      !isSendingMessage &&
      !isLoadingMessages &&
      selectedChat != null &&
      message.role == 'user' &&
      message.content.trim().isNotEmpty &&
      messages.any((current) => identical(current, message));

  ChatDraftReuseRequest? prepareMessageAsDraft(Message message) {
    if (!canUseMessageAsDraft(message)) return null;
    _syncComposerState();
    return ChatDraftReuseRequest._(
      session: chatSessionKey,
      selection: _conversation.selectionRevision,
      chatId: selectedChat!.id,
      source: message,
      text: message.content,
      composer: _composer.takeTicket(),
    );
  }

  bool isDraftReuseCurrent(ChatDraftReuseRequest request) =>
      canUseMessageAsDraft(request._source) &&
      chatSessionKey == request._session &&
      selectedChat?.id == request._chatId &&
      _conversation.selectionRevision == request._selection &&
      request._source.content == request._text &&
      _composer.isCurrent(request._composer);

  bool applyMessageAsDraft(ChatDraftReuseRequest request) {
    if (!isDraftReuseCurrent(request)) return false;
    // Retire pending voice results before publishing the replacement text.
    _composerReplacementRevision++;
    if (!_composer.replaceIfCurrent(request._composer, request._text)) {
      return false;
    }
    notifyListeners();
    return true;
  }

  /// Custom workspace prompts keep their own wording instead of receiving an
  /// unrelated engineering category when the server changes their order.
  int? suggestedQuestionTaskIndex(int index) {
    if (index < 0 || index >= defaultQuestions.length) return null;
    final task = _fallbackDefaultQuestions.indexOf(defaultQuestions[index]);
    return task < 0 ? null : task;
  }

  bool _canPrepareSuggestion(int index) =>
      !_isDisposed &&
      isLoggedIn &&
      !isSendingMessage &&
      !isLoadingMessages &&
      selectedChat == null &&
      index >= 0 &&
      index < defaultQuestions.length &&
      defaultQuestions[index].trim().isNotEmpty;

  ChatSuggestedDraftRequest? prepareSuggestedDraft(int index) {
    if (!_canPrepareSuggestion(index)) return null;
    _syncComposerState();
    return ChatSuggestedDraftRequest._(
      chatSessionKey,
      _conversation.selectionRevision,
      index,
      defaultQuestions[index],
      _composer.takeTicket(),
    );
  }

  bool isSuggestedDraftCurrent(ChatSuggestedDraftRequest request) =>
      _canPrepareSuggestion(request._index) &&
      chatSessionKey == request._session &&
      _conversation.selectionRevision == request._selection &&
      defaultQuestions[request._index] == request._text &&
      _composer.isCurrent(request._composer);

  bool applySuggestedDraft(ChatSuggestedDraftRequest request) {
    if (!isSuggestedDraftCurrent(request)) return false;
    // Invalidate pending recognition before publishing a deliberate replacement.
    _composerReplacementRevision++;
    _draftClearUndo = null;
    if (!_composer.replaceIfCurrent(request._composer, request._text)) {
      return false;
    }
    notifyListeners();
    return true;
  }

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
    if (!_isDisposed) {
      _syncComposerState();
      _onComposerDraftEdited();
      super.notifyListeners();
    }
  }

  void _reportError(
    ChatFailure failure, {
    AsyncCallback? retry,
  }) {
    if (_isDisposed) return;
    if (failure.type == ChatErrorType.unauthorized) {
      // A confirmed expired session must not leave private data available to
      // the next account. Reset synchronously before publishing the notice.
      unawaited(clearChatStateOnLogout());
      retry = null;
    }
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
    await _refreshAuthSession();
  }

  bool _isCurrentSession(int generation) =>
      !_isDisposed && generation == _sessionGeneration;

  bool _isCurrentAuthRequest(int requestId) =>
      !_isDisposed && requestId == _authRequestId;

  Future<bool> _refreshAuthSession() async {
    final requestId = ++_authRequestId;
    try {
      final hasSession = await _authUseCase.isLoggedIn();
      if (!_isCurrentAuthRequest(requestId)) return false;
      if (!hasSession) {
        await clearChatStateOnLogout();
        return false;
      }
      return await _fetchAuthenticatedUser(requestId);
    } catch (error) {
      if (!_isCurrentAuthRequest(requestId)) return false;
      _reportError(
        ChatErrorMapper.from(error, operation: ChatOperation.authenticate),
        retry: _retryAuthentication,
      );
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchUser() async {
    await _fetchAuthenticatedUser(++_authRequestId);
  }

  Future<bool> _fetchAuthenticatedUser(int requestId) async {
    try {
      final authenticatedUser = await _userUserCase.fetchMe();
      if (!_isCurrentAuthRequest(requestId)) return false;
      final owner = _userIdentity(authenticatedUser);
      final previousOwner = _sessionOwner ?? _userIdentity(user);
      if (previousOwner != null && previousOwner != owner) {
        await _clearPrivateChatState();
        if (!_isCurrentAuthRequest(requestId)) return false;
      }
      user = authenticatedUser;
      _sessionOwner = owner;
      isLoggedIn = true;
      if (_activeError?.failure.operation == ChatOperation.authenticate ||
          _activeError?.failure.type == ChatErrorType.unauthorized) {
        _activeError = null;
        _activeErrorRetry = null;
      }
      return true;
    } catch (error) {
      if (!_isCurrentAuthRequest(requestId)) return false;
      // Network or server failures do not prove that a valid session ended.
      _reportError(
        ChatErrorMapper.from(error, operation: ChatOperation.authenticate),
        retry: _retryAuthentication,
      );
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _retryAuthentication() async {
    final requestId = _authRequestId + 1;
    final verified = await _refreshAuthSession();
    // Preserving an existing user after a timeout is not fresh verification.
    // A newer login/logout also supersedes this retry before hydration starts.
    if (!verified || !isLoggedIn || !_isCurrentAuthRequest(requestId)) return;
    await Future.wait([fetchChats(), fetchTools()]);
  }

  static String? _userIdentity(User? value) {
    if (value == null) return null;
    final id = value.id?.trim();
    if (id != null && id.isNotEmpty) return 'id:$id';
    final email = value.email.trim().toLowerCase();
    if (email.isNotEmpty) return 'email:$email';
    final username = value.username?.trim();
    return username == null || username.isEmpty ? null : 'name:$username';
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _draftClearUndo = null;
    _disposalNotifier.value = true;
    _disposalNotifier.dispose();
    _composer.textController.removeListener(_onComposerDraftEdited);
    _composer.dispose();
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
    final generation = _sessionGeneration;
    await _loadChatLists(showLoading: true);
    if (!_isCurrentSession(generation)) return;
    await refreshChatOrganization();
  }

  Future<void> fetchTools() async {
    if (!isLoggedIn) return;
    final generation = _sessionGeneration;

    isLoadingTools = true;
    notifyListeners();
    try {
      try {
        final configuration = await _chatUseCase.fetchChatConfiguration();
        if (!_isCurrentSession(generation)) return;
        _chatConfiguration = configuration;
      } catch (e) {
        if (!_isCurrentSession(generation)) return;
        final failure =
            ChatErrorMapper.from(e, operation: ChatOperation.loadTools);
        if (failure.type == ChatErrorType.unauthorized) {
          _reportError(failure);
          return;
        }
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
      final loadedTools = await toolsFuture;
      final loadedModels = await modelsFuture;
      if (!_isCurrentSession(generation)) return;
      tools = loadedTools;
      models = loadedModels;
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
      if (!_isCurrentSession(generation)) return;
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
      if (_isCurrentSession(generation)) {
        isLoadingTools = false;
        notifyListeners();
      }
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
    final generation = _sessionGeneration;

    isLoadingMoreChats = true;
    notifyListeners();
    try {
      final list = await _chatUseCase.fetchChats(page: _nextChatListPage);
      if (!_isCurrentSession(generation)) return;
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
      if (!_isCurrentSession(generation)) return;
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
      if (_isCurrentSession(generation)) {
        isLoadingMoreChats = false;
        notifyListeners();
      }
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
    final generation = _sessionGeneration;
    try {
      final folders = await _chatUseCase.fetchFolders();
      if (!_isCurrentSession(generation)) return;
      chatFolders = folders;
    } catch (e) {
      if (!_isCurrentSession(generation)) return;
      if (kDebugMode) {
        debugPrint('refreshChatOrganization error: $e');
      }
      final failure =
          ChatErrorMapper.from(e, operation: ChatOperation.loadFilters);
      if (failure.type == ChatErrorType.unauthorized) _reportError(failure);
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
    final generation = _sessionGeneration;
    isLoadingMoreChats = false;
    if (showLoading) {
      isLoadingChats = true;
      notifyListeners();
    }
    allChatsLoaded = true;
    try {
      final list = await _chatUseCase.fetchChats(page: 1);
      if (!_isCurrentSession(generation)) return;
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
      if (!_isCurrentSession(generation)) return;
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
    if (!_isCurrentSession(generation)) return;
    try {
      final pinned = await _chatUseCase.fetchPinnedChats();
      if (!_isCurrentSession(generation)) return;
      pinnedChats = pinned;
      if (kDebugMode) {
        debugPrint(
            'fetchPinnedChats: API returned ${pinnedChats.length} pinned');
      }
    } catch (e) {
      if (!_isCurrentSession(generation)) return;
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
      if (_isCurrentSession(generation)) {
        if (showLoading) isLoadingChats = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateNewChat(Chat newChat) async {
    final generation = _sessionGeneration;
    final selection = _conversation.selectionRevision;
    if (selectedChat?.id != newChat.id) return;
    _syncComposerSession();
    _composer.adoptNewChat(newChat.id);
    await fetchChats();
    if (!_isCurrentSession(generation) ||
        _conversation.selectionRevision != selection ||
        selectedChat?.id != newChat.id) {
      return;
    }
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
    final generation = _sessionGeneration;
    try {
      await _chatUseCase.deleteChat(chat);
      if (!_isCurrentSession(generation)) return;
      _composer.removeChat(chat.id);
      _removeChatFromLists(chat.id);
      if (selectedChat?.id == chat.id) {
        onTapNewChat();
      } else {
        notifyListeners();
      }
    } catch (e) {
      if (!_isCurrentSession(generation)) return;
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
    final generation = _sessionGeneration;
    try {
      final updated = await _chatUseCase.updateChatTitle(chat, newTitle);
      if (!_isCurrentSession(generation)) return;
      _replaceChatInLists(updated);
    } catch (e) {
      if (!_isCurrentSession(generation)) return;
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
    final generation = _sessionGeneration;
    try {
      await _chatUseCase.togglePin(chat);
      if (!_isCurrentSession(generation)) return;
      await _loadChatLists(showLoading: false);
    } catch (e) {
      if (!_isCurrentSession(generation)) return;
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
    final generation = _sessionGeneration;
    try {
      await _chatUseCase.archiveChat(chat);
      if (!_isCurrentSession(generation)) return;
      _removeChatFromLists(chat.id);
      if (selectedChat?.id == chat.id) {
        onTapNewChat();
      } else {
        notifyListeners();
      }
    } catch (e) {
      if (!_isCurrentSession(generation)) return;
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
    final generation = _sessionGeneration;
    try {
      final updated = await _chatUseCase.updateChatFolder(chat, folderId);
      if (!_isCurrentSession(generation)) return;
      _replaceChatInLists(updated);
      await refreshChatOrganization();
    } catch (e) {
      if (!_isCurrentSession(generation)) return;
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
    final generation = _sessionGeneration;
    try {
      final folder = await _chatUseCase.createFolder(trimmed);
      if (!_isCurrentSession(generation)) return;
      await moveChatToFolder(chat, folder.id);
    } catch (e) {
      if (!_isCurrentSession(generation)) return;
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
    final generation = _sessionGeneration;
    try {
      final link = await _chatUseCase.shareChat(chat);
      if (!_isCurrentSession(generation)) return false;
      await Clipboard.setData(ClipboardData(text: link));
      notifyListeners();
      return true;
    } catch (e) {
      if (!_isCurrentSession(generation)) return false;
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
    await _refreshAuthSession();
  }

  /// Clears chat UI state when the session ends (logout, account deletion, QA env switch).
  /// Call after auth token is invalidated so the next login does not see another user's thread.
  Future<void> clearChatStateOnLogout() async {
    _authRequestId++;
    isLoggedIn = false;
    user = null;
    _sessionOwner = null;
    await _clearPrivateChatState();
  }

  Future<void> _clearPrivateChatState() async {
    _sessionGeneration++;
    _draftClearUndo = null;
    _composerSessionKey = chatSessionKey;
    _composer.clear();
    _chatFilterRequestId++;
    final conversationReset = _conversation.reset();
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
    isLoadingTools = false;
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
    await conversationReset;
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
    _draftClearUndo = null;
    if (isUploadingFile || isSendingMessage) return;
    final generation = _sessionGeneration;
    final session = chatSessionKey;
    final attachments = List<ChatFile>.from(pendingFiles);
    await _conversation.sendMessage(
      text: text,
      attachments: attachments,
      toolIds: selectedToolIds.toList(growable: false),
      model: selectedModel,
      isCurrentRequest: () =>
          _isCurrentSession(generation) && chatSessionKey == session,
      onMessageAccepted: () {
        if (!_isCurrentSession(generation) || chatSessionKey != session) return;
        _attachments.markPendingFilesSent();
        onMessageAccepted?.call();
      },
    );
  }

  /// Keeps the acceptance callback compatible with subclasses that override
  /// sendInputMessage, while protecting the originating draft and session.
  Future<void> sendComposerMessage() async {
    if (_isDisposed) return;
    _draftClearUndo = null;
    _syncComposerState();
    final session = chatSessionKey;
    final ticket = _composer.takeTicket();
    await sendInputMessage(
      ticket.value.text.trim(),
      onMessageAccepted: () {
        if (!_isDisposed && chatSessionKey == session) _composer.accept(ticket);
      },
    );
  }

  bool get canRegenerate => _conversation.canRegenerate;

  void stopGenerating() => _conversation.stopGenerating();

  Future<void> regenerateLastResponse() async {
    _draftClearUndo = null;
    if (isUploadingFile) return;
    await _conversation.regenerateLastResponse(
      toolIds: selectedToolIds.toList(growable: false),
      model: selectedModel,
    );
  }

  Future<void> onDefaultQuestionsTapped(int index) async {
    _draftClearUndo = null;
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
