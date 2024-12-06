import 'dart:async';
import 'package:domain/domain.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:domain/usecases/function_tools_usecase.dart';
import 'package:domain/usecases/user_usercase.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatUseCase _chatUseCase;
  final ChatSessionUseCase _chatSessionUseCase;
  final FunctionToolsUseCase _functionToolsUseCase;
  final AuthUseCase _authUseCase;
  final UserUseCase _userUserCase;

  bool isLoggedIn = false;
  User? user;

  final ScrollController scrollController = ScrollController();
  bool isLoading = false;

  List<ChatSession> sessions = [];
  ChatSession? _selectedSession;

  List<Message> messages = [];
  StreamController<Message> messageStreamController =
      StreamController.broadcast();

  List<String> defaultQuestions = [
    "Calculate lamina engineering constants",
    "Calculate lamina strain",
    "Calculate lamina stress",
    "Calculate laminate plate properties",
    "Calculate laminate 3D properties",
    "Calculate laminar strain",
    "Calculate laminate stress",
    "Calculates the UDFRC properties by rules of mixture",
    // "Give me some math equations.",
  ];

  ChatViewModel({
    required ChatUseCase chatUseCase,
    required ChatSessionUseCase chatSessionUseCase,
    required FunctionToolsUseCase functionToolsUseCase,
    required AuthUseCase authUseCase,
    required UserUseCase userUserCase,
  })  : _chatUseCase = chatUseCase,
        _chatSessionUseCase = chatSessionUseCase,
        _functionToolsUseCase = functionToolsUseCase,
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
    messageStreamController.close();
    super.dispose();
  }

  // Initialize session if no sessions exist
  Future<void> initializeChatSessions() async {
    sessions = await _chatSessionUseCase.getAllSessions();
    if (sessions.isEmpty) {
      addNewSession();
    } else {
      _selectedSession = sessions.first;
      notifyListeners();
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

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  void addNewSession() {
    final newSession = _chatSessionUseCase.createNewSession();
    sessions.add(newSession);
    selectSession(newSession);
  }

  void selectSession(ChatSession session) {
    _selectedSession = session;
    messages = [..._selectedSession!.messages];
    notifyListeners();
    scrollToBottom();
  }

  Future<void> sendInputMessage(text) async {
    final message = Message(role: 'user', content: text);
    await sendMessage(message);
  }

  Future<void> sendMessage(Message newMessage) async {
    if (_selectedSession == null) return;
    messages.add(newMessage);
    setLoading(true);
    scrollToBottom();

    // Store the latest message
    Message? finalMessage;

    // Create a subscription to listen to the stream
    messageStreamController = StreamController.broadcast();
    final subscription = _chatUseCase
        .sendMessage(newMessage, _selectedSession!)
        .listen((Message message) {
      // Add each streamed message to the stream controller and to the message list
      messageStreamController.add(message);
      finalMessage = message; // Update the latest message
      scrollToBottom();
    }, onError: (error) {
      messageStreamController.add(error);
      print('Error receiving messages: $error');
      // Handle the error
    }, onDone: () {
      // Stream is done; this will trigger when the stream closes
      print("stream is done, finalMessage: $finalMessage");
    });

    // Wait for the stream to finish
    await subscription.asFuture();

    print("stream is finished");

    messageStreamController.close();

    if (finalMessage != null) {
      messages.add(finalMessage!);
      saveSession();
      await checkFunctionCall(finalMessage!);
    }

    setLoading(false);
  }

  void saveSession() {
    _selectedSession?.messages = [...messages];
  }

  Future<void> checkFunctionCall(Message message) async {
    final tool = message.toolCalls?.first;
    if (tool != null) {
      final toolMessage = _functionToolsUseCase.handleToolCall(tool);
      await sendMessage(toolMessage);
    }
  }

  bool isUserMessage(Message message) {
    return message.role == 'user';
  }

  Future<void> onDefaultQuestionsTapped(int index) async {
    final question = defaultQuestions[index];
    final message = Message(role: 'user', content: question);
    await sendMessage(message);
  }
}

// Extension on the Message class
extension ChatContentExtension on Message {
  String get chatContent {
    var contentText = content;
    if (role == 'assistant') {
      final function = toolCalls?.first.function;
      if (function != null) {
        final name = function.name;
        final arguments = function.arguments;
        contentText = contentText +
            '\n\n' +
            "Call function: $name" +
            '\n\n' +
            "Use parameters:\n\n $arguments";
      }
    }
    return contentText;
  }
}
