import 'dart:async';
import 'dart:math' as math;

import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../util/chat_limiter.dart';
import '../../../util/feedback_id_cache.dart';
import '../model/chat_error.dart';

typedef ChatCreatedCallback = Future<void> Function(Chat chat);
typedef ChatErrorCallback = void Function(
  ChatFailure failure, {
  AsyncCallback? retry,
});
typedef ChatScrollCallback = void Function({required bool force});

/// Owns the lifecycle of the active conversation.
///
/// Chat library organization, attachments, authentication, and UI-only state
/// deliberately remain outside this controller. This keeps streaming and
/// message persistence testable without rebuilding the entire chat screen.
class ChatConversationController extends ChangeNotifier {
  ChatConversationController({
    required ChatUseCase chatUseCase,
    required ChatCreatedCallback onChatCreated,
    required ChatErrorCallback onError,
    required ChatScrollCallback onScrollRequested,
    ChatLimiter? chatLimiter,
  })  : _chatUseCase = chatUseCase,
        _onChatCreated = onChatCreated,
        _onError = onError,
        _onScrollRequested = onScrollRequested,
        _chatLimiter = chatLimiter ?? ChatLimiter();

  static const Duration _streamUpdateInterval = Duration(milliseconds: 40);

  final ChatUseCase _chatUseCase;
  final ChatCreatedCallback _onChatCreated;
  final ChatErrorCallback _onError;
  final ChatScrollCallback _onScrollRequested;
  final ChatLimiter _chatLimiter;

  Chat? selectedChat;
  List<Message> messages = <Message>[];
  bool isSendingMessage = false;
  bool isLoadingMessages = false;
  bool isSubmittingFeedback = false;
  String? copyingMessageId;

  final Set<String> _submittingFeedbackMessageIds = <String>{};
  int _selectedChatRequestId = 0;
  int _operationId = 0;
  bool _sendAdmissionInProgress = false;
  bool _isDisposed = false;
  Timer? _streamUpdateTimer;
  StreamSubscription<ChatStreamEvent>? _activeResponseSubscription;
  Completer<void>? _activeResponseCompleter;

  StreamController<Message> threadResponseController =
      StreamController<Message>.broadcast();

  void startNewChat() {
    if (_isDisposed) return;
    _invalidateActiveOperation();
    _selectedChatRequestId++;
    selectedChat = null;
    messages = <Message>[];
    notifyListeners();
  }

  Future<void> selectChat(Chat chat) async {
    if (_isDisposed) return;
    _invalidateActiveOperation();
    final requestId = ++_selectedChatRequestId;
    selectedChat = chat;
    isLoadingMessages = true;
    notifyListeners();

    try {
      final loadedMessages = await _chatUseCase.fetchMessages(chat);
      if (_isDisposed || requestId != _selectedChatRequestId) return;

      for (final message in loadedMessages) {
        final cachedFeedbackId =
            FeedbackIdCache.getFeedbackId(chat.id, message.id);
        if (cachedFeedbackId != null) {
          message.feedbackId = cachedFeedbackId;
        }
      }
      messages = loadedMessages;
    } catch (error) {
      if (_isDisposed || requestId != _selectedChatRequestId) return;
      if (kDebugMode) debugPrint('selectChat error: $error');
      messages = <Message>[];
      _onError(
        ChatErrorMapper.from(
          error,
          operation: ChatOperation.loadConversation,
        ),
        retry: () => selectChat(chat),
      );
    } finally {
      if (!_isDisposed && requestId == _selectedChatRequestId) {
        isLoadingMessages = false;
        notifyListeners();
        _onScrollRequested(force: true);
      }
    }
  }

