import 'dart:async';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/domain.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../util/chat_limiter.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatUseCase _chatUseCase;
  final AuthUseCase _authUseCase;
  final UserUseCase _userUserCase;

  bool isLoggedIn = false;
  User? user;

  final ScrollController scrollController = ScrollController();
  bool isSendingMessage = false;
  bool isLoadingMessages = false;
  bool isLoadingChats = false;

  List<Chat> chats = [];
  Chat? selectedChat;
  String? errorMessage;

  List<Message> messages = [];
  StreamController<Message> threadResponseController =
      StreamController.broadcast();

  String? copyingMessageId;
  List<Message> selectedMessages = [];

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
        _userUserCase = userUserCase;

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
    scrollController.dispose();
    threadResponseController.close();
    super.dispose();
  }

  // Initialize session if no chat list exists
  Future<void> fetchChats() async {
    isLoadingChats = true;
    notifyListeners();
    try {
      final list = await _chatUseCase.fetchChats();
      if (kDebugMode) {
        print('fetchChats: API returned ${list.length} chats');
      }
      chats = list;
    } catch (e) {
      if (kDebugMode) {
        print('fetchChats error: $e');
      }
      // Avoid crashing UI on 401/403 before login is established.
      chats = [];
    } finally {
      isLoadingChats = false;
      notifyListeners();
    }
  }

  void onTapNewChat() {
    selectedChat = null;
    notifyListeners();
  }

  Future<void> deleteChat(Chat chat) async {
    try {
      await _chatUseCase.deleteChat(chat);
      chats.removeWhere((c) => c.id == chat.id);
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
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Update error: $e');
      errorMessage = 'Failed to rename chat. Please try again.';
      notifyListeners();
    }
  }

  Future<void> togglePin(Chat chat) async {
    try {
      final updated = await _chatUseCase.togglePin(chat);
      final index = chats.indexWhere((c) => c.id == chat.id);
      if (index >= 0) {
        chats[index].pinned = updated.pinned;
        final item = chats.removeAt(index);
        if (updated.pinned) {
          chats.insert(0, item);
        } else {
          chats.add(item);
        }
      }
      notifyListeners();
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
    isLoadingMessages = false;
    notifyListeners();
    scrollToBottom();
  }

  Future<bool> reachChatLimit() async {
    return _chatLimiter.reachChatLimit();
  }

  Future<void> sendInputMessage(String text) async {
    if (selectedChat == null) return;
    final userMessage = Message(role: 'user', content: text);
    messages.add(userMessage);
    setSendingMessage(true);
    scrollToBottom();

    final Stream<Message> Function() streamBuilder = () => _chatUseCase
        .sendMessages(messages, selectedChat!)
        .map((content) => Message(role: 'assistant', content: content));

    await _processResponseStream(streamBuilder);
  }

  Future<void> _processResponseStream(
    Stream<Message> Function() streamBuilder,
  ) async {
    threadResponseController = StreamController<Message>.broadcast();
    Message assistantMessage = Message(role: 'assistant', content: '');
    messages.add(assistantMessage);

    try {
      final stream = streamBuilder();

      await for (final response in stream) {
        threadResponseController.add(response);

        if (response is Message) {
          assistantMessage.content += response.content;
          notifyListeners();
          scrollToBottom();
        }
      }
      await _chatLimiter.incrementChatCount();
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

  void toggleMessageSelection(Message message) {
    if (selectedMessages.contains(message)) {
      selectedMessages.remove(message);
    } else {
      selectedMessages.add(message);
    }
    notifyListeners();
  }

  bool isMessageCopying(Message message) {
    return copyingMessageId == message.id;
  }

  bool isMessageSelected(Message message) {
    return selectedMessages.contains(message);
  }

  void toggleMessageLikeStatus(Message message, bool isLiked) {
    message.isLiked = isLiked;
    notifyListeners();
  }
}
