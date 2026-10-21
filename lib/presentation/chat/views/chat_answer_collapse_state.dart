import 'dart:collection';

import 'package:domain/chat/entities/message.dart';
import 'package:flutter/foundation.dart';

/// Only presentation state. Message content and export data are never changed.
class ChatAnswerCollapseState {
  ChatAnswerCollapseState({int maximumEntries = 64})
      : maximumEntries = maximumEntries < 1 ? 1 : maximumEntries;

  static const int minimumContentLength = 1200;
  static const int minimumLineCount = 16;
  final int maximumEntries;
  final _collapsed = LinkedHashMap<Message, String>.identity();
  Object? _scope;

  @visibleForTesting
  int get collapsedCount => _collapsed.length;

  static bool isLongAnswer(Message message) {
    final text = message.content;
    if (message.role != 'assistant' || text.trim().isEmpty) return false;
    if (text.length >= minimumContentLength) return true;
    var lines = 1;
    for (var index = 0; index < text.length; index++) {
      if (text.codeUnitAt(index) == 10 && ++lines >= minimumLineCount) {
        return true;
      }
    }
    return false;
  }

  void synchronize({
    required Object scope,
    required bool available,
    required List<Message> messages,
    Message? streamingMessage,
  }) {
    if (!available || _scope != scope) _collapsed.clear();
    _scope = scope;
    if (_collapsed.isEmpty) return;
    final current = HashSet<Message>.identity()..addAll(messages);
    _collapsed.removeWhere((message, content) =>
        !current.contains(message) ||
        identical(message, streamingMessage) ||
        content != message.content ||
        !isLongAnswer(message));
  }

  bool isCollapsed(Message message) => _collapsed[message] == message.content;

  void toggle(Message message) {
    if (isCollapsed(message)) {
      _collapsed.remove(message);
      return;
    }
    _collapsed.remove(message);
    _collapsed[message] = message.content;
    while (_collapsed.length > maximumEntries) {
      _collapsed.remove(_collapsed.keys.first);
    }
  }

  void clear() {
    _collapsed.clear();
    _scope = null;
  }
}
