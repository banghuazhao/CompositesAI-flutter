import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_fonts.dart';

/// Converts the Markdown that chat answers use into PDF widgets.
///
/// This covers what the assistant actually produces: headings, paragraphs,
/// bullet and numbered lists, block quotes, fenced code, tables, rules, and
/// inline bold, code, links and math. LaTeX is shown as readable text with
/// common symbols (\sigma, \le, \times, …) replaced by their Unicode glyphs.
class MarkdownPdf {
  MarkdownPdf(this.fonts, {this.baseFontSize = 10.5});

  final PdfFonts fonts;
  final double baseFontSize;

  static const PdfColor _muted = PdfColor.fromInt(0xFF5F6368);
  static const PdfColor _codeBackground = PdfColor.fromInt(0xFFF1F3F4);
  static const PdfColor _rule = PdfColor.fromInt(0xFFDADCE0);
  static const PdfColor _link = PdfColor.fromInt(0xFF1A73E8);

  static final RegExp _heading = RegExp(r'^(#{1,6})\s+(.*)$');
  static final RegExp _bullet = RegExp(r'^(\s*)[-*+]\s+(.*)$');
  static final RegExp _ordered = RegExp(r'^(\s*)(\d+)[.)]\s+(.*)$');
  static final RegExp _rulePattern = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
  static final RegExp _tableSeparator =
      RegExp(r'^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$');
  static final RegExp _inline = RegExp(
    r'(\*\*[^*]+\*\*|__[^_]+__|`[^`]+`|\[[^\]]+\]\([^)\s]+\)|\$[^$\n]+\$|\\\(.+?\\\)|\*[^*\s][^*]*\*)',
  );

