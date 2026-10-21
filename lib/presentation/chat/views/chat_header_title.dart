import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../viewModels/chat_view_model.dart';

/// Identifies the selected conversation without taking space from its actions.
class ChatHeaderTitle extends StatefulWidget {
  const ChatHeaderTitle({super.key, required this.viewModel});

  final ChatViewModel viewModel;

  @override
  State<ChatHeaderTitle> createState() => _ChatHeaderTitleState();
}

class _ChatHeaderTitleState extends State<ChatHeaderTitle> {
  // Weak ownership records prevent a retained selection from displaying its
  // private title after an account/session change, without retaining old chats.
  Expando<Object> _selectionSessions = Expando<Object>();
  late Listenable _changes;

  @override
  void initState() {
    super.initState();
    _observeModel();
  }

  void _observeModel() {
    if (widget.viewModel.isDisposed) {
      _changes = Listenable.merge(const []);
      return;
    }
    _changes = Listenable.merge([
      widget.viewModel,
      widget.viewModel.disposalListenable,
    ]);
  }

  @override
  void didUpdateWidget(covariant ChatHeaderTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _selectionSessions = Expando<Object>();
      _observeModel();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _changes,
        builder: (context, _) {
          final model = widget.viewModel;
          final strings = S.maybeOf(context);
          final session = model.chatSessionKey;
          final selected = model.selectedChat;
          var showSelection =
              !model.isDisposed && model.isLoggedIn && selected != null;
          if (showSelection) {
            final owner = _selectionSessions[selected];
            if (owner == null) {
              _selectionSessions[selected] = session;
            } else if (owner != session) {
              showSelection = false;
            }
          }

          final title = showSelection
              ? selected!.title.trim().isEmpty
                  ? strings?.Chat_untitled_chat ?? 'Untitled chat'
                  : selected.title
              : strings?.Chat_title ?? 'Chat';
          final label = Semantics(
            key: const Key('chat-header-title-semantics'),
            header: true,
            label: title,
            child: ExcludeSemantics(
              child: Text(
                title,
                key: const Key('chat-header-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
          if (!showSelection) return label;
          return Tooltip(
            // A replaced Tooltip also removes an already visible old overlay.
            key: ValueKey((session, selected!.id, title)),
            message: title,
            excludeFromSemantics: true,
            margin: const EdgeInsets.all(12),
            child: label,
          );
        },
      );
}
