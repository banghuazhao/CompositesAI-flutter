

import 'dart:io';
import 'dart:typed_data';

import '../repositories_abstract/composites_tools_repository.dart';

abstract class CompositesToolsUseCase {
  Future<String> createAiTool(String title, File pyFile, String? description, String? instructions);

  Future<String> createAiToolFromBytes(String title, Uint8List file, String? desiredFileName, String? description, String? instructions);
}

class CompositesToolsUseCaseImpl implements CompositesToolsUseCase {
  final CompositesToolsRepository repository;

  CompositesToolsUseCaseImpl({required this.repository});
  @override
  Future<String> createAiTool(String title, File pyFile, String? description, String? instructions) async {
    return await repository.createCompositesTool(title, pyFile, description, instructions);
  }


  @override
  Future<String> createAiToolFromBytes(String title, Uint8List bytes, String? desiredFileName, String? description, String? instructions) async {
    return await repository.createAiToolFromBytes(title, bytes, desiredFileName, description, instructions);
  }


}