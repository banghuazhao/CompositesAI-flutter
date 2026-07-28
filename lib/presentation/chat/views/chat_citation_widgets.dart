import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/chat_citation.dart';

class ChatCitationBadge extends StatelessWidget {
  const ChatCitationBadge({
    super.key,
    required this.citation,
    required this.onTap,
  });

  final ChatCitation citation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'View citation ${citation.number}, ${citation.displayTitle}',
      child: Tooltip(
        message: 'View ${citation.displayTitle}',
        child: Material(
          color: scheme.primaryContainer,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                child: Text(
                  '${citation.number}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatSourcesButton extends StatelessWidget {
  const ChatSourcesButton({
    super.key,
    required this.citations,
  });

  final List<ChatCitation> citations;

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) return const SizedBox.shrink();
    final availableCount =
        citations.where((citation) => citation.canOpen).length;
    final countLabel =
        '${citations.length} source${citations.length == 1 ? '' : 's'}';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: OutlinedButton.icon(
        key: const ValueKey('chat-sources-button'),
        onPressed: () => ChatCitationSheets.showSources(context, citations),
        icon: const Icon(Icons.library_books_outlined, size: 17),
        label: Text(
          availableCount == citations.length
              ? countLabel
              : '$countLabel · $availableCount links',
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 36),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
    );
  }
}

class ChatCitationSheets {
  const ChatCitationSheets._();

  static Future<void> showCitation(
    BuildContext context,
    ChatCitation citation,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _CitationDetails(citation: citation),
    );
  }

  static Future<void> showSources(
    BuildContext context,
    List<ChatCitation> citations,
  ) {
    final pageContext = context;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Sources',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: citations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final citation = citations[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text('${citation.number}'),
                      ),
                      title: Text(
                        citation.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: citation.uri == null
                          ? const Text('Link information unavailable')
                          : Text(
                              citation.uri.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (pageContext.mounted) {
                            showCitation(pageContext, citation);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CitationDetails extends StatelessWidget {
  const _CitationDetails({required this.citation});

  final ChatCitation citation;

  Future<void> _openSource(BuildContext context) async {
    final uri = citation.uri;
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this source.')),
      );
    }
  }

  Future<void> _copySource(BuildContext context) async {
    final uri = citation.uri;
    if (uri == null) return;
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source link copied.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(
                    '${citation.number}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    citation.displayTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            if (citation.context?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                citation.context!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Source link',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                citation.uri?.toString() ??
                    (citation.label?.isNotEmpty == true
                        ? 'No external link is available for “${citation.label}”.'
                        : 'The response did not include a link for this citation.'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (citation.uri != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copySource(context),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy link'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openSource(context),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open source'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
