import 'dart:io';
import 'dart:typed_data';

import '../entities/user.dart';

abstract class CompositesToolsRepository {
  Future<String> createCompositesTool(String title, File pyFile, String? description, String? instructions);
  Future<String> createAiToolFromBytes(String title, Uint8List bytes, String? desiredFileName, String? description, String? instructions);
}