  Future<void> sendMessage({
    required String text,
    required List<ChatFile> attachments,
    required List<String> toolIds,
    ChatModel? model,
    VoidCallback? onMessageAccepted,
  }) async {
    if (_isDisposed || isSendingMessage || _sendAdmissionInProgress) return;

    _sendAdmissionInProgress = true;
    try {
      if (await _chatLimiter.reachChatLimit()) {
        _onError(ChatFailure.dailyLimit());
        return;
      }
    } catch (error) {
      if (kDebugMode) debugPrint('chat limit check error: $error');
      _onError(
        ChatErrorMapper.from(
          error,
          operation: ChatOperation.sendMessage,
          fallbackMessage:
              'Unable to start a chat right now. Please try again.',
        ),
        retry: () => sendMessage(
          text: text,
          attachments: attachments,
          toolIds: toolIds,
          model: model,
          onMessageAccepted: onMessageAccepted,
        ),
      );
      return;
    } finally {
      _sendAdmissionInProgress = false;
    }
    if (_isDisposed) return;

    final prompt =
        text.trim().isEmpty ? _attachmentOnlyPrompt(attachments) : text.trim();
    if (prompt.isEmpty) return;

    final operationId = ++_operationId;
    onMessageAccepted?.call();
    final userMessage = Message(
      role: 'user',
      content: prompt,
      files: List<ChatFile>.from(attachments),
    );

    if (selectedChat != null && messages.isNotEmpty) {
      userMessage.parentId = messages.last.id;
      messages.last.childrenIds = <String>[userMessage.id];
    }
    messages.add(userMessage);
    _setSendingMessage(true);
    _onScrollRequested(force: true);

    try {
      if (selectedChat == null) {
        final newChat = await _chatUseCase.createChat(userMessage);
        if (operationId != _operationId) return;
        selectedChat = newChat;
        await _onChatCreated(newChat);
        if (operationId != _operationId) return;
      }

      final chat = selectedChat;
      if (chat == null || operationId != _operationId) return;
      final messagesForRequest = List<Message>.from(messages);
      final sendId = const Uuid().v4();
      final stream = _chatUseCase.sendMessages(
        messagesForRequest,
        chat,
        sendId,
        toolIds: List<String>.from(toolIds),
        model: model,
      );

      await _processResponseStream(
        stream: stream,
        chat: chat,
        selectedModel: model,
        operationId: operationId,
      );
    } catch (error) {
      if (operationId != _operationId) return;
      if (kDebugMode) debugPrint('sendMessage error: $error');
      _setSendingMessage(false);
      _onError(
        ChatErrorMapper.from(
          error,
          operation: ChatOperation.sendMessage,
        ),
      );
    }
  }

