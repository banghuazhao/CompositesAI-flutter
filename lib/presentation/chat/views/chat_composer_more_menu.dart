import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

/// Secondary composer actions; callbacks retain their owner's scope guards.
class ChatComposerMoreMenu extends StatelessWidget {
  const ChatComposerMoreMenu({
    super.key,
    required this.onClear,
    this.onExpand,
  });

  final VoidCallback? onClear;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final strings = S.maybeOf(context);
    final width = (MediaQuery.sizeOf(context).width - 24).clamp(48.0, 320.0);
    final itemStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      maximumSize:
          WidgetStatePropertyAll(Size(width.toDouble(), double.infinity)),
    );
    return MenuAnchor(
      menuChildren: [
        if (onExpand != null)
          MenuItemButton(
            key: const Key('chat-expand-composer'),
            style: itemStyle,
            leadingIcon: const Icon(Icons.open_in_full_rounded),
            onPressed: onExpand,
            child: Text(strings?.Chat_expand_composer ?? 'Expand composer'),
          ),
        MenuItemButton(
          key: const Key('chat-clear-draft'),
          style: itemStyle,
          leadingIcon: const Icon(Icons.clear_rounded),
          onPressed: onClear,
          child: Text(strings?.Chat_clear_draft ?? 'Clear draft'),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        key: const Key('chat-composer-more'),
        tooltip: strings?.Chat_more_actions ?? 'More actions',
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.more_horiz_rounded),
      ),
    );
  }
}
