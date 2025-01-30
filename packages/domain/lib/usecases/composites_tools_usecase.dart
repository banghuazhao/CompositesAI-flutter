

import 'dart:io';
import 'dart:typed_data';

import 'package:infrastructure/token_provider.dart';

import '../entities/tool_creation_requests.dart';
import '../repositories_abstract/composites_tools_repository.dart';

abstract class CompositesToolsUseCase {
  Future<String> createAiTool(String title, File pyFile, String? description, String? instructions);

  Future<String> createAiToolFromBytes(String title, Uint8List file, String? desiredFileName, String? description, String? instructions);
  Future<List<ToolCreationRequest>> getAllRequests();
  Future<String> approveRequest(int id);
  Future<List<ToolCreationRequest>> getAllTools();
  Future<String> deleteRequest(int id);
}

class CompositesToolsUseCaseImpl implements CompositesToolsUseCase {
  final CompositesToolsRepository repository;
  final TokenProvider tokenProvider;

  CompositesToolsUseCaseImpl({required this.repository, required this.tokenProvider});
  @override
  Future<String> createAiTool(String title, File pyFile, String? description, String? instructions) async {
    return await repository.createCompositesTool(title, pyFile, description, instructions);
  }


  @override
  Future<String> createAiToolFromBytes(String title, Uint8List bytes, String? desiredFileName, String? description, String? instructions) async {
    return await repository.createAiToolFromBytes(title, bytes, desiredFileName, description, instructions);
  }
  Future<List<ToolCreationRequest>> getAllRequests() async {
    return await repository.getAllRequests();
  }

  Future<String> approveRequest(int id) async {
    return await repository.approveRequest(id);
  }

  Future<List<ToolCreationRequest>> getAllTools() async {
    return await repository.getAllTools();
  }

  Future<String> deleteRequest(int id) async {
    return await repository.deleteRequest(id);
  }

}