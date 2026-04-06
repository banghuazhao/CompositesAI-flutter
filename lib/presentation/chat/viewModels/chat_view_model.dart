import 'dart:async';
import 'dart:math' as math;
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
  /// Appending next page for GET /chats/?page=n (infinite scroll).
  bool isLoadingMoreChats = false;
  /// After first page: false if last page had [chatListPageSize] items (may have more).
  bool allChatsLoaded = true;
  int _nextChatListPage = 2;

  bool isSubmittingFeedback = false;
  final Set<String> _submittingFeedbackMessageIds = <String>{};

  List<Chat> chats = [];
  List<Chat> pinnedChats = [];
  Chat? selectedChat;
  String? errorMessage;

  List<Message> messages = [];
  StreamController<Message> threadResponseController =
      StreamController.broadcast();

  String? copyingMessageId;

  final ChatLimiter _chatLimiter = ChatLimiter();

  final assistantId = "asst_pxUDI3A9Q8afCqT9cqgUkWQP";

  List<String> defaultQuestions = [
    "What is Composites AI?",
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
        print(e);
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
        print(e);
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
  }

  /// GET /chats/{chatId}/pinned — use when you need server truth for Pin vs Unpin.
  Future<bool> fetchChatPinned(String chatId) {
    return _chatUseCase.fetchChatPinned(chatId);
  }

  /// Next page for GET /chats/?page=n; append to [chats]. Stops when empty or short page (see [chatListPageSize]).
  Future<void> loadMoreChats() async {
    if (!isLoggedIn) return;
    if (allChatsLoaded || isLoadingMoreChats || isLoadingChats) return;

    isLoadingMoreChats = true;
    notifyListeners();
    try {
      final list = await _chatUseCase.fetchChats(page: _nextChatListPage);
      if (kDebugMode) {
        print(
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
        print('loadMoreChats error: $e');
      }
      errorMessage = 'Failed to load more chats.';
    } finally {
      isLoadingMoreChats = false;
      notifyListeners();
    }
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
        print('fetchChats page=1: API returned ${list.length} chats');
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
        print('fetchChats error: $e');
      }
      chats = [];
      allChatsLoaded = true;
    }
    try {
      pinnedChats = await _chatUseCase.fetchPinnedChats();
      if (kDebugMode) {
        print('fetchPinnedChats: API returned ${pinnedChats.length} pinned');
      }
    } catch (e) {
      if (kDebugMode) {
        print('fetchPinnedChats error: $e');
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
    selectedChat = chats.firstWhere((chat) => chat.id == newChat.id);
  }

  void onTapNewChat() {
    selectedChat = null;
    messages = [];
    notifyListeners();
  }

  Future<void> deleteChat(Chat chat) async {
    try {
      await _chatUseCase.deleteChat(chat);
      chats.removeWhere((c) => c.id == chat.id);
      pinnedChats.removeWhere((c) => c.id == chat.id);
      notifyListeners();
    } catch (e) {
      print('Delete error: $e');
      errorMessage = 'Failed to delete chat. Please try again.';
      notifyListeners();
    }
  }

  Future<void> updateChatTitle(Chat chat, String newTitle) async {
    try {
      final updated = await _chatUseCase.updateChatTitle(chat, newTitle);
      final index = chats.indexWhere((c) => c.id == chat.id);
      if (index >= 0) {
        chats[index].title = updated.title;
      }
      final pinIndex = pinnedChats.indexWhere((c) => c.id == chat.id);
      if (pinIndex >= 0) {
        pinnedChats[pinIndex].title = updated.title;
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Update error: $e');
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
      if (kDebugMode) print('Pin/Unpin error: $e');
      errorMessage = 'Failed to operate. Please try again.';
      notifyListeners();
    }
  }

  /// Calls share API, copies link to clipboard. Returns true if success. No need to store the link.
  Future<bool> copyShareLink(Chat chat) async {
    try {
      final link = await _chatUseCase.shareChat(chat);
      await Clipboard.setData(ClipboardData(text: link));
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Share error: $e');
      errorMessage = 'Failed to create share link. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    isLoggedIn = await _authUseCase.isLoggedIn();
    print("isLoggedIn: $isLoggedIn");
    if (isLoggedIn) {
      await fetchUser();
    } else {
      user = null; // Ensure user is null if not logged in
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

  void selectChat(Chat chat) async {
    selectedChat = chat;
    isLoadingMessages = true;
    notifyListeners();
    messages = await _chatUseCase.fetchMessages(chat);
    // Restore feedbackId from local cache so update calls are reliable
    // even after page rebuild / app restart.
    for (final m in messages) {
      final cached = FeedbackIdCache.getFeedbackId(chat.id, m.id);
      if (cached != null) {
        m.feedbackId = cached;
      }
    }
    isLoadingMessages = false;
    notifyListeners();
    scrollToBottom();
  }

  Future<bool> reachChatLimit() async {
    return _chatLimiter.reachChatLimit();
  }

  Future<void> sendInputMessage(String text) async {
    final userMessage = Message(role: 'user', content: text);

    if (selectedChat != null) {
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
        updateNewChat(newChat);
      }

      final messagesForRequest = List<Message>.from(messages);
      final sendId = Uuid().v4();

      streamBuilder() => _chatUseCase
          .sendMessages(messagesForRequest, selectedChat!, sendId)
          .map((content) => Message(
              role: 'assistant', content: content, parentId: userMessage.id));

      await _processResponseStream(streamBuilder, sendId);
    } catch (e) {
      if (kDebugMode) print('sendInputMessage error: $e');
      setSendingMessage(false);
      errorMessage = 'Failed to send message. Please try again.';
      notifyListeners();
    }
  }

  Future<void> _processResponseStream(
      Stream<Message> Function() streamBuilder, String sendId) async {
    threadResponseController = StreamController<Message>.broadcast();
    Message assistantMessage = Message(role: 'assistant', content: '');
    assistantMessage.parentId = messages.last.id;
    messages.last.childrenIds = [assistantMessage.id];
    messages.add(assistantMessage);

    selectedChat?.updatedAt = DateTime.now().microsecondsSinceEpoch ~/ 1000;
    await _chatUseCase.persistMessages(messages, selectedChat!);

    try {
      final stream = streamBuilder();

      await for (final response in stream) {
        threadResponseController.add(response);

        assistantMessage.content += response.content;
        notifyListeners();
        scrollToBottom();
      }
      await _chatLimiter.incrementChatCount();
      assistantMessage.thinkingElapsed = math.max(
          0,
          (DateTime.now().millisecondsSinceEpoch - assistantMessage.timestamp) ~/
              1000);
      assistantMessage.isDone = true;
      selectedChat?.updatedAt = DateTime.now().microsecondsSinceEpoch ~/ 1000;
      await _chatUseCase.updateChatMessage(assistantMessage, selectedChat!);
      await _chatUseCase.persistMessages(messages, selectedChat!);
    } catch (error) {
      threadResponseController.addError(error);
      if (kDebugMode) print('Error receiving messages: $error');
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
      await FeedbackIdCache.setFeedbackId(
        selectedChat!.id,
        message.id,
        feedbackId,
      );
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('submitMessageFeedback error: $e');
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
