import 'dart:typed_data';

import 'package:domain/chat/entities/message.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../util/export/markdown_pdf.dart';
import '../../../util/export/pdf_fonts.dart';
import 'chat_citation.dart';

/// Builds shareable Markdown and PDF versions of a conversation.
class ChatExport {
  const ChatExport._();

  static const String _assistantName = 'CompositesAI';

  static List<Message> _visibleMessages(List<Message> messages) {
    return messages
        .where((message) =>
            (message.role == 'user' || message.role == 'assistant') &&
            ChatCitationParser.normalizeMarkdown(message.content)
                .trim()
                .isNotEmpty)
        .toList(growable: false);
  }

  static String _speaker(Message message) {
    if (message.role == 'user') return 'You';
    final model = message.modelName.trim();
    return model.isEmpty ? _assistantName : '$_assistantName · $model';
  }

  static String _dateLine(DateTime exportedAt) =>
      'Exported from CompositesAI on '
      '${DateFormat('yyyy-MM-dd HH:mm').format(exportedAt)}';

  static List<ChatCitation> _citations(Message message) {
    if (message.role != 'assistant') return const [];
    return ChatCitationParser.parse(
      markdown: message.content,
      statusHistory: message.statusHistory,
      sources: message.sources,
    )
        .where((citation) =>
            citation.uri != null ||
            (citation.label?.trim().isNotEmpty ?? false) ||
            (citation.bibliographicText?.trim().isNotEmpty ?? false))
        .toList(growable: false);
  }

  static String _citationLine(ChatCitation citation) {
    final url = citation.uri?.toString();
    final title = citation.displayTitle;
    if (url == null || url == title) return '[${citation.number}] $title';
    return '[${citation.number}] $title — $url';
  }

  static String toMarkdown({
    required String title,
    required List<Message> messages,
    DateTime? exportedAt,
  }) {
    final buffer = StringBuffer()
      ..writeln('# ${title.trim().isEmpty ? 'Conversation' : title.trim()}')
      ..writeln()
      ..writeln('_${_dateLine(exportedAt ?? DateTime.now())}_');

    for (final message in _visibleMessages(messages)) {
      buffer
        ..writeln()
        ..writeln('---')
        ..writeln()
        ..writeln('### ${_speaker(message)}')
        ..writeln()
        ..writeln(ChatCitationParser.normalizeMarkdown(message.content).trim());

      final attachments = message.files.map((file) => file.name).toList();
      if (attachments.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('_Attachments: ${attachments.join(', ')}_');
      }

      final citations = _citations(message);
      if (citations.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('**Sources**')
          ..writeln();
        for (final citation in citations) {
          buffer.writeln('- ${_citationLine(citation)}');
        }
      }
    }
    return buffer.toString();
  }

  static Future<Uint8List> toPdf({
    required String title,
    required List<Message> messages,
    DateTime? exportedAt,
  }) async {
    final visible = _visibleMessages(messages);
    final fonts = await PdfFonts.load(
      sampleText: [title, ...visible.map((m) => m.content)].join('\n'),
    );
    final markdown = MarkdownPdf(fonts);
    final heading = title.trim().isEmpty ? 'Conversation' : title.trim();

    final document = pw.Document(
      title: heading,
      author: _assistantName,
      creator: _assistantName,
      theme: fonts.theme,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 40),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              _assistantName,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          pw.Text(
            heading,
            style: pw.TextStyle(font: fonts.bold, fontSize: 18),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _dateLine(exportedAt ?? DateTime.now()),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 12),
          for (final message in visible) ..._messageWidgets(message, markdown),
        ],
      ),
    );
    return document.save();
  }

  static List<pw.Widget> _messageWidgets(
    Message message,
    MarkdownPdf markdown,
  ) {
    final isUser = message.role == 'user';
    final citations = _citations(message);
    final content = ChatCitationParser.normalizeMarkdown(message.content).trim();
    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
        padding: const pw.EdgeInsets.only(bottom: 2),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        child: pw.Text(
          _speaker(message),
          style: pw.TextStyle(
            font: markdown.fonts.bold,
            fontSize: 10,
            color: isUser ? PdfColors.blueGrey700 : PdfColors.teal800,
          ),
        ),
      ),
      if (isUser)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          margin: const pw.EdgeInsets.only(bottom: 4),
          decoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey50,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(content),
        )
      else
        ...markdown.build(content),
      if (message.files.isNotEmpty)
        pw.Text(
          'Attachments: ${message.files.map((file) => file.name).join(', ')}',
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
        ),
      if (citations.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        pw.Text(
          'Sources',
          style: pw.TextStyle(font: markdown.fonts.bold, fontSize: 9),
        ),
        for (final citation in citations)
          pw.Text(
            _citationLine(citation),
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
      ],
    ];
  }
}
