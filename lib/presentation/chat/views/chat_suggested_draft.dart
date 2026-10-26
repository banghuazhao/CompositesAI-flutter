import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../viewModels/chat_view_model.dart';

/// Prepares a welcome question for review, asking before replacing unsent text.
Future<bool> useChatSuggestionAsDraft(
  BuildContext context,
  ChatViewModel model,
  int index,
) async {
  if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) {
    return false;
  }
  final request = model.prepareSuggestedDraft(index);
  if (request == null) return false;
  if (!request.replacesDraft) return model.applySuggestedDraft(request);

  final owner = ModalRoute.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final composer = model.composerTextController;
  bool closing = false;
  bool observing = true;
  late final DialogRoute<bool> route;
  late final VoidCallback check;

  bool current() =>
      !closing &&
      context.mounted &&
      owner?.isActive == true &&
      model.isSuggestedDraftCurrent(request);

  void detach() {
    if (!observing) return;
    observing = false;
    model.removeListener(check);
    model.disposalListenable.removeListener(check);
    composer.removeListener(check);
  }

  check = () {
    if (current() || closing) return;
    closing = true;
    detach();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted && route.isActive) navigator.removeRoute(route);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  };

  void checkOwnerAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!observing) return;
      check();
      if (observing) checkOwnerAfterFrame();
    });
  }

  route = DialogRoute<bool>(
    context: context,
    builder: (dialogContext) {
      final strings = S.maybeOf(dialogContext);
      return AlertDialog(
        key: const ValueKey('chat-replace-draft-dialog'),
        scrollable: true,
        title: Text(strings?.Chat_replace_draft_title ?? 'Replace draft?'),
        content: Text(strings?.Chat_replace_draft_message ??
            'Replace the current unsent text with this message?'),
        actions: [
          TextButton(
            key: const ValueKey('chat-replace-draft-cancel'),
            onPressed: () {
              if (!closing && route.isCurrent) navigator.pop(false);
            },
            child: Text(strings?.Chat_cancel ?? 'Cancel'),
          ),
          FilledButton(
            key: const ValueKey('chat-replace-draft-confirm'),
            onPressed: () {
              if (current() && route.isCurrent) navigator.pop(true);
            },
            child: Text(strings?.Chat_replace_draft ?? 'Replace draft'),
          ),
        ],
      );
    },
  );
  model.addListener(check);
  model.disposalListenable.addListener(check);
  composer.addListener(check);
  checkOwnerAfterFrame();
  try {
    final confirmed = await navigator.push(route);
    if (confirmed != true ||
        !context.mounted ||
        !current() ||
        ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }
    detach();
    return model.applySuggestedDraft(request);
  } finally {
    closing = true;
    detach();
  }
}
