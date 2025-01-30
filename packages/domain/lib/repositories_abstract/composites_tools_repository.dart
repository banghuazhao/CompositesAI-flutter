import 'dart:io';
import 'dart:typed_data';

import '../entities/tool_creation_requests.dart';
import '../entities/user.dart';

abstract class CompositesToolsRepository {
  Future<String> createCompositesTool(String title, File pyFile, String? description, String? instructions);
  Future<String> createAiToolFromBytes(String title, Uint8List bytes, String? desiredFileName, String? description, String? instructions);
  Future<List<ToolCreationRequest>> getAllRequests();
  Future<String> approveRequest(int id);
  Future<List<ToolCreationRequest>> getAllTools();
  Future<String> deleteRequest(int id);
}
