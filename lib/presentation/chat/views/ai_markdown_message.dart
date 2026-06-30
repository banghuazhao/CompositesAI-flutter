import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AiMarkdownMessage extends StatelessWidget {
  const AiMarkdownMessage({
    super.key,
    required this.markdown,
  });

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF202123),
          fontSize: 15,
          height: 1.5,
          letterSpacing: 0,
        ) ??
        const TextStyle(
          color: Color(0xFF202123),
          fontSize: 15,
          height: 1.5,
          letterSpacing: 0,
        );

    final markdownTheme = GptMarkdownThemeData(
      brightness: theme.brightness,
      h1: baseStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      h2: baseStyle.copyWith(fontSize: 19, fontWeight: FontWeight.w700),
      h3: baseStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
      h4: baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      h5: baseStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      h6: baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      linkColor: const Color(0xFF0B57D0),
      linkHoverColor: const Color(0xFF0B57D0),
      hrLineColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFFFF3BF),
    );

    return SelectionArea(
      child: GptMarkdownTheme(
        gptThemeData: markdownTheme,
        child: GptMarkdown(
          _cleanMarkdown(markdown),
          style: baseStyle,
          followLinkColor: true,
          useDollarSignsForLatex: true,
          latexBuilder: _buildLatex,
          codeBuilder: _buildCodeBlock,
          onLinkTap: _openLink,
        ),
      ),
    );
  }

  static String _cleanMarkdown(String value) {
    final toolDetailsRegExp =
        RegExp(r'<details[^>]*type="tool_calls"[\s\S]*?<\/details>');
    final citationRegExp = RegExp(r'【.*?】');

    return value
        .replaceAll('\r\n', '\n')
        .replaceAll(toolDetailsRegExp, '')
        .replaceAll(citationRegExp, '')
        .trimRight();
  }

  static Future<void> _openLink(String url, String title) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      language: language.trim().isEmpty ? 'code' : language.trim(),
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

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final languageLabel =
        widget.isStreaming ? '${widget.language} - streaming' : widget.language;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.only(left: 12, right: 4),
            color: const Color(0xFF111827),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    languageLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _copied ? 'Copied' : 'Copy code',
                  onPressed: widget.code.isEmpty ? null : _copyCode,
                  icon: Icon(
                    _copied ? Icons.check : Icons.copy,
                    size: 16,
                    color: const Color(0xFFE5E7EB),
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(32),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              widget.code,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
