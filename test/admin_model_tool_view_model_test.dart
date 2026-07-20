import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/chat_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/settings/viewModels/admin_model_tool_view_model.dart';

class _FakeAdminChatUseCase extends Fake implements ChatUseCase {
  Map<String, dynamic>? updatedModelPayload;
  Object? updateModelError;

  @override
  Future<List<ChatModel>> fetchWorkspaceModels() async => <ChatModel>[];

  @override
  Future<List<ChatTool>> fetchToolList() async => <ChatTool>[];

  @override
  Future<ChatModel> updateModel(
    String id,
    Map<String, dynamic> model,
  ) async {
    final error = updateModelError;
    if (error != null) throw error;
    updatedModelPayload = model;
    return ChatModel.fromJson(model);
  }
}

void main() {
  group('AdminModelToolViewModel', () {
    test('saves tool assignments on the edited model', () async {
      final useCase = _FakeAdminChatUseCase();
      final viewModel = AdminModelToolViewModel(chatUseCase: useCase);
      final model = ChatModel(
        id: 'model-a',
        name: 'Model A',
        rawJson: const {'id': 'model-a'},
      );

      final saved = await viewModel.saveModel(
        existing: model,
        id: model.id,
        name: model.name,
        description: 'Composite model',
        isActive: true,
        toolIds: const ['tool-a', 'tool-b'],
      );

      expect(saved, isTrue);
      expect(
        (useCase.updatedModelPayload!['meta'] as Map)['toolIds'],
        ['tool-a', 'tool-b'],
      );
    });

    test('keeps the editor usable when a model update fails', () async {
      final useCase = _FakeAdminChatUseCase()
        ..updateModelError = StateError('update failed');
      final viewModel = AdminModelToolViewModel(chatUseCase: useCase);
      final model = ChatModel(
        id: 'model-a',
        name: 'Model A',
        rawJson: const {'id': 'model-a'},
      );

      final saved = await viewModel.saveModel(
        existing: model,
        id: model.id,
        name: model.name,
        description: '',
        isActive: true,
        toolIds: const [],
      );

      expect(saved, isFalse);
      expect(viewModel.isSaving, isFalse);
      expect(viewModel.error, contains('update failed'));
    });
  });

  test('ChatModel accepts top-level tool IDs from the API', () {
    final model = ChatModel.fromJson({
      'id': 'model-a',
      'name': 'Model A',
      'tool_ids': ['tool-a'],
    });

    expect(model.toolIds, ['tool-a']);
  });
}
