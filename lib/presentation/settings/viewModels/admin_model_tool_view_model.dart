import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/chat_tool.dart';
import 'package:flutter/foundation.dart';

class AdminModelToolViewModel extends ChangeNotifier {
  final ChatUseCase chatUseCase;

  AdminModelToolViewModel({required this.chatUseCase});

  List<ChatModel> models = [];
  List<ChatTool> tools = [];
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> load() => loadModelsAndTools();

  Future<void> loadModelsAndTools() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        chatUseCase.fetchWorkspaceModels(),
        chatUseCase.fetchToolList(),
      ]);
      models = results[0] as List<ChatModel>;
      tools = results[1] as List<ChatTool>;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTools() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      tools = await chatUseCase.fetchToolList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveModel({
    ChatModel? existing,
    required String id,
    required String name,
    String? baseModelId,
    required String description,
    required bool isActive,
    required List<String> toolIds,
  }) async {
    return _saving(() async {
      final payload =
          (existing ?? ChatModel.fallback(id: id, name: name)).toAdminJson(
        id: id,
        name: name,
        baseModelId: baseModelId,
        description: description,
        isActive: isActive,
        toolIds: toolIds,
      );

      if (existing == null) {
        await chatUseCase.createModel(payload);
      } else {
        await chatUseCase.updateModel(existing.id, payload);
      }
      await loadModelsAndTools();
    });
  }

  Future<bool> toggleModel(ChatModel model) async {
    return _saving(() async {
      await chatUseCase.toggleModel(model.id);
      await loadModelsAndTools();
    });
  }

  Future<bool> deleteModel(ChatModel model) async {
    return _saving(() async {
      await chatUseCase.deleteModel(model.id);
      await loadModelsAndTools();
    });
  }

  Future<bool> saveTool({
    ChatTool? existing,
    required String id,
    required String name,
    required String description,
    required String content,
  }) async {
    return _saving(() async {
      final payload = (existing ?? ChatTool(id: id, name: name)).toAdminJson(
        id: id,
        name: name,
        description: description,
        content: content,
      );

      if (existing == null) {
        await chatUseCase.createTool(payload);
      } else {
        await chatUseCase.updateTool(existing.id, payload);
      }
      await loadTools();
    });
  }

  Future<bool> deleteTool(ChatTool tool) async {
    return _saving(() async {
      await chatUseCase.deleteTool(tool.id);
      await loadTools();
    });
  }

  Future<bool> _saving(Future<void> Function() action) async {
    isSaving = true;
    error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
