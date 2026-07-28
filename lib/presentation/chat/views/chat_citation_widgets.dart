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
        message: 'Source [${citation.number}]',
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _CitationDetails(citation: citation),
    );
  }
}

class _CitationDetails extends StatelessWidget {
  const _CitationDetails({required this.citation});

  final ChatCitation citation;

  Future<void> _copyCitation(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: citation.copyText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Citation copied.')),
      );
    }
  }

  Future<void> _openUri(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this source.')),
      );
    }
  }

  String get _citationBody {
    final bibliographic = citation.bibliographicText?.trim() ?? '';
    final isWeakBibliographic = bibliographic.isEmpty ||
        RegExp(r'^Source\s*\[?\d+\]?$', caseSensitive: false)
            .hasMatch(bibliographic);

    if (!isWeakBibliographic) return bibliographic;

    final title = citation.displayTitle.trim();
    final hasUsefulTitle = title.isNotEmpty &&
        !RegExp(r'^Source\s*\[?\d+\]?$', caseSensitive: false).hasMatch(title);
    if (citation.uri != null) {
      if (hasUsefulTitle && title != citation.uri.toString()) {
        return '$title\n${citation.uri}';
      }
      return citation.uri.toString();
    }
    if (hasUsefulTitle) return title;
    return 'Source details were not included for citation ${citation.number}.';
  }

  List<String> get _excerpts {
    if (citation.excerpts.isNotEmpty) return citation.excerpts;
    final context = citation.context?.trim() ?? '';
    if (context.isEmpty) return const [];
    // Avoid showing research-status fluff as an "excerpt".
    if (context.startsWith('Referenced while researching')) return const [];
    return [context];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final excerpts = _excerpts;
    final citationBody = _citationBody;
    final linkMatches = RegExp(r'https?://[^\s]+').allMatches(citationBody);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Source [${citation.number}]',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copyCitation(context),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CITATION',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText.rich(
                      TextSpan(
                        style: textTheme.bodyMedium?.copyWith(height: 1.45),
                        children: _linkifiedSpans(
                          citationBody,
                          linkMatches,
                          scheme.primary,
                        ),
                      ),
                      onTap: () {
                        final uri = citation.uri;
                        if (uri != null) _openUri(context, uri);
                      },
                    ),
                  ],
                ),
              ),
              for (var index = 0; index < excerpts.length; index++) ...[
                const SizedBox(height: 18),
                Text(
                  'EXCERPT ${index + 1}',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  excerpts[index],
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: scheme.onSurface,
                  ),
                ),
              ],
              if (citation.uri != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openUri(context, citation.uri!),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open source'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _linkifiedSpans(
    String text,
    Iterable<RegExpMatch> matches,
    Color linkColor,
  ) {
    if (matches.isEmpty) return [TextSpan(text: text)];

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: linkColor,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }
}
