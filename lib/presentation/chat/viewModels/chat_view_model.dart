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

  ChatViewModel(this._chatUseCase, this._chatSessionUseCase) {
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

  Future<void> sendMessage() async {
    if (!isUserInputEmpty() && selectedSession != null) {
      setLoading(true);
      final userMessage = Message(role: 'user', content: _controller.text);
      _chatSessionUseCase.addMessageToSession(selectedSession!, userMessage);
      _controller.clear();
      scrollToBottom();
      notifyListeners();

      try {
        await _chatUseCase.sendMessages(selectedSession!.messages).listen(
            (token) {
          final bool isLastMessageAssist = _chatSessionUseCase
              .isLastMessageAssistInSession(selectedSession!);
          if (isLastMessageAssist) {
            _chatSessionUseCase.updateLastAssistantMessage(
                selectedSession!, token);
          } else {
            _chatSessionUseCase.addMessageToSession(
              selectedSession!,
              Message(role: "assistant", content: token),
            );
          }
          scrollToBottom();
          notifyListeners();
        }, onDone: () {
          setLoading(false);
        });
      } catch (error) {
        setLoading(false);
      }
    }
  }

  bool isUserMessage(Message message) {
    return message.role == 'user';
  }

  String assistantMessageContent(Message message) {
    final isLastMessage = selectedSession?.messages.last == message;

    final shouldAppendDot = _isLoading && isLastMessage;

    final assistantMessageContent = shouldAppendDot
        ? message.content + " ●"
        : message.content;
    return assistantMessageContent;
  }

  void _onUserInputChanged() {
    notifyListeners();
  }

  bool isUserInputEmpty() {
    return controller.text.isEmpty;
  }
}
