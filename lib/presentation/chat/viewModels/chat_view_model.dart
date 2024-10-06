import 'dart:convert';

import 'package:composite_calculator/calculators/lamina_engineering_constants_calculator.dart';
import 'package:composite_calculator/models/lamina_engineering_constants_input.dart';
import 'package:composite_calculator/models/lamina_engineering_constants_output.dart';
import 'package:domain/domain.dart';
import 'package:domain/entities/chat_session.dart';
import 'package:domain/entities/message.dart';
import 'package:domain/usecases/chat_session_usecase.dart';
import 'package:domain/usecases/chat_usecase.dart';
import 'package:flutter/cupertino.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatUseCase _chatUseCase;
  final ChatSessionUseCase _chatSessionUseCase;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<ChatSession> _sessions = [];
  ChatSession? _selectedSession;

  TextEditingController get controller => _controller;

  ScrollController get scrollController => _scrollController;

  bool get isLoading => _isLoading;

  List<ChatSession> get sessions => _sessions;

  ChatSession? get selectedSession => _selectedSession;

  List<String> defaultQuestions = [
    "What is SwiftComp?",
    "Calculate lamina engineering constants",
    "What is the upper bound of Young's modulus for composites?",
    // "How to use SwiftComp?",
    "Give me some math equations.",
  ];

  ChatViewModel({
    required ChatUseCase chatUseCase,
    required ChatSessionUseCase chatSessionUseCase,
  })
      : _chatUseCase = chatUseCase,
        _chatSessionUseCase = chatSessionUseCase {
    _controller.addListener(_onUserInputChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Initialize session if no sessions exist
  void initializeSession() async {
    _sessions = await _chatSessionUseCase.getAllSessions();
    if (_sessions.isEmpty) {
      final newSession = ChatSession(
        id: UniqueKey().toString(),
        title: 'Session 1',
      );
      _chatSessionUseCase.saveSession(newSession);
      _sessions = [newSession];
    }
    _selectedSession = _sessions.first;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void addNewSession() {
    final newSession = ChatSession(
      id: UniqueKey().toString(),
      title: 'Session ${sessions.length + 1}',
    );
    _chatSessionUseCase.createSession(newSession);
    _sessions.add(newSession);
    selectSession(newSession);
  }

  void selectSession(ChatSession session) {
    _selectedSession = session;
    notifyListeners();
    scrollToBottom();
  }

  Future<void> sendCurrentUserMessage() async {
    sendUserMessage(_controller.text);
  }

  Future<void> sendUserMessage(String content) async {
    if (content.isEmpty || selectedSession == null) return;
    setLoading(true);
    final userMessage = Message(role: 'user', content: content);
    _chatSessionUseCase.addMessageToSession(selectedSession!, userMessage);
    _controller.clear();
    scrollToBottom();
    notifyListeners();
    _sendMessages();
  }

  Future<void> _sendMessages() async {
    try {
      await _chatUseCase.sendMessages(selectedSession!.messages).listen(
              (message) {
            final bool isLastMessageAssist = _chatSessionUseCase
                .isLastMessageAssistInSession(selectedSession!);
            if (isLastMessageAssist) {
              _chatSessionUseCase.updateLastAssistantMessage(
                  selectedSession!, message);
            } else {
              _chatSessionUseCase.addMessageToSession(
                  selectedSession!, message);
            }
            scrollToBottom();
            notifyListeners();
          }, onDone: () {
        checkFunctionCall();
      });
    } catch (error) {
      setLoading(false);
    }
  }

  void checkFunctionCall() {
    final lastMessage = selectedSession?.messages.last;
    final tool = lastMessage?.toolCalls?.first;
    if (tool != null) {
      final functionName = tool.function?.name;
      final functionArguments = tool.function?.arguments ?? "";
      final argumentsJson = jsonDecode(functionArguments);
      if (functionName == "calculate_lamina_engineering_constants") {
        LaminaEngineeringConstantsInput input = LaminaEngineeringConstantsInput
            .fromJson(argumentsJson);
        LaminaEngineeringConstantsOutput output = LaminaEngineeringConstantsCalculator.calculate(input);
        _chatSessionUseCase.addMessageToSession(
            selectedSession!,
            Message(
                role: "tool",
                content: output.toJson().toString(),
                tool_call_id: tool.id
            )
        );
      }
      _sendMessages();
    } else {
      setLoading(false);
    }
  }


  bool isUserMessage(Message message) {
    return message.role == 'user';
  }

  String assistantMessageContent(Message message) {
    final isLastMessage = selectedSession?.messages.last == message;

    final shouldAppendDot = _isLoading && isLastMessage;

    var content = message.content ?? "";

    final function = message.toolCalls?.first.function;
    if (function != null) {
      final name = message.toolCalls?.first.function?.name;
      final arguments = message.toolCalls?.first.function?.arguments;
      content = content +
          '\n\n' +
          "Call function: $name" +
          '\n\n' +
          "Use parameters:\n\n $arguments";
    }

    final assistantContent = shouldAppendDot ? content + " ●" : content;
    return assistantContent;
  }

  void _onUserInputChanged() {
    notifyListeners();
  }

  bool isUserInputEmpty() {
    return controller.text.isEmpty;
  }

  void onDefaultQuestionsTapped(int index) {
    // Handle the card tap event, e.g., navigate to another screen
    final question = defaultQuestions[index];
    sendUserMessage(question);
  }
}
