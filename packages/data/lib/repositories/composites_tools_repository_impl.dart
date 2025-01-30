import 'dart:io';
import 'dart:typed_data';

import 'package:domain/repositories_abstract/composites_tools_repository.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:domain/entities/tool_creation_requests.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../mappers/domain_exception_mapper.dart';

class CompositesToolsRepositoryImpl implements CompositesToolsRepository {
  final AuthenticatedHttpClient authClient;
  final APIEnvironment apiEnvironment;

  CompositesToolsRepositoryImpl({required this.authClient, required this.apiEnvironment});

  @override
  Future<String> createCompositesTool(String title, File pyFile, String? description, String? instructions) async {
    final baseURL = await apiEnvironment.getBaseUrl();

    // Create a MultipartRequest
    final uri = Uri.parse('$baseURL/compositestools/create-tool');
    final request = http.MultipartRequest('POST', uri);

    // Add text fields
    print('Title: $title');

    request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    if (instructions != null) request.fields['instructions'] = instructions;

    // Add the file
    request.files.add(await http.MultipartFile.fromPath('file', pyFile.path));

    // Use authClient to send the request
    final streamedResponse = await authClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    // Handle the response
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['message']; // Success message
    } else {
      throw Exception('Failed to create tool: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Future<String> createAiToolFromBytes(
      String title,
      Uint8List bytes,
      String? desiredFileName,
      String? description,
      String? instructions,
      ) async {
    try {
      // Get the base URL
      final baseURL = await apiEnvironment.getBaseUrl();

      // Create the multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseURL/compositestools/create-tool-web'),
      );

      // Add fields
      print('Title: $title');
      request.fields['title'] = title;
      if (description != null) {
        request.fields['description'] = description;
      }
      if (instructions != null) {
        request.fields['instructions'] = instructions;
      }

      // Add the file bytes
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: desiredFileName, // Use the variable for the file name
      ));

      // Send the request using authClient
      final streamedResponse = await authClient.send(request);

      // Parse the response
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final responseData = json.decode(responseBody);
        return responseData['message'] ??
            "Tool creation request has been sent successfully. Please wait for approval.";
      } else if (streamedResponse.statusCode == 401) {
        // Decode the response body to determine the specific issue
        final errorDetails = json.decode(responseBody);
        final errorMessage = errorDetails['message'] ?? "Authorization failed.";

        if (errorMessage.contains("Unauthorized")) {
          return "Authorization failed. Please ensure you are logged in with a valid account.";
        } else if (errorMessage.contains("You need to be a composite expert")) {
          return "You need to be a composite expert to create a tool. Please apply to become one.";
        } else {
          return "Authorization error: $errorMessage";
        }
      } else if (streamedResponse.statusCode == 400) {
        // Handle bad request errors by decoding the server response
        final errorDetails = json.decode(responseBody);
        final errorMessage = errorDetails['message'] ?? "Invalid request. Please check your input fields.";
        return "Error: $errorMessage";
      } else if (streamedResponse.statusCode == 500) {
        return "An internal server error occurred. Please try again later.";
      } else {
        // Generic error message for unknown status codes
        return "An error occurred (status code: ${streamedResponse.statusCode}). Please try again.";
      }
    } catch (e) {
      // Catch unexpected errors and provide a user-friendly message
      return "An unexpected error occurred: $e. Please try again.";
    }
  }

  @override
  Future<List<ToolCreationRequest>> getAllRequests() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final response = await authClient.get(
      Uri.parse('$baseURL/compositestools/tool-requests'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final requests = data.map((json) => ToolCreationRequest.fromJson(json)).toList();
      return requests;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }
  
  @override
  Future<String> approveRequest(int id) async {
    try {
      final baseURL = await apiEnvironment.getBaseUrl(); // Ensure this is non-null
      final response = await authClient.patch(
        Uri.parse('$baseURL/compositestools/tool-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      // Check the response status code
      if (response.statusCode == 200) {
        return "Request approved successfully";
      } else {
        // Log and throw a meaningful exception with response details
        print("Failed to approve the request: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to approve the request: ${response.statusCode}");
      }
    } catch (e) {
      // Handle and rethrow the error with additional context
      print("Error in approveRequest: $e");
      throw Exception("An error occurred while approving the request. Please try again.");
    }
  }

  @override
  Future<List<ToolCreationRequest>> getAllTools() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final response = await authClient.get(
      Uri.parse('$baseURL/compositestools/tools'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final tools = data.map((json) => ToolCreationRequest.fromJson(json)).toList();
      return tools;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<String> deleteRequest(int id) async {
    try {
      final baseURL = await apiEnvironment.getBaseUrl(); // Ensure this is non-null
      final response = await authClient.delete(
        Uri.parse('$baseURL/compositestools/tool-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      // Check the response status code
      if (response.statusCode == 200) {
        return "Request deleted successfully";
      } else {
        // Log and throw a meaningful exception with response details
        print("Failed to delete the request: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to delete the request: ${response.statusCode}");
      }
    } catch (e) {
      // Handle and rethrow the error with additional context
      print("Error in delete request: $e");
      throw Exception("An error occurred while deleting the request. Please try again.");
    }
  }

}



