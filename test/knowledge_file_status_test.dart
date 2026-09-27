import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat_knowledge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/chat/controllers/chat_attachment_controller.dart';

class _FakeChatUseCase extends Fake implements ChatUseCase {
  List<ChatKnowledge> bases = [];

  @override
  Future<List<ChatKnowledge>> fetchKnowledgeBases() async => bases;
}

void main() {
  test(
    'knowledge file status and processing error come from backend metadata',
    () {
      final knowledge = ChatKnowledge.fromJson({
        'id': 'base-1',
        'name': 'Materials',
        'files': [
          {
            'id': 'queued-1',
            'meta': {'name': 'Queued.pdf', 'processing_status': 'queued'},
          },
          {
            'id': 'failed-1',
            'meta': {
              'name': 'Failed.pdf',
              'processing_status': 'failed',
              'processing_error': 'Page limit exceeded',
            },
          },
          {
            'id': 'ready-1',
            'meta': {'name': 'Ready.pdf', 'processing_status': 'completed'},
          },
          {
            'id': 'legacy-1',
            'meta': {'name': 'Legacy.pdf'},
          },
        ],
      });

      expect(knowledge.files[0].isProcessing, isTrue);
      expect(knowledge.files[0].isSelectableKnowledgeFile, isFalse);
      expect(knowledge.files[1].hasProcessingFailed, isTrue);
      expect(knowledge.files[1].processingError, 'Page limit exceeded');
      expect(knowledge.files[1].isSelectableKnowledgeFile, isFalse);
      expect(knowledge.files[2].isSelectableKnowledgeFile, isTrue);
      expect(knowledge.files[3].isSelectableKnowledgeFile, isTrue);
    },
  );

  test('refresh clears a selected document that later fails processing',
      () async {
    final useCase = _FakeChatUseCase();
    final controller = ChatAttachmentController(
      chatUseCase: useCase,
      canUseChat: () => true,
      onError: (_, {retry}) {},
    );
    addTearDown(controller.dispose);

    ChatKnowledge baseWithStatus(String status) => ChatKnowledge.fromJson({
          'id': 'base-1',
          'files': [
            {
              'id': 'document-1',
              'meta': {'name': 'Materials.pdf', 'processing_status': status},
            },
          ],
        });

    useCase.bases = [baseWithStatus('completed')];
    await controller.fetchKnowledgeBases();
    controller
        .toggleKnowledgeFile(controller.knowledgeBases.single.files.single);
    expect(controller.pendingFiles, hasLength(1));

    useCase.bases = [baseWithStatus('failed')];
    await controller.fetchKnowledgeBases();
    expect(controller.pendingFiles, isEmpty);
    controller
        .toggleKnowledgeFile(controller.knowledgeBases.single.files.single);
    expect(controller.pendingFiles, isEmpty);
  });
}
