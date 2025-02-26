import 'dart:typed_data';

import 'package:domain/entities/tool_creation_requests.dart';
import 'package:domain/entities/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:domain/use_cases/composites_tools_use_case.dart';
import 'dart:io';

class CompositesToolsViewModel extends ChangeNotifier {
  final CompositesToolsUseCase toolUseCase;
  final User user;
  List<ToolCreationRequest> requests = [];

  CompositesToolsViewModel({required this.toolUseCase, required this.user});

  bool isLoggedIn = false;
  bool isLoading = false;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<String> createCompositeTool(
      String title,
      dynamic file, // Accept both File and Uint8List
      String? desiredFileName,
      String? description,
      String? instructions) async {
    String statusMessage;

    if (file is File) {
      // Handle the File case (desktop/mobile)
      statusMessage = await toolUseCase.createAiTool(
          title, file, description, instructions);
    } else if (file is Uint8List) {
      // Handle the Uint8List case (web)
      statusMessage = await toolUseCase.createAiToolFromBytes(
          title, file, desiredFileName, description, instructions);
    } else {
      throw ArgumentError('Unsupported file type. Must be File or Uint8List.');
    }

    return statusMessage;
  }

  Future<List<ToolCreationRequest>> getAllRequests() async {
    _setLoading(true);
    try {
      // Try to fetch the requests
      requests = await toolUseCase.getAllRequests();
      return requests; // Return the fetched requests
    } catch (e) {
      // In case of error, return an empty list
      requests = [];
      _errorMessage = "Failed to fetch applications: $e";
      print(_errorMessage);
      return requests; // Ensure a return value
    } finally {
      // Ensure the loading state is updated regardless of success or error
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> approveRequest(int id) async {
    try {
      // First step: Make user an expert
      await toolUseCase.approveRequest(id);
      notifyListeners();
    } catch (e) {
      print("Error in approve request: $e");
      throw Exception("Failed to approve the request with ID: $id.");
    }
  }

  Future<void> deleteRequest(int id) async {
    try {
      await toolUseCase.deleteRequest(id);
      notifyListeners();
    } catch (e) {
      print("Error in delete request: $e");
      throw Exception("Failed to delete the request with ID: $id.");
    }
  }
}
