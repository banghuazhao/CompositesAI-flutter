import 'dart:convert';
import 'dart:typed_data';

import 'package:data/chat/chat_repository_imp.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/knowledge_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/token_provider.dart';
import 'package:swiftcomp/presentation/chat/views/knowledge_document_page.dart';

class _TestEnvironment extends APIEnvironment {
  @override
  Future<String> getBaseUrl() async => 'https://example.test/api/v1';
}

class _TestTokenProvider extends TokenProvider {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _ReaderUseCase extends Fake implements ChatUseCase {
  _ReaderUseCase({this.content = 'Current material data'});

  final String content;
  final List<String> requestedImages = [];

  @override
  Future<KnowledgeDocument> fetchKnowledgeDocument(String fileId) async =>
      KnowledgeDocument(
        content: content,
        freshness: 'fresh',
        versions: [KnowledgeDocumentVersion(version: 1, kind: 'edited')],
      );

  @override
  Future<String> fetchKnowledgeDocumentVersion(
          String fileId, int version) async =>
      'Previous material data';

  @override
  Future<Uint8List> fetchKnowledgeDocumentImage(
      String fileId, String name) async {
    requestedImages.add(name);
    return Uint8List(0);
  }
}

void main() {
  test('document reader uses authenticated GET endpoints', () async {
    final requests = <http.Request>[];
    final token = _TestTokenProvider();
    final client = AuthenticatedHttpClient(
      MockClient((request) async {
        requests.add(request);
        switch (request.url.path) {
          case '/api/v1/files/file-1/markdown':
            return http.Response(
              jsonEncode({
                'content': 'Current text',
                'freshness': 'stale',
                'versions': {
                  'versions': [
                    {'version': 2, 'kind': 'edited', 'note': 'Correction'}
                  ]
                },
              }),
              200,
            );
          case '/api/v1/files/file-1/versions/2':
            return http.Response(jsonEncode({'content': 'Older text'}), 200);
          case '/api/v1/files/file-1/images/figure-1.png':
            return http.Response.bytes([1, 2, 3], 200);
        }
        return http.Response('Not found', 404);
      }),
      token,
    );
    final repository = ChatRepositoryImpl(
      authClient: client,
      apiEnvironment: _TestEnvironment(),
      tokenProvider: token,
    );

    final document = await repository.fetchKnowledgeDocument('file-1');
    expect(document.content, 'Current text');
    expect(document.freshness, 'stale');
    expect(document.versions.single.version, 2);
    expect(document.versions.single.note, 'Correction');
    expect(await repository.fetchKnowledgeDocumentVersion('file-1', 2),
        'Older text');
    expect(
      await repository.fetchKnowledgeDocumentImage('file-1', 'figure-1.png'),
      [1, 2, 3],
    );
    expect(requests, hasLength(3));
    expect(requests.every((request) => request.method == 'GET'), isTrue);
    expect(
      requests.every(
          (request) => request.headers['Authorization'] == 'Bearer test-token'),
      isTrue,
    );
    await expectLater(
      repository.fetchKnowledgeDocumentImage('file-1', '../secret'),
      throwsArgumentError,
    );
  });

  testWidgets('reader can inspect an archived version and return to current',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: KnowledgeDocumentPage(
        file: const ChatFile(id: 'file-1', name: 'Materials.md', url: ''),
        useCase: _ReaderUseCase(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Current material data'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Version 1'));
    await tester.pumpAndSettle();
    expect(find.text('Previous material data'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current version'));
    await tester.pumpAndSettle();
    expect(find.text('Current material data'), findsOneWidget);
  });

  testWidgets('preview requests only document images', (tester) async {
    final useCase = _ReaderUseCase(
      content: '![Remote](https://other.example/image.png)\n\n'
          '![Figure](images/figure-1.png)',
    );
    await tester.pumpWidget(MaterialApp(
      home: KnowledgeDocumentPage(
        file: const ChatFile(id: 'file-1', name: 'Materials.md', url: ''),
        useCase: useCase,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Preview Markdown'));
    await tester.pumpAndSettle();
    expect(useCase.requestedImages, ['figure-1.png']);
  });
}
