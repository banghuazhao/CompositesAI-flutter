import 'dart:math' as math;

import 'package:domain/chat/entities/message.dart';
import 'package:flutter/widgets.dart' show CharacterRange;

/// Searches the text already loaded for a conversation without changing it.
class ChatMessageSearch {
  static const int maximumExcerptLength = 240;
  static const int _leadingContextLength = 60;

  static List<ChatMessageSearchMatch> find(
    Iterable<Message> messages,
    String query,
  ) {
    final text = query.trim();
    if (text.isEmpty) return const [];
    // Match against the original text. Lowercasing a separate copy can change
    // UTF-16 offsets (for example, dotted I) and corrupt the excerpt position.
    final pattern =
        RegExp(RegExp.escape(text), caseSensitive: false, unicode: true);
    final results = <ChatMessageSearchMatch>[];
    var index = 0;
    for (final message in messages) {
      final match = pattern.firstMatch(message.content);
      if (match != null) {
        results.add(ChatMessageSearchMatch._(
          messageIndex: index,
          role: message.role,
          content: message.content,
          matchStart: match.start,
        ));
      }
      index++;
    }
    return List.unmodifiable(results);
  }
}

/// An immutable text snapshot. Excerpts are computed only for visible results.
class ChatMessageSearchMatch {
  ChatMessageSearchMatch._({
    required this.messageIndex,
    required this.role,
    required String content,
    required int matchStart,
  })  : _content = content,
        _matchStart = matchStart;

  final int messageIndex;
  final String role;
  final String _content;
  final int _matchStart;

  late final String excerpt = _excerpt();

  String _excerpt() {
    final start =
        math.max(0, _matchStart - ChatMessageSearch._leadingContextLength);
    final end = math.min(
        _content.length, start + ChatMessageSearch.maximumExcerptLength);
    // Expand a UTF-16 window to complete grapheme boundaries, including emoji
    // and combining sequences. The search indices always belong to _content.
    final range = CharacterRange.at(_content, start, end);
    return '${range.stringBeforeLength > 0 ? '…' : ''}'
        '${range.current}'
        '${range.stringAfterLength > 0 ? '…' : ''}';
  }
}