  List<pw.Widget> build(String markdown) {
    final lines = markdown.replaceAll('\r\n', '\n').split('\n');
    final widgets = <pw.Widget>[];
    final paragraph = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      widgets.add(_paragraph(paragraph.join(' ')));
      paragraph.clear();
    }

    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        flushParagraph();
        i++;
        continue;
      }

      if (trimmed.startsWith('```')) {
        flushParagraph();
        final code = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          code.add(lines[i]);
          i++;
        }
        i++; // Closing fence.
        widgets.add(_codeBlock(code.join('\n')));
        continue;
      }

      if (trimmed.startsWith(r'$$') || trimmed.startsWith(r'\[')) {
        flushParagraph();
        final closing = trimmed.startsWith(r'$$') ? r'$$' : r'\]';
        final math = <String>[trimmed.substring(2)];
        var closed = math.first.trimRight().endsWith(closing);
        i++;
        while (!closed && i < lines.length) {
          math.add(lines[i]);
          closed = lines[i].trimRight().endsWith(closing);
          i++;
        }
        var text = math.join(' ').trim();
        if (text.endsWith(closing)) {
          text = text.substring(0, text.length - closing.length);
        }
        widgets.add(_mathBlock(text.trim()));
        continue;
      }

      if (_rulePattern.hasMatch(line)) {
        flushParagraph();
        widgets.add(pw.Divider(color: _rule, thickness: 0.6, height: 14));
        i++;
        continue;
      }

      final heading = _heading.firstMatch(trimmed);
      if (heading != null) {
        flushParagraph();
        widgets.add(_headingBlock(heading.group(1)!.length, heading.group(2)!));
        i++;
        continue;
      }

      if (trimmed.startsWith('|') &&
          i + 1 < lines.length &&
          _tableSeparator.hasMatch(lines[i + 1])) {
        flushParagraph();
        final rows = <List<String>>[_tableCells(trimmed)];
        i += 2;
        while (i < lines.length && lines[i].trim().startsWith('|')) {
          rows.add(_tableCells(lines[i].trim()));
          i++;
        }
        widgets.add(_table(rows));
        continue;
      }

      if (trimmed.startsWith('>')) {
        flushParagraph();
        final quote = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('>')) {
          quote.add(lines[i].trim().replaceFirst(RegExp(r'^>\s?'), ''));
          i++;
        }
        widgets.add(_quote(quote.join(' ')));
        continue;
      }

      final bullet = _bullet.firstMatch(line);
      final ordered = _ordered.firstMatch(line);
      if (bullet != null || ordered != null) {
        flushParagraph();
        final indent = (bullet?.group(1) ?? ordered!.group(1)!).length ~/ 2;
        final marker = bullet != null ? '•' : '${ordered!.group(2)}.';
        final text = bullet?.group(2) ?? ordered!.group(3)!;
        widgets.add(_listItem(marker, text, indent));
        i++;
        continue;
      }

      paragraph.add(trimmed);
      i++;
    }
    flushParagraph();
    return widgets;
  }

  pw.Widget _paragraph(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(text: pw.TextSpan(children: inlineSpans(text))),
    );
  }

  pw.Widget _headingBlock(int level, String text) {
    final size = switch (level) {
      1 => baseFontSize + 7,
      2 => baseFontSize + 5,
      3 => baseFontSize + 3,
      _ => baseFontSize + 1,
    };
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(font: fonts.bold, fontSize: size),
          children: inlineSpans(text, bold: true),
        ),
      ),
    );
  }

  pw.Widget _listItem(String marker, String text, int indent) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(left: 12.0 * indent, bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 16,
            child: pw.Text(marker, style: _style()),
          ),
          pw.Expanded(
            child: pw.RichText(text: pw.TextSpan(children: inlineSpans(text))),
          ),
        ],
      ),
    );
  }

  pw.Widget _quote(String text) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.only(left: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: _rule, width: 2)),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          style: _style(color: _muted),
          children: inlineSpans(text),
        ),
      ),
    );
  }

  pw.Widget _codeBlock(String code) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(6),
      decoration: const pw.BoxDecoration(
        color: _codeBackground,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        code,
        style: pw.TextStyle(
          font: fonts.mono,
          fontSize: baseFontSize - 1.5,
          fontFallback: fonts.fallback,
        ),
      ),
    );
  }

  pw.Widget _mathBlock(String latex) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Center(
        child: pw.Text(latexToText(latex), style: _style()),
      ),
    );
  }

  pw.Widget _table(List<List<String>> rows) {
    final columns = rows.fold<int>(0, (max, row) {
      return row.length > max ? row.length : max;
    });
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Table(
        border: pw.TableBorder.all(color: _rule, width: 0.5),
        children: [
          for (var r = 0; r < rows.length; r++)
            pw.TableRow(
              decoration: r == 0
                  ? const pw.BoxDecoration(color: _codeBackground)
                  : null,
              children: [
                for (var c = 0; c < columns; c++)
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        style: pw.TextStyle(fontSize: baseFontSize - 1),
                        children: inlineSpans(
                          c < rows[r].length ? rows[r][c] : '',
                          bold: r == 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  List<String> _tableCells(String line) {
    var content = line.trim();
    if (content.startsWith('|')) content = content.substring(1);
    if (content.endsWith('|')) {
      content = content.substring(0, content.length - 1);
    }
    return content.split('|').map((cell) => cell.trim()).toList();
  }

  pw.TextStyle _style({bool bold = false, PdfColor? color}) {
    return pw.TextStyle(
      font: bold ? fonts.bold : fonts.base,
      fontSize: baseFontSize,
      lineSpacing: 1.5,
      color: color,
      fontFallback: fonts.fallback,
    );
  }

  List<pw.InlineSpan> inlineSpans(String text, {bool bold = false}) {
    final spans = <pw.InlineSpan>[];
    var index = 0;
    for (final match in _inline.allMatches(text)) {
      if (match.start > index) {
        spans.add(pw.TextSpan(
          text: text.substring(index, match.start),
          style: _style(bold: bold),
        ));
      }
      spans.add(_inlineToken(match.group(0)!, bold));
      index = match.end;
    }
    if (index < text.length) {
      spans.add(
          pw.TextSpan(text: text.substring(index), style: _style(bold: bold)));
    }
    return spans;
  }

  pw.InlineSpan _inlineToken(String token, bool bold) {
    if (token.startsWith('**') || token.startsWith('__')) {
      return pw.TextSpan(
        text: token.substring(2, token.length - 2),
        style: _style(bold: true),
      );
    }
    if (token.startsWith('`')) {
      return pw.TextSpan(
        text: token.substring(1, token.length - 1),
        style: pw.TextStyle(
          font: fonts.mono,
          fontSize: baseFontSize - 1,
          background: const pw.BoxDecoration(color: _codeBackground),
          fontFallback: fonts.fallback,
        ),
      );
    }
    if (token.startsWith('[')) {
      final close = token.indexOf('](');
      final label = token.substring(1, close);
      final url = token.substring(close + 2, token.length - 1);
      return pw.WidgetSpan(
        child: pw.UrlLink(
          destination: url,
          child: pw.Text(
            label,
            style: _style(bold: bold, color: _link).copyWith(
              decoration: pw.TextDecoration.underline,
            ),
          ),
        ),
      );
    }
    if (token.startsWith(r'$')) {
      return pw.TextSpan(
        text: latexToText(token.substring(1, token.length - 1)),
        style: _style(bold: bold),
      );
    }
    if (token.startsWith(r'\(')) {
      return pw.TextSpan(
        text: latexToText(token.substring(2, token.length - 2)),
        style: _style(bold: bold),
      );
    }
    // *italic*: no italic face is bundled, so keep the text plain.
    return pw.TextSpan(
      text: token.substring(1, token.length - 1),
      style: _style(bold: bold),
    );
  }

  static const Map<String, String> _latexSymbols = {
    r'\alpha': 'α',
    r'\beta': 'β',
    r'\gamma': 'γ',
    r'\Gamma': 'Γ',
    r'\delta': 'δ',
    r'\Delta': 'Δ',
    r'\varepsilon': 'ε',
    r'\epsilon': 'ε',
    r'\eta': 'η',
    r'\theta': 'θ',
    r'\kappa': 'κ',
    r'\lambda': 'λ',
    r'\mu': 'μ',
    r'\nu': 'ν',
    r'\pi': 'π',
    r'\rho': 'ρ',
    r'\sigma': 'σ',
    r'\Sigma': 'Σ',
    r'\tau': 'τ',
    r'\phi': 'φ',
    r'\varphi': 'φ',
    r'\psi': 'ψ',
    r'\omega': 'ω',
    r'\Omega': 'Ω',
    r'\times': '×',
    r'\cdot': '·',
    r'\leq': '≤',
    r'\geq': '≥',
    r'\le': '≤',
    r'\ge': '≥',
    r'\neq': '≠',
    r'\approx': '≈',
    r'\pm': '±',
    r'\infty': '∞',
    r'\partial': '∂',
    r'\sum': '∑',
    r'\int': '∫',
    r'\sqrt': '√',
    r'\circ': '°',
    r'\degree': '°',
    r'\rightarrow': '→',
    r'\to': '→',
    r'\left': '',
    r'\right': '',
    r'\,': ' ',
    r'\;': ' ',
    r'\quad': '  ',
  };

  /// Makes LaTeX readable as plain text, e.g. `\sigma_{11} \le 2\times 10^3`
  /// becomes `σ_11 ≤ 2× 10^3`.
  static String latexToText(String latex) {
    var text = latex;
    // \frac{a}{b} -> (a)/(b), innermost first.
    final frac = RegExp(r'\\frac\{([^{}]*)\}\{([^{}]*)\}');
    while (frac.hasMatch(text)) {
      text = text.replaceAllMapped(frac, (m) => '(${m[1]})/(${m[2]})');
    }
    text = text.replaceAllMapped(
      RegExp(r'\\(?:text|mathrm|mathbf|operatorname)\{([^{}]*)\}'),
      (m) => m[1]!,
    );
    // The PDF renderer cannot position combining accents, so spell them
    // out the way engineers write them in plain text: \bar{Q} -> Qbar.
    const accents = {
      'bar': 'bar',
      'overline': 'bar',
      'hat': 'hat',
      'tilde': '~',
      'dot': 'dot',
      'vec': 'vec',
    };
    text = text.replaceAllMapped(
      RegExp(r'\\(bar|overline|hat|tilde|dot|vec)\{([^{}]*)\}'),
      (m) => '${m[2]}${accents[m[1]]}',
    );
    final keys = _latexSymbols.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in keys) {
      final pattern = RegExp('${RegExp.escape(key)}(?![A-Za-z])');
      text = text.replaceAll(pattern, _latexSymbols[key]!);
    }
    text = text.replaceAllMapped(
      RegExp(r'([_^])\{([^{}]*)\}'),
      (m) => '${m[1]}${m[2]}',
    );
    return text.replaceAll(RegExp(r'[{}]'), '').replaceAll(RegExp(r' {2,}'), ' ');
  }
}
