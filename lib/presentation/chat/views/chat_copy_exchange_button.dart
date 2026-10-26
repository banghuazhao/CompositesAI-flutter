import 'dart:async';

import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../model/chat_exchange.dart';
import '../viewModels/chat_view_model.dart';

class ChatCopyExchangeButton extends StatefulWidget {
  const ChatCopyExchangeButton({
    super.key,
    required this.viewModel,
    required this.answer,
    this.menuItem = false,
    this.onCopied,
  });

  final ChatViewModel viewModel;
  final Message answer;
  final bool menuItem;
  final VoidCallback? onCopied;

  @override
  State<ChatCopyExchangeButton> createState() => _ChatCopyExchangeButtonState();
}

enum _CopyFeedback { copied, failed }

class _ChatCopyExchangeButtonState extends State<ChatCopyExchangeButton> {
  _ExchangeContext? _observed;
  ModalRoute<dynamic>? _route;
  bool _wasCurrent = false;
  bool _copying = false;
  bool _refreshPending = false;
  int _revision = 0;
  _CopyFeedback? _feedback;

  _ExchangeContext? _capture() {
    final model = widget.viewModel;
    if (model.isDisposed ||
        !model.isLoggedIn ||
        model.isLoadingMessages ||
        model.isSendingMessage ||
        model.selectedChat == null) {
      return null;
    }
    final exchange = ChatExchangeSnapshot.resolve(
      messages: model.messages,
      answer: widget.answer,
    );
    if (exchange == null) return null;
    return _ExchangeContext(
      model,
      model.chatSessionKey,
      model.selectedChat!.id,
      model.chatSelectionRevision,
      exchange,
    );
  }

  void _listen(ChatViewModel model) {
    if (model.isDisposed) return;
    model.addListener(_onModelChanged);
    model.disposalListenable.addListener(_onModelChanged);
  }

  void _unlisten(ChatViewModel model) {
    model.removeListener(_onModelChanged);
    model.disposalListenable.removeListener(_onModelChanged);
  }

  void _onModelChanged() {
    final next = _capture();
    if (_same(_observed, next)) return;
    _observed = next;
    _revision++;
    _feedback = null;
    if (_refreshPending) return;
    _refreshPending = true;
    scheduleMicrotask(() {
      _refreshPending = false;
      if (mounted) setState(() {});
    });
  }

  static bool _same(_ExchangeContext? first, _ExchangeContext? second) =>
      first == null ? second == null : second != null && first.matches(second);

  @override
  void initState() {
    super.initState();
    _observed = _capture();
    _listen(widget.viewModel);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final current = route?.isCurrent == true;
    if (!identical(route, _route) || current != _wasCurrent) {
      _revision++;
      _feedback = null;
      _route = route;
      _wasCurrent = current;
    }
  }

  @override
  void didUpdateWidget(covariant ChatCopyExchangeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.viewModel, widget.viewModel)) {
      _unlisten(oldWidget.viewModel);
      _listen(widget.viewModel);
      _revision++;
    }
    if (!identical(oldWidget.answer, widget.answer)) _revision++;
    final next = _capture();
    if (!_same(_observed, next)) _revision++;
    if (!_same(_observed, next)) _feedback = null;
    _observed = next;
  }

  bool _current(_ExchangeContext snapshot, int revision) {
    if (!mounted ||
        _revision != revision ||
        _route?.isCurrent != true ||
        !identical(_route, ModalRoute.of(context))) {
      return false;
    }
    final current = _capture();
    return current != null && snapshot.matches(current);
  }

  Future<void> _copy(_ExchangeContext snapshot, int revision) async {
    if (_copying || !_current(snapshot, revision)) return;
    final strings = S.maybeOf(context);
    final markdown = snapshot.exchange.toMarkdown(
      questionLabel: strings?.Chat_exchange_question ?? 'Question',
      answerLabel: strings?.Chat_exchange_answer ?? 'Answer',
    );
    setState(() {
      _copying = true;
      _feedback = null;
    });
    try {
      // Clipboard receives only the validated, immutable text captured above.
      await Clipboard.setData(ClipboardData(text: markdown));
      if (_current(snapshot, revision)) {
        setState(() => _feedback = _CopyFeedback.copied);
        widget.onCopied?.call();
      }
    } catch (_) {
      if (_current(snapshot, revision)) {
        setState(() => _feedback = _CopyFeedback.failed);
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  void dispose() {
    _unlisten(widget.viewModel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _capture();
    final revision = _revision;
    final strings = S.maybeOf(context);
    final label = strings?.Chat_copy_exchange ?? 'Copy question and answer';
    final feedback = _same(_observed, snapshot) && _route?.isCurrent == true
        ? _feedback
        : null;
    final status = feedback == _CopyFeedback.copied
        ? strings?.Chat_exchange_copied ?? 'Question and answer copied'
        : feedback == _CopyFeedback.failed
            ? strings?.Chat_exchange_copy_failed ??
                'Could not copy this exchange.'
            : null;
    final icon = _copying
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            feedback == _CopyFeedback.copied
                ? Icons.check_rounded
                : feedback == _CopyFeedback.failed
                    ? Icons.error_outline_rounded
                    : Icons.copy_all_outlined,
            size: 18);
    final onPressed = _copying || snapshot == null
        ? null
        : () => unawaited(_copy(snapshot, revision));
    final width =
        (MediaQuery.sizeOf(context).width - 24).clamp(48.0, 320.0).toDouble();
    Widget statusText() => Semantics(
          key: ValueKey('chat-copy-exchange-status-${widget.answer.id}'),
          liveRegion: true,
          child: Text(status!,
              style: feedback == _CopyFeedback.failed
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null),
        );
    if (widget.menuItem) {
      return MenuItemButton(
        key: ValueKey('chat-copy-exchange-${widget.answer.id}'),
        closeOnActivate: false,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          maximumSize: WidgetStatePropertyAll(Size(width, double.infinity)),
        ),
        leadingIcon: icon,
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (feedback != _CopyFeedback.copied) Text(label),
            if (status != null) statusText(),
          ],
        ),
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          key: ValueKey('chat-copy-exchange-${widget.answer.id}'),
          tooltip: label,
          onPressed: onPressed,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: icon,
        ),
        if (status != null)
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: (width - 48).clamp(0, width).toDouble()),
            child: statusText(),
          ),
      ],
    );
  }
}

class _ExchangeContext {
  const _ExchangeContext(
    this.model,
    this.session,
    this.chatId,
    this.selection,
    this.exchange,
  );

  final ChatViewModel model;
  final Object session;
  final String chatId;
  final int selection;
  final ChatExchangeSnapshot exchange;

  bool matches(_ExchangeContext other) =>
      identical(model, other.model) &&
      session == other.session &&
      chatId == other.chatId &&
      selection == other.selection &&
      exchange.matches(other.exchange);
}
