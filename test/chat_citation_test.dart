import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/chat/model/chat_citation.dart';
import 'package:swiftcomp/presentation/chat/views/ai_markdown_message.dart';
import 'package:swiftcomp/presentation/chat/views/chat_citation_widgets.dart';

void main() {
  group('ChatCitationParser', () {
    test('maps citation markers to explicit and tool-provided URLs', () {
      final citations = ChatCitationParser.parse(
        markdown:
            'NASA reports this result 【1†NASA Technical Reports】 and [2](https://example.com/paper).',
        statusHistory: const [
          ToolStatus(
            query: 'composite rotor blades',
            urls: [
              'https://ntrs.nasa.gov/citations/example',
              'https://example.com/paper',
            ],
          ),
        ],
      );

      expect(citations, hasLength(2));
      expect(citations[0].number, 1);
      expect(citations[0].displayTitle, 'NASA Technical Reports');
      expect(citations[0].uri?.host, 'ntrs.nasa.gov');
      expect(citations[1].number, 2);
      expect(citations[1].uri, Uri.parse('https://example.com/paper'));
      expect(citations[0].context, contains('composite rotor blades'));
    });

    test('normalizes supported citation formats without deleting markers', () {
      final normalized = ChatCitationParser.normalizeMarkdown(
        'First 【1†Journal】. Second 【https://example.com】[2]. '
        'Third [3](https://example.org).',
      );

      expect(normalized, 'First [1]. Second [2]. Third [3].');
    });

    test('rejects unsafe citation schemes', () {
      final citations = ChatCitationParser.parse(
        markdown: 'Unsafe source [1].',
        statusHistory: const [
          ToolStatus(urls: ['javascript:alert(1)', 'file:///private/document']),
        ],
      );

      expect(citations, hasLength(1));
      expect(citations.single.canOpen, false);
    });
  });

  testWidgets('tapping an inline citation shows source information',
      (tester) async {
    final citation = ChatCitation(
      number: 1,
      label: 'NASA Technical Reports',
      context: 'Referenced while researching rotor blade analysis.',
      uri: Uri.parse('https://ntrs.nasa.gov/citations/example'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiMarkdownMessage(
            markdown: 'A referenced result [1].',
            citations: [citation],
          ),
        ),
      ),
    );

    expect(find.byType(ChatCitationBadge), findsOneWidget);
    await tester.tap(find.byType(ChatCitationBadge));
    await tester.pumpAndSettle();

    expect(find.text('NASA Technical Reports'), findsOneWidget);
    expect(
      find.text('https://ntrs.nasa.gov/citations/example'),
      findsOneWidget,
    );
    expect(find.text('Open source'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
  });
}
