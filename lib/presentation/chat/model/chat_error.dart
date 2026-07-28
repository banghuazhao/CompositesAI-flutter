import 'dart:async';

import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/foundation.dart';

enum ChatErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  rateLimited,
  invalidRequest,
  notFound,
  serviceUnavailable,
  interrupted,
  persistence,
  upload,
  limitReached,
  unknown,
}

enum ChatErrorSeverity { warning, error }

enum ChatOperation {
  authenticate,
  loadConversation,
  sendMessage,
  loadChats,
  loadMoreChats,
  loadFilters,
  loadTools,
  loadKnowledge,
  uploadFile,
  uploadImage,
  updateChat,
  submitFeedback,
  shareChat,
  synchronizeHistory,
}

@immutable
class ChatFailure {
  const ChatFailure({
    required this.type,
    required this.operation,
    required this.title,
    required this.message,
    this.severity = ChatErrorSeverity.error,
    this.retryable = false,
    this.technicalCode = 'CHAT_UNKNOWN',
  });

  final ChatErrorType type;
  final ChatOperation operation;
  final String title;
  final String message;
  final ChatErrorSeverity severity;
  final bool retryable;
  final String technicalCode;

  factory ChatFailure.dailyLimit() {
    return const ChatFailure(
      type: ChatErrorType.limitReached,
      operation: ChatOperation.sendMessage,
      title: 'Daily limit reached',
      message: 'Daily chat limit reached (50/day)',
      severity: ChatErrorSeverity.warning,
      technicalCode: 'CHAT_DAILY_LIMIT',
    );
  }

  factory ChatFailure.interrupted() {
    return const ChatFailure(
      type: ChatErrorType.interrupted,
      operation: ChatOperation.sendMessage,
      title: 'Response interrupted',
      message: 'The response was interrupted. Please try again.',
      retryable: true,
      technicalCode: 'CHAT_STREAM_INTERRUPTED',
    );
  }

  factory ChatFailure.persistence() {
    return const ChatFailure(
      type: ChatErrorType.persistence,
      operation: ChatOperation.synchronizeHistory,
      title: 'History not synchronized',
      message: 'Response received, but chat history could not be synchronized.',
      severity: ChatErrorSeverity.warning,
      retryable: true,
      technicalCode: 'CHAT_HISTORY_SYNC',
    );
  }

  factory ChatFailure.validation({
    required ChatOperation operation,
    required String title,
    required String message,
    String technicalCode = 'CHAT_VALIDATION',
  }) {
    return ChatFailure(
      type: ChatErrorType.invalidRequest,
      operation: operation,
      title: title,
      message: message,
      severity: ChatErrorSeverity.warning,
      technicalCode: technicalCode,
    );
  }
}

@immutable
class ChatErrorNotice {
  const ChatErrorNotice({
    required this.id,
    required this.failure,
    required this.hasRetry,
  });

  final int id;
  final ChatFailure failure;
  final bool hasRetry;

  String get title => failure.title;
  String get message => failure.message;
  ChatErrorSeverity get severity => failure.severity;
  bool get canRetry => hasRetry && failure.retryable;
}

class ChatErrorMapper {
  const ChatErrorMapper._();

  static ChatFailure from(
    Object error, {
    required ChatOperation operation,
    String? fallbackMessage,
  }) {
    if (error is TimeoutException) {
      return _failure(
        type: ChatErrorType.timeout,
        operation: operation,
        title: 'Request timed out',
        message: 'The service took too long to respond. Please try again.',
        retryable: true,
        technicalCode: 'CHAT_TIMEOUT',
      );
    }
    if (error is UnauthorizedException) {
      return _failure(
        type: ChatErrorType.unauthorized,
        operation: operation,
        title: 'Session expired',
        message: 'Please sign in again to continue chatting.',
        technicalCode: 'CHAT_UNAUTHORIZED',
      );
    }
    if (error is ForbiddenException) {
      return _failure(
        type: ChatErrorType.forbidden,
        operation: operation,
        title: 'Access denied',
        message: 'Your account does not have access to this chat resource.',
        technicalCode: 'CHAT_FORBIDDEN',
      );
    }
    if (error is TooManyRequestsException) {
      return _failure(
        type: ChatErrorType.rateLimited,
        operation: operation,
        title: 'Too many requests',
        message: 'Please wait a moment before trying again.',
        severity: ChatErrorSeverity.warning,
        retryable: true,
        technicalCode: 'CHAT_RATE_LIMITED',
      );
    }
    if (error is NotFoundException) {
      return _failure(
        type: ChatErrorType.notFound,
        operation: operation,
        title: 'Chat not found',
        message: 'This chat may have been removed or is no longer available.',
        technicalCode: 'CHAT_NOT_FOUND',
      );
    }
    if (error is BadRequestException || error is UnprocessableEntityException) {
      return _failure(
        type: ChatErrorType.invalidRequest,
        operation: operation,
        title: 'Could not complete request',
        message: fallbackMessage ?? _defaultMessage(operation),
        technicalCode: 'CHAT_INVALID_REQUEST',
      );
    }
    if (error is InternalServerErrorException) {
      return _serviceUnavailable(operation);
    }

    final normalized = error.toString().toLowerCase();
    if (_containsAny(normalized, const [
      'timeout',
      'timed out',
      'deadline exceeded',
    ])) {
      return from(
        TimeoutException('Chat request timed out'),
        operation: operation,
        fallbackMessage: fallbackMessage,
      );
    }
    if (_containsAny(normalized, const [
      'socketexception',
      'failed host lookup',
      'connection refused',
      'connection reset',
      'network is unreachable',
      'network request failed',
      'xmlhttprequest error',
      'clientexception',
      'offline',
    ])) {
      return _failure(
        type: ChatErrorType.network,
        operation: operation,
        title: 'Connection problem',
        message: 'Check your internet connection and try again.',
        retryable: true,
        technicalCode: 'CHAT_NETWORK',
      );
    }
    if (_containsAny(normalized, const [
      '401',
      'unauthorized',
      'token expired',
      'invalid token',
    ])) {
      return from(
        UnauthorizedException(),
        operation: operation,
        fallbackMessage: fallbackMessage,
      );
    }
    if (_containsAny(normalized, const [
      '429',
      'too many requests',
      'rate limit',
    ])) {
      return from(
        TooManyRequestsException(),
        operation: operation,
        fallbackMessage: fallbackMessage,
      );
    }
    if (_containsAny(normalized, const [
      '500',
      '502',
      '503',
      '504',
      'internal server',
      'service unavailable',
      'bad gateway',
    ])) {
      return _serviceUnavailable(operation);
    }

    return _failure(
      type: operation == ChatOperation.uploadFile ||
              operation == ChatOperation.uploadImage
          ? ChatErrorType.upload
          : ChatErrorType.unknown,
      operation: operation,
      title: _defaultTitle(operation),
      message: fallbackMessage ?? _defaultMessage(operation),
      retryable: _isSafeToRetry(operation),
      technicalCode: 'CHAT_${operation.name.toUpperCase()}_FAILED',
    );
  }

