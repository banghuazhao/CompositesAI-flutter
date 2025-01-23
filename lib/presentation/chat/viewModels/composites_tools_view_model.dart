



import 'dart:typed_data';

import 'package:domain/entities/user.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:domain/usecases/chat_session_usecase.dart';
import 'package:domain/usecases/chat_usecase.dart';
import 'package:domain/usecases/function_tools_usecase.dart';
import 'package:domain/usecases/user_usercase.dart';
import 'package:flutter/cupertino.dart';
import 'package:domain/usecases/composites_tools_usecase.dart';
import 'dart:io';

class CompositesToolsViewModel extends ChangeNotifier {
final CompositesToolsUseCase toolUseCase;

CompositesToolsViewModel({required this.toolUseCase});

  bool isLoggedIn = false;
  User? user;

  bool isLoading = false;

Future<String> createCompositeTool(
    String title,
    dynamic file, // Accept both File and Uint8List
    String? desiredFileName,
    String? description,
    String? instructions
    ) async {
  String statusMessage;

  if (file is File) {
    // Handle the File case (desktop/mobile)
    statusMessage = await toolUseCase.createAiTool(title, file, description, instructions);
  } else if (file is Uint8List) {
    // Handle the Uint8List case (web)
    statusMessage = await toolUseCase.createAiToolFromBytes(title, file, desiredFileName, description, instructions);
  } else {
    throw ArgumentError('Unsupported file type. Must be File or Uint8List.');
  }

  return statusMessage;
}


}