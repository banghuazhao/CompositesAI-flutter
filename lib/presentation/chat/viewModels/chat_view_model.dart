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
      // TODO: pinned is not a property of a chat
      // final index = chats.indexWhere((c) => c.id == chat.id);
      // if (index >= 0) {
      //   chats[index].pinned = updated.pinned;
      //   final item = chats.removeAt(index);
      //   if (updated.pinned) {
      //     chats.insert(0, item);
      //   } else {
      //     chats.add(item);
      //   }
      // }
      // notifyListeners();
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
}
