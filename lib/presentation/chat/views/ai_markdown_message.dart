import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/chat_citation.dart';
import 'chat_citation_widgets.dart';
import 'chat_reading_style.dart';

class AiMarkdownMessage extends StatelessWidget {
  const AiMarkdownMessage({
    super.key,
    required this.markdown,
    this.citations = const [],
  });

  final String markdown;
  final List<ChatCitation> citations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseStyle = ChatReadingStyle.body(context);

    final markdownTheme = GptMarkdownThemeData(
      brightness: theme.brightness,
      h1: baseStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      h2: baseStyle.copyWith(fontSize: 19, fontWeight: FontWeight.w700),
      h3: baseStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
      h4: baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      h5: baseStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      h6: baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      linkColor: scheme.primary,
      linkHoverColor: scheme.primary,
      hrLineColor: scheme.outlineVariant,
      highlightColor: scheme.tertiaryContainer,
    );

    return SelectionArea(
      child: GptMarkdownTheme(
        gptThemeData: markdownTheme,
        child: GptMarkdown(
          ChatCitationParser.normalizeMarkdown(markdown),
          style: baseStyle,
          followLinkColor: true,
          useDollarSignsForLatex: true,
          latexBuilder: _buildLatex,
          codeBuilder: _buildCodeBlock,
          sourceTagBuilder: _buildCitation,
          onLinkTap: (url, title) => _openLink(context, url, title),
        ),
      ),
    );
  }

  Widget _buildCitation(
    BuildContext context,
    String content,
    TextStyle textStyle,
  ) {
    final number = int.tryParse(content);
    final citation =
        citations.where((item) => item.number == number).firstOrNull;
    final resolved = citation ?? ChatCitation(number: number ?? 0);
    return ChatCitationBadge(
      citation: resolved,
      onTap: () => ChatCitationSheets.showCitation(context, resolved),
    );
  }

  static Future<void> _openLink(
    BuildContext context,
    String url,
    String title,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.maybeOf(context)?.Chat_open_link_failed ??
                'Could not open this link.',
          ),
        ),
      );
    }
  }

  static Widget _buildLatex(
    BuildContext context,
    String tex,
    TextStyle textStyle,
    bool inline,
  ) {
    final math = Math.tex(
      tex,
      textStyle: textStyle,
      mathStyle: inline ? MathStyle.text : MathStyle.display,
    );

    if (inline && tex.length < 50) return math;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: math,
    );
  }

  static Widget _buildCodeBlock(
    BuildContext context,
    String language,
    String code,
    bool closed,
  ) {
    return _CodeBlock(
      language: language.trim().isEmpty
          ? (S.maybeOf(context)?.Chat_code ?? 'code')
          : language.trim(),
      code: code,
      isStreaming: !closed,
    );
  }
}

class _CodeBlock extends StatefulWidget {
  const _CodeBlock({
    required this.language,
    required this.code,
    required this.isStreaming,
  });

  final String language;
  final String code;
  final bool isStreaming;

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;
  bool _copying = false;
  String? _copyError;
  Timer? _resetCopied;
  int _copyRevision = 0;

  @override
  void didUpdateWidget(covariant _CodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code ||
        oldWidget.language != widget.language) {
      _copyRevision++;
      _resetCopied?.cancel();
      _copied = false;
      _copyError = null;
    }
  }

  Future<void> _copyCode() async {
    if (!mounted || _copying || widget.code.isEmpty) return;
    final code = widget.code;
    final revision = _copyRevision;
    final failed = S.maybeOf(context)?.Chat_code_copy_failed ??
        'Could not copy this code.';
    setState(() {
      _copying = true;
      _copyError = null;
    });
    try {
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted || revision != _copyRevision) return;
      setState(() => _copied = true);
      _resetCopied?.cancel();
      _resetCopied = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    } catch (_) {
      if (!mounted || revision != _copyRevision) return;
      setState(() => _copyError = failed);
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  void dispose() {
    _resetCopied?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageLabel = widget.isStreaming
        ? (S.maybeOf(context)?.Chat_code_streaming(widget.language) ??
            '${widget.language} - streaming')
        : widget.language;

    return Container(
      key: const Key('chat-code-surface'),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ChatReadingStyle.codeSurface(context),
        borderRadius: BorderRadius.circular(ChatReadingStyle.codeRadius),
        border: Border.all(color: ChatReadingStyle.codeBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const Key('chat-code-header'),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.only(left: 12, right: 4),
            color: ChatReadingStyle.codeHeader(context),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    languageLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ChatReadingStyle.metadata(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: _copied
                      ? (S.maybeOf(context)?.Chat_copied ?? 'Copied')
                      : (S.maybeOf(context)?.Chat_copy_code ?? 'Copy code'),
                  onPressed: widget.code.isEmpty || _copying ? null : _copyCode,
                  icon: _copying
                      ? const SizedBox.square(
                          dimension: ChatReadingStyle.iconSize,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _copied ? Icons.check : Icons.copy,
                          size: ChatReadingStyle.iconSize,
                        ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(48),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                ),
              ],
            ),
          ),
          if (_copyError != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  _copyError!,
                  key: const Key('chat-code-copy-error'),
                  style: ChatReadingStyle.metadata(context,
                      color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              widget.code,
              style: ChatReadingStyle.code(context),
            ),
          ),
        ],
      ),
    );
  }
}
