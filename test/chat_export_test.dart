import 'dart:convert';

import 'package:domain/chat/entities/chat_source.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/chat/model/chat_export.dart';
import 'package:swiftcomp/util/export/file_share.dart';
import 'package:swiftcomp/util/export/markdown_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final exportedAt = DateTime(2026, 9, 24, 10, 30);

  List<Message> conversation() {
    final question = Message(role: 'user', content: 'What is E1 for T300?');
    final answer = Message(
      role: 'assistant',
      content: '## Result\n\nUse the rule of mixtures [1]:\n\n'
          r'$$E_1 = V_f E_f + (1 - V_f) E_m$$'
          '\n\n| Property | Value |\n|---|---|\n| E1 | 135 GPa |\n\n'
          '- **Fiber**: T300\n- `Vf` = 0.6\n\n```\ncode block\n```',
      sources: [
        const ChatSource(
          citationId: 1,
          name: 'Composite handbook',
          url: 'https://example.com/handbook',
        ),
      ],
    )..modelName = 'CompositesAI Pro';
    final empty = Message(role: 'assistant');
    return [question, answer, empty];
  }

  test('markdown export includes speakers, content and sources', () {
    final markdown = ChatExport.toMarkdown(
      title: 'T300 stiffness',
      messages: conversation(),
      exportedAt: exportedAt,
    );

    expect(markdown, startsWith('# T300 stiffness\n'));
    expect(markdown, contains('Exported from CompositesAI on 2026-09-24 10:30'));
    expect(markdown, contains('### You\n\nWhat is E1 for T300?'));
    expect(markdown, contains('### CompositesAI · CompositesAI Pro'));
    expect(markdown, contains('| E1 | 135 GPa |'));
    expect(markdown, contains('**Sources**'));
    expect(
      markdown,
      contains('[1] Composite handbook — https://example.com/handbook'),
    );
    // Empty assistant placeholders are not exported.
    expect('### CompositesAI'.allMatches(markdown), hasLength(1));
  });

  test('pdf export produces a PDF document', () async {
    final bytes = await ChatExport.toPdf(
      title: 'T300 stiffness σ₁₁',
      messages: conversation(),
      exportedAt: exportedAt,
    );

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('latexToText renders common symbols readably', () {
    expect(
      MarkdownPdf.latexToText(r'\sigma_{11} \le \frac{F}{A}'),
      'σ_11 ≤ (F)/(A)',
    );
    expect(MarkdownPdf.latexToText(r'\left(\varepsilon\right)'), '(ε)');
    expect(MarkdownPdf.latexToText(r'\text{MPa}'), 'MPa');
    expect(MarkdownPdf.latexToText(r'\bar{Q}_{ij}'), 'Qbar_ij');
  });

  test('safeFileName strips path characters', () {
    expect(FileShare.safeFileName('a/b: c?', 'md'), 'ab_c.md');
    expect(FileShare.safeFileName('   ', 'pdf'), 'CompositesAI.pdf');
  });
}
