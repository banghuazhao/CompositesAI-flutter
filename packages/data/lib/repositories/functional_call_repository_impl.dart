import 'dart:convert';
import 'dart:io';

import 'package:domain/entities/chat/function_tool.dart';
import 'package:domain/entities/chat/function_tool_output.dart';
import 'package:domain/repositories_abstract/functional_call_repository.dart';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';

class FunctionalCallRepositoryImpl implements FunctionalCallRepository {
  @override
  Future<FunctionToolOutput> callFunctionTool(FunctionTool tool) async {
    String functionToolEndPoint = tool.name.replaceAll("_", "-");
    print("tool.arguments: ${tool.arguments}");
    final request = http.Request(
        'POST', Uri.parse("${ApiConstants.functionCallEndpoint}/$functionToolEndPoint"))
      ..headers.addAll({
        'Content-Type': 'application/json'
      })
      ..body = tool.arguments;

    final http.StreamedResponse streamedResponse = await http.Client().send(request);
    final String responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      print("responseBody: $responseBody");
      return FunctionToolOutput(callId: tool.callId, output: responseBody);
    } else {
      throw HttpException(
        'Failed to call function tool $functionToolEndPoint.'
            'Status: ${streamedResponse.statusCode}, '
            'Response: $responseBody',
        uri: request.url,
      );
    }
  }
}