  String _attachmentOnlyPrompt(List<ChatFile> attachments) {
    if (attachments.isEmpty) return '';
    final names = attachments
        .map((file) => file.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (names.isEmpty) return 'Please review the attached file(s).';
    return 'Please review the attached file(s): ${names.join(', ')}.';
  }

  Future<void> _processResponseStream({
    required Stream<ChatStreamEvent> stream,
    required Chat chat,
    required ChatModel? selectedModel,
    required int operationId,
  }) async {
    final responseController =
        await _replaceResponseController(operationId: operationId);
    if (_isDisposed ||
        responseController == null ||
        operationId != _operationId) {
      return;
    }

    final assistantMessage = Message(role: 'assistant');
    if (selectedModel != null) {
      assistantMessage
        ..model = selectedModel.id
        ..modelName = selectedModel.name;
    }
    if (messages.isNotEmpty) {
      assistantMessage.parentId = messages.last.id;
      messages.last.childrenIds = <String>[assistantMessage.id];
    }
    messages.add(assistantMessage);
    chat.updatedAt = _nowTimestamp();
    notifyListeners();

    final responseCompleter = Completer<void>();
    late final StreamSubscription<ChatStreamEvent> responseSubscription;
    responseSubscription = stream.listen(
      (response) {
        if (operationId != _operationId || responseCompleter.isCompleted) {
          return;
        }
        try {
          if (response.error != null) throw Exception(response.error);

          final status = response.status;
          if (status != null && !status.hidden) {
            assistantMessage.statusHistory.add(status);
          }

          if (response.hasContent) {
            if (response.replacesContent) {
              assistantMessage.content = response.content;
            } else {
              assistantMessage.content += response.content;
            }
            if (!responseController.isClosed) {
              responseController.add(
                Message(role: 'assistant', content: response.content),
              );
            }
          }
          _scheduleStreamUpdate(operationId);
        } catch (error, stackTrace) {
          responseCompleter.completeError(error, stackTrace);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!responseCompleter.isCompleted) {
          responseCompleter.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!responseCompleter.isCompleted) responseCompleter.complete();
      },
      cancelOnError: true,
    );
    _activeResponseSubscription = responseSubscription;
    _activeResponseCompleter = responseCompleter;

    try {
      await responseCompleter.future;
      if (operationId != _operationId) return;

      if (assistantMessage.content.trim().isEmpty &&
          assistantMessage.statusHistory.isEmpty) {
        throw StateError('No response received from the chat service.');
      }

      await _chatLimiter.incrementChatCount();
      if (operationId != _operationId) return;
      assistantMessage
        ..thinkingElapsed = math.max(
          0,
          (DateTime.now().millisecondsSinceEpoch -
                  assistantMessage.timestamp) ~/
              1000,
        )
        ..isDone = true;
      chat.updatedAt = _nowTimestamp();
      _flushStreamUpdate(operationId);

      try {
        await _chatUseCase.updateChatMessage(assistantMessage, chat);
        if (operationId != _operationId) return;
        await _chatUseCase.persistMessages(messages, chat);
      } catch (error) {
        if (operationId != _operationId) return;
        if (kDebugMode) debugPrint('persist response error: $error');
        _onError(
          ChatFailure.persistence(),
          retry: () async {
            await _chatUseCase.updateChatMessage(assistantMessage, chat);
            await _chatUseCase.persistMessages(
              List<Message>.from(messages),
              chat,
            );
          },
        );
      }
    } catch (error) {
      if (operationId != _operationId) return;
      final hasPartialResponse = assistantMessage.content.trim().isNotEmpty ||
          assistantMessage.statusHistory.isNotEmpty;
      _handleInterruptedResponse(assistantMessage);
      if (!responseController.isClosed) {
        responseController.addError(error);
      }
      if (kDebugMode) debugPrint('response stream error: $error');
      _onError(
        hasPartialResponse
            ? ChatFailure.interrupted()
            : ChatErrorMapper.from(
                error,
                operation: ChatOperation.sendMessage,
              ),
      );
    } finally {
      if (identical(_activeResponseSubscription, responseSubscription)) {
        _activeResponseSubscription = null;
      }
      if (identical(_activeResponseCompleter, responseCompleter)) {
        _activeResponseCompleter = null;
      }
      await responseSubscription.cancel();
      if (!responseController.isClosed) await responseController.close();
      if (operationId == _operationId) {
        _flushStreamUpdate(operationId);
        _setSendingMessage(false);
      }
    }
  }

  void _handleInterruptedResponse(Message assistantMessage) {
    if (assistantMessage.content.trim().isNotEmpty ||
        assistantMessage.statusHistory.isNotEmpty) {
      assistantMessage.statusHistory.add(
        const ToolStatus(
          action: 'response_interrupted',
          description: 'Response interrupted',
          done: true,
        ),
      );
      assistantMessage.isDone = true;
      return;
    }

    messages.removeWhere((message) => message.id == assistantMessage.id);
    final parentId = assistantMessage.parentId;
    if (parentId == null) return;
    final parentIndex =
        messages.indexWhere((message) => message.id == parentId);
    if (parentIndex >= 0) messages[parentIndex].childrenIds = <String>[];
  }

  Future<StreamController<Message>?> _replaceResponseController({
    int? operationId,
  }) async {
    final previousController = threadResponseController;
    if (!previousController.isClosed) {
      await previousController.close();
    }
    if (operationId != null && operationId != _operationId) return null;

    final nextController = StreamController<Message>.broadcast();
    threadResponseController = nextController;
    return nextController;
  }

  void _scheduleStreamUpdate(int operationId) {
    if (operationId != _operationId) return;
    if (_streamUpdateTimer?.isActive == true) return;
    _streamUpdateTimer = Timer(_streamUpdateInterval, () {
      if (operationId != _operationId) return;
      notifyListeners();
      _onScrollRequested(force: false);
    });
  }

  void _flushStreamUpdate(int operationId) {
    if (operationId != _operationId) return;
    _streamUpdateTimer?.cancel();
    _streamUpdateTimer = null;
    notifyListeners();
    _onScrollRequested(force: false);
  }

  void _invalidateActiveOperation() {
    _operationId++;
    _streamUpdateTimer?.cancel();
    _streamUpdateTimer = null;
    final completer = _activeResponseCompleter;
    if (completer != null && !completer.isCompleted) completer.complete();
    final subscription = _activeResponseSubscription;
    _activeResponseCompleter = null;
    _activeResponseSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    isSendingMessage = false;
  }

  void _setSendingMessage(bool value) {
    if (isSendingMessage == value) return;
    isSendingMessage = value;
    if (!_isDisposed) notifyListeners();
  }

  bool isMessageCopying(Message message) => copyingMessageId == message.id;

  void setCopyingMessage(String? messageId) {
    if (_isDisposed) return;
    copyingMessageId = messageId;
    notifyListeners();
  }

  bool isSubmittingFeedbackFor(Message message) {
    return _submittingFeedbackMessageIds.contains(message.id);
  }

  Future<bool> submitMessageFeedback({
    required Message message,
    required int goodBadRating,
    required int detailsRating,
    required List<String> reasons,
    String? comment,
    required int messageIndex,
  }) async {
    final chat = selectedChat;
    if (_isDisposed ||
        chat == null ||
        _submittingFeedbackMessageIds.contains(message.id)) {
      return false;
    }

    _submittingFeedbackMessageIds.add(message.id);
    isSubmittingFeedback = true;
    notifyListeners();

    try {
      final feedbackId = await _chatUseCase.submitMessageFeedback(
        chat: chat,
        message: message,
        goodBadRating: goodBadRating,
        detailsRating: detailsRating,
        reasons: reasons,
        comment: comment,
        messageIndex: messageIndex,
      );
      if (_isDisposed) return false;
      message
        ..feedbackId = feedbackId
        ..feedbackRating = goodBadRating
        ..feedbackDetailsRating = detailsRating
        ..feedbackReasons = List<String>.from(reasons)
        ..feedbackComment = comment;
      await FeedbackIdCache.setFeedbackId(chat.id, message.id, feedbackId);
      await _chatUseCase.persistMessages(messages, chat);
      if (_isDisposed) return false;
      notifyListeners();
      return true;
    } catch (error) {
      if (_isDisposed) return false;
      if (kDebugMode) debugPrint('submitMessageFeedback error: $error');
      _onError(
        ChatErrorMapper.from(
          error,
          operation: ChatOperation.submitFeedback,
        ),
        retry: () async {
          await submitMessageFeedback(
            message: message,
            goodBadRating: goodBadRating,
            detailsRating: detailsRating,
            reasons: reasons,
            comment: comment,
            messageIndex: messageIndex,
          );
        },
      );
      return false;
    } finally {
      _submittingFeedbackMessageIds.remove(message.id);
      isSubmittingFeedback = _submittingFeedbackMessageIds.isNotEmpty;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> reset() async {
    _invalidateActiveOperation();
    _selectedChatRequestId++;
    selectedChat = null;
    messages = <Message>[];
    isSendingMessage = false;
    isLoadingMessages = false;
    isSubmittingFeedback = false;
    copyingMessageId = null;
    _submittingFeedbackMessageIds.clear();
    await _replaceResponseController();
    notifyListeners();
  }

  int _nowTimestamp() =>
      DateTime.now().microsecondsSinceEpoch ~/
      Duration.microsecondsPerMillisecond;

  @override
  void dispose() {
    _isDisposed = true;
    _selectedChatRequestId++;
    _invalidateActiveOperation();
    if (!threadResponseController.isClosed) {
      threadResponseController.close();
    }
    super.dispose();
  }
}
