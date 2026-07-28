import 'package:domain/chat/entities/chat_source.dart';
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

    test('maps citation markers to message source URLs by citation_id', () {
      final citations = ChatCitationParser.parse(
        markdown: 'Laminate stiffness is orthotropic [1] and [2].',
        sources: [
          ChatSource.fromJson({
            'citation_id': 1,
            'source': {'name': 'NASA Technical Reports'},
            'metadata': [
              {
                'name': 'NASA Technical Reports',
                'source': 'https://ntrs.nasa.gov/citations/example',
                'citation_id': 1,
                'bibliographic': {
                  'author_full_name': 'Wenbin Yu',
                  'title':
                      'Inertial and elastic properties of general composite beams',
                  'journal': 'Composite Structures',
                  'publisher': 'Elsevier',
                  'publication_year': '2025',
                  'doi': '10.1016/j.compstruct.2024.118690',
                },
              },
            ],
            'document': [
              'Composite rotor blades exhibit orthotropic stiffness...',
            ],
          }),
          ChatSource.fromJson({
            'citation_id': 2,
            'source': {
              'name': 'Example Paper',
              'url': 'https://example.com/paper',
            },
            'metadata': [
              {'name': 'Example Paper', 'citation_id': 2},
            ],
          }),
        ],
      );

      expect(citations, hasLength(2));
      expect(citations[0].uri?.host, 'ntrs.nasa.gov');
      expect(citations[0].displayTitle, 'NASA Technical Reports');
      expect(citations[0].bibliographicText, contains('Wenbin Yu'));
      expect(citations[0].bibliographicText, contains('Elsevier'));
      expect(
        citations[0].bibliographicText,
        contains('https://doi.org/10.1016/j.compstruct.2024.118690'),
      );
      expect(
        citations[0].excerpts.single,
        contains('Composite rotor blades exhibit'),
      );
      expect(citations[1].uri, Uri.parse('https://example.com/paper'));
      expect(citations[1].displayTitle, 'Example Paper');
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

    test('fills paper names by citation_id and positional fallback', () {
      final citations = ChatCitationParser.parse(
        markdown: 'See [10] and [3].',
        sources: [
          ChatSource.fromJson({
            'citation_id': 3,
            'source': {'name': 'Classical%20Lamination%20Theory.pdf'},
            'document': ['CLT assumes each ply is orthotropic...'],
          }),
          ChatSource.fromJson({
            'source': {
              'name': 'Inertial and elastic properties of general composite beams',
            },
            'metadata': [
              {
                'bibliographic': {
                  'author_full_name': 'Wenbin Yu',
                  'title':
                      'Inertial and elastic properties of general composite beams',
                  'journal': 'Composite Structures',
                  'publication_year': '2025',
                },
              },
            ],
            'document': ['Beam properties depend on the cross section...'],
          }),
        ],
      );

      final byNumber = {
        for (final citation in citations) citation.number: citation,
      };

      expect(byNumber[3]?.displayTitle, 'Classical Lamination Theory.pdf');
      expect(
        byNumber[3]?.bibliographicText,
        contains('Classical Lamination Theory.pdf'),
      );
      expect(byNumber[10]?.displayTitle, contains('Inertial and elastic'));
      expect(byNumber[10]?.bibliographicText, contains('Wenbin Yu'));
      expect(byNumber[10]?.bibliographicText, contains('Composite Structures'));
    });
  });

  testWidgets('tapping an inline citation shows the source card',
      (tester) async {
    final citation = ChatCitation(
      number: 5,
      label: 'Composite Structures',
      bibliographicText:
          'Wenbin Yu. Inertial and elastic properties of general composite beams. '
          'Composite Structures, Elsevier, 2025. '
          'https://doi.org/10.1016/j.compstruct.2024.118690.',
      excerpts: const [
        'Materials, by their nature, are anisotropic...',
      ],
      uri: Uri.parse('https://doi.org/10.1016/j.compstruct.2024.118690'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiMarkdownMessage(
            markdown: 'A referenced result [5].',
            citations: [citation],
          ),
        ),
      ),
    );

    expect(find.byType(ChatCitationBadge), findsOneWidget);
    await tester.tap(find.byType(ChatCitationBadge));
    await tester.pumpAndSettle();

    expect(find.text('Source [5]'), findsOneWidget);
    expect(find.text('CITATION'), findsOneWidget);
    expect(find.text('EXCERPT 1'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.textContaining('Wenbin Yu'), findsOneWidget);
    expect(
      find.textContaining('Materials, by their nature, are anisotropic'),
      findsOneWidget,
    );
    expect(find.text('Open source'), findsOneWidget);
  });
}