  static ChatFailure _serviceUnavailable(ChatOperation operation) {
    return _failure(
      type: ChatErrorType.serviceUnavailable,
      operation: operation,
      title: 'Service temporarily unavailable',
      message: 'The chat service is having trouble. Please try again shortly.',
      retryable: true,
      technicalCode: 'CHAT_SERVICE_UNAVAILABLE',
    );
  }

  static ChatFailure _failure({
    required ChatErrorType type,
    required ChatOperation operation,
    required String title,
    required String message,
    ChatErrorSeverity severity = ChatErrorSeverity.error,
    bool retryable = false,
    required String technicalCode,
  }) {
    return ChatFailure(
      type: type,
      operation: operation,
      title: title,
      message: message,
      severity: severity,
      retryable: retryable,
      technicalCode: technicalCode,
    );
  }

  static String _defaultTitle(ChatOperation operation) {
    switch (operation) {
      case ChatOperation.authenticate:
        return 'Could not verify session';
      case ChatOperation.uploadFile:
      case ChatOperation.uploadImage:
        return 'Upload failed';
      case ChatOperation.loadConversation:
      case ChatOperation.loadChats:
      case ChatOperation.loadMoreChats:
      case ChatOperation.loadFilters:
      case ChatOperation.loadTools:
      case ChatOperation.loadKnowledge:
        return 'Could not load chat data';
      case ChatOperation.submitFeedback:
        return 'Feedback not saved';
      case ChatOperation.shareChat:
        return 'Could not share chat';
      case ChatOperation.synchronizeHistory:
        return 'History not synchronized';
      case ChatOperation.sendMessage:
        return 'Message not sent';
      case ChatOperation.updateChat:
        return 'Chat update failed';
    }
  }

  static String _defaultMessage(ChatOperation operation) {
    switch (operation) {
      case ChatOperation.authenticate:
        return 'Your session could not be verified. Please try again.';
      case ChatOperation.loadConversation:
        return 'Chat messages could not be loaded. Please try again.';
      case ChatOperation.loadChats:
        return 'Your chat history could not be loaded. Please try again.';
      case ChatOperation.loadMoreChats:
        return 'More chats could not be loaded. Please try again.';
      case ChatOperation.loadFilters:
        return 'Filtered chats could not be loaded. Please try again.';
      case ChatOperation.loadTools:
        return 'Chat tools could not be loaded. You can still use basic chat.';
      case ChatOperation.loadKnowledge:
        return 'Knowledge sources could not be loaded.';
      case ChatOperation.uploadFile:
        return 'The file could not be uploaded. Please try again.';
      case ChatOperation.uploadImage:
        return 'The image could not be uploaded. Please try again.';
      case ChatOperation.updateChat:
        return 'The chat could not be updated. Please try again.';
      case ChatOperation.submitFeedback:
        return 'Your feedback could not be saved. Please try again.';
      case ChatOperation.shareChat:
        return 'A share link could not be created. Please try again.';
      case ChatOperation.synchronizeHistory:
        return 'The latest changes could not be synchronized.';
      case ChatOperation.sendMessage:
        return 'Your message could not be sent. Please try again.';
    }
  }

  static bool _isSafeToRetry(ChatOperation operation) {
    return switch (operation) {
      ChatOperation.authenticate ||
      ChatOperation.loadConversation ||
      ChatOperation.loadChats ||
      ChatOperation.loadMoreChats ||
      ChatOperation.loadFilters ||
      ChatOperation.loadTools ||
      ChatOperation.loadKnowledge ||
      ChatOperation.uploadFile ||
      ChatOperation.uploadImage ||
      ChatOperation.submitFeedback ||
      ChatOperation.shareChat ||
      ChatOperation.synchronizeHistory =>
        true,
      ChatOperation.sendMessage || ChatOperation.updateChat => false,
    };
  }

  static bool _containsAny(String value, List<String> candidates) {
    return candidates.any(value.contains);
  }
}
