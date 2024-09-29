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
    "How to use SwiftComp?",
  ];

  ChatViewModel({
    required ChatUseCase chatUseCase,
    required ChatSessionUseCase chatSessionUseCase,
  })  : _chatUseCase = chatUseCase,
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
              _chatSessionUseCase.addMessageToSession(selectedSession!, message);
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
      if (functionName == "calculate_lamina_engineering_constants") {
        // TODO: Use internal or external tools to calculation the result...
        _chatSessionUseCase.addMessageToSession(
            selectedSession!,
            Message(
                role: "tool",
                content:
                    "{     \"E_1\": 4431.314623338257,     \"E_2\": 4431.314623338257,     \"G_12\": 36144.57831325301,     \"nu_12\": 0.7725258493353028,     \"eta_1_12\": 0.10339734121122615,     \"eta_2_12\": 0.10339734121122582,     \"Q\": [         [             43000.50301810866,             40500.50301810865,             -70422.5352112676         ],         [             40500.50301810865,             43000.50301810863,             -70422.53521126758         ],         [             -70422.53521126762,             -70422.53521126759,             154929.57746478872         ]     ],     \"S\": [         [             0.00022566666666666666,             -0.00017433333333333333,             2.3333333333333373e-05         ],         [             -0.00017433333333333333,             0.00022566666666666669,             2.3333333333333295e-05         ],         [             2.333333333333337e-05,             2.3333333333333295e-05,             2.7666666666666667e-05         ]     ] }",
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
