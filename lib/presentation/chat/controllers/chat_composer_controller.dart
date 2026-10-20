import 'package:flutter/widgets.dart';

/// Account-scoped, in-memory composer drafts. Null identifies New chat and is
/// distinct from every server chat ID, including an empty ID.
class ChatComposerController {
  ChatComposerController({int maximumDrafts = defaultMaximumDrafts})
      : maximumDrafts = maximumDrafts < 1 ? 1 : maximumDrafts {
    textController.addListener(_recordEdit);
    _recordEdit();
  }

  static const int defaultMaximumDrafts = 20;
  final int maximumDrafts;
  final TextEditingController textController = TextEditingController();
  final _drafts = <String?, _Draft>{};
  String? _chatId;
  int _epoch = 0;
  bool _restoring = false;
  bool _disposed = false;

  @visibleForTesting
  int get cachedDraftCount => _drafts.length;

  void _recordEdit() {
    if (_restoring || _disposed) return;
    final value = _restorable(textController.value);
    final previous = _drafts[_chatId];
    _store(
        _chatId,
        _Draft(value,
            revision: previous?.value.text == value.text
                ? previous?.revision
                : null));
  }

  void _store(String? id, _Draft draft) {
    _drafts.remove(id);
    _drafts[id] = draft;
    while (_drafts.length > maximumDrafts) {
      _drafts.remove(_drafts.keys.first);
    }
  }

  static TextEditingValue _restorable(TextEditingValue value) {
    final selection = value.selection;
    return TextEditingValue(
      text: value.text,
      selection: selection.isValid &&
              selection.baseOffset <= value.text.length &&
              selection.extentOffset <= value.text.length
          ? selection
          : TextSelection.collapsed(offset: value.text.length),
      composing: TextRange.empty,
    );
  }

  void selectChat(String? chatId) {
    if (_disposed || chatId == _chatId) return;
    _chatId = chatId;
    final draft = _drafts[chatId] ?? _Draft(TextEditingValue.empty);
    _store(chatId, draft);
    _restoring = true;
    try {
      textController.value = _restorable(draft.value);
    } finally {
      _restoring = false;
    }
  }

  /// Moves any newly typed follow-up from New chat to the server-created chat.
  /// The New-chat slot stays empty when the user starts another conversation.
  void adoptNewChat(String chatId) {
    if (_disposed || _chatId != null) return;
    final draft = _drafts.remove(null) ?? _Draft(TextEditingValue.empty);
    _chatId = chatId;
    _store(chatId, draft);
  }

  ChatComposerTicket takeTicket() {
    final draft = _drafts[_chatId] ?? _Draft(_restorable(textController.value));
    _store(_chatId, draft);
    return ChatComposerTicket._(_epoch, _chatId, draft);
  }

  bool isCurrent(ChatComposerTicket ticket) =>
      !_disposed &&
      ticket._epoch == _epoch &&
      ticket._chatId == _chatId &&
      identical(_drafts[_chatId]?.revision, ticket._draft.revision);

  bool replaceIfCurrent(ChatComposerTicket ticket, String text) {
    if (!isCurrent(ticket)) return false;
    final value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    // A deliberate replacement is a new draft even when its text is identical.
    _store(_chatId, _Draft(value));
    _restoring = true;
    try {
      textController.value = value;
    } finally {
      _restoring = false;
    }
    return true;
  }

  /// Accepted sends may clear only the exact draft that initiated the request.
  void accept(ChatComposerTicket ticket) {
    if (_disposed ||
        ticket._epoch != _epoch ||
        !identical(_drafts[ticket._chatId]?.revision, ticket._draft.revision)) {
      return;
    }
    final cleared = _Draft(
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)));
    _store(ticket._chatId, cleared);
    if (_chatId != ticket._chatId) return;
    _restoring = true;
    try {
      textController.value = cleared.value;
    } finally {
      _restoring = false;
    }
  }

  void removeChat(String chatId) {
    if (_disposed) return;
    _drafts.remove(chatId);
    if (_chatId == chatId) selectChat(null);
  }

  void clear() {
    if (_disposed) return;
    _epoch++;
    _drafts.clear();
    _chatId = null;
    _restoring = true;
    try {
      textController.value =
          const TextEditingValue(selection: TextSelection.collapsed(offset: 0));
    } finally {
      _restoring = false;
    }
  }

  void dispose() {
    if (_disposed) return;
    clear();
    _disposed = true;
    textController.removeListener(_recordEdit);
    textController.dispose();
  }
}

class ChatComposerTicket {
  const ChatComposerTicket._(this._epoch, this._chatId, this._draft);

  final int _epoch;
  final String? _chatId;
  final _Draft _draft;

  TextEditingValue get value => _draft.value;
}

class _Draft {
  _Draft(this.value, {Object? revision}) : revision = revision ?? Object();

  final TextEditingValue value;
  final Object revision;
}
