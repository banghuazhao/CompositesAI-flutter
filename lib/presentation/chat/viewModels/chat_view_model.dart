import 'dart:async';
import 'package:domain/chat/chat.dart';
import 'package:domain/domain.dart';
import 'package:domain/entities/chat/function_tool.dart';
import 'package:domain/entities/chat/thread.dart';
import 'package:domain/entities/chat/chat_response.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/use_cases/auth_use_case.dart';
import 'package:domain/use_cases/composites_tools_use_case.dart';
import 'package:domain/use_cases/functional_call_use_case.dart';
import 'package:domain/use_cases/thread_runs_use_case.dart';
import 'package:domain/use_cases/threads_use_case.dart';
import 'package:domain/use_cases/user_use_case.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../util/chat_limiter.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatUseCase _chatUseCase;
  final AuthUseCase _authUseCase;
  final UserUseCase _userUserCase;
  final ThreadRunsUseCase _threadRunsUseCase;
  final FunctionalCallUseCase _functionalCallUseCase;

  bool isLoggedIn = false;
  User? user;

  final ScrollController scrollController = ScrollController();
  bool isSendingMessage = false;
  bool isLoadingMessages = false;

  List<Chat> chats = [];
  Chat? selectedChat;

  List<Message> messages = [];
  StreamController<ChatResponse> threadResponseController =
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
    required ThreadsUseCase threadsUseCase,
    required ThreadRunsUseCase threadRunsUseCase,
    required CompositesToolsUseCase toolsUseCase,
    required FunctionalCallUseCase functionalCallUseCase,
  })  : _chatUseCase = chatUseCase,
        _authUseCase = authUseCase,
        _userUserCase = userUserCase,
        _threadRunsUseCase = threadRunsUseCase,
        _functionalCallUseCase = functionalCallUseCase;

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
    try {
      chats = await _chatUseCase.fetchChats();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      // Avoid crashing UI on 401/403 before login is established.
      chats = [];
    }
    notifyListeners();
  }

  void onTapNewChat() {
    selectedChat = null;
    notifyListeners();
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
    final message = Message(role: 'user', content: text);
    if (selectedChat == null) return;

    final Stream<ChatResponse> Function() streamBuilder = messages.isEmpty
        ? () => _threadRunsUseCase.createThreadAndRunStream(
            assistantId, message.content)
        : () {
            final threadId = selectedChat!.id!;
            return _threadRunsUseCase.createMessageAndRunStream(
                threadId, assistantId, message.content);
          };

    messages.add(message);
    setSendingMessage(true);
    scrollToBottom();

    await _processResponseStream(streamBuilder);
  }

  Future<void> _processResponseStream(
    Stream<ChatResponse> Function() streamBuilder,
  ) async {
    threadResponseController = StreamController<ChatResponse>.broadcast();
    Message? finalMessage;

    try {
      final stream = streamBuilder();

      await for (final response in stream) {
        threadResponseController.add(response);

        if (response is Message) {
          finalMessage = response;
          selectedChat?.title = response.content;
          scrollToBottom();
        } else if (response is Thread) {
          // selectedChat?.id = response.id;
        } else if (response is FunctionTool) {
          final threadToolOutput =
              await _functionalCallUseCase.callFunctionTool(response);
          streamBuilder() => _threadRunsUseCase.submitToolOutputsToRunStream(
              selectedChat!.id!, response.runId, [threadToolOutput]);
          setSendingMessage(true);
          scrollToBottom();
          await _processResponseStream(streamBuilder);
        }
      }
    } catch (error) {
      threadResponseController.addError(error);
      print('Error receiving messages: $error');
    } finally {
      await threadResponseController.close();
      if (finalMessage != null) {
        // print(finalMessage.content);
        await _chatLimiter.incrementChatCount();
        messages.add(finalMessage);
      }
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
