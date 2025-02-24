import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:domain/entities/message.dart';
import 'package:domain/entities/thread.dart';
import 'package:domain/entities/thread_function_tool.dart';
import 'package:domain/entities/thread_response.dart';
import 'package:domain/entities/thread_run.dart';
import 'package:domain/entities/thread_tool_output.dart';
import 'package:domain/repositories_abstract/thread_runs_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../utils/sse_stream.dart'
    if (dart.library.js) '../utils/sse_stream_web.dart';

import '../utils/api_constants.dart';
import '../models/message_delta.dart';

enum ThreadResponseEvent {
  initial,
  threadCreated,
  threadRunCreated,
  threadMessageCreated,
  threadMessageDelta,
  threadRunRequiresAction,
  other
}

class ThreadRunsRepositoryImpl implements ThreadRunsRepository {
  @override
  Stream<ThreadResponse> createRunStream(
      String threadId, String assistantId) async* {
    final request = http.Request(
        'POST', Uri.parse("${ApiConstants.threadsEndpoint}/$threadId/runs"))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
        'OpenAI-Beta': 'assistants=v2',
      })
      ..body = jsonEncode({
        "assistant_id": assistantId,
        "stream": true,
      });

    yield* createThreadResponseStream(request);
  }

  @override
  Stream<ThreadResponse> createMessageAndRunStream(
      String threadId, String assistantId, String message) async* {
    final createMessageRequest = http.Request(
        'POST', Uri.parse("${ApiConstants.threadsEndpoint}/$threadId/messages"))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
        'OpenAI-Beta': 'assistants=v2',
      })
      ..body = jsonEncode({
        "role": "user",
        "content": message,
      });

    final http.StreamedResponse streamedResponse =
        await http.Client().send(createMessageRequest);
    final String responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      yield* createRunStream(threadId, assistantId);
    } else {
      // Provide as much detail as possible for debugging
      throw HttpException(
        'Failed to create a message. '
        'Status: ${streamedResponse.statusCode}, '
        'Response: $responseBody',
        uri: createMessageRequest.url,
      );
    }
  }

  @override
  Stream<ThreadResponse> createThreadAndRunStream(
      String assistantId, String message) async* {
    final request =
        http.Request('POST', Uri.parse("${ApiConstants.threadsEndpoint}/runs"))
          ..headers.addAll({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConstants.apiKey}',
            'OpenAI-Beta': 'assistants=v2',
          })
          ..body = jsonEncode({
            "assistant_id": assistantId,
            "stream": true,
            "thread": {
              "messages": [
                {"role": "user", "content": message}
              ]
            }
          });

    yield* createThreadResponseStream(request);
  }

  @override
  Stream<ThreadResponse> submitToolOutputsToRunStream(String threadId,
      String runId, List<ThreadToolOutput> toolOutputs) async* {
    // String outputs = toolOutputs[0].output;
    final request = http.Request(
        'POST',
        Uri.parse(
            "${ApiConstants.threadsEndpoint}/$threadId/runs/$runId/submit_tool_outputs"))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
        'OpenAI-Beta': 'assistants=v2',
      })
      ..body = jsonEncode({"stream": true, "tool_outputs": toolOutputs});

    yield* createThreadResponseStream(request);
  }

  Stream<ThreadResponse> createThreadResponseStream(Request request) async* {
    final stream = await getStream(request);

    var currentEvent = ThreadResponseEvent.initial;
    Message messageObj = Message(role: "assistant");
    ThreadFunctionTool threadFunctionTool = ThreadFunctionTool(
        callId: '', runId: '', index: 0, name: '', arguments: '');

    await for (final line
        in stream.transform(utf8.decoder).transform(const LineSplitter())) {
      final jsonString = line.replaceFirst('data: ', '').trim();

      if (jsonString.isEmpty) continue;

      if (jsonString == '[DONE]') return;

      // Detect event lines and update the current event.
      if (jsonString.startsWith("event: ")) {
        if (jsonString.contains("thread.created")) {
          currentEvent = ThreadResponseEvent.threadCreated;
        } else if (jsonString.contains("thread.run.created")) {
          currentEvent = ThreadResponseEvent.threadRunCreated;
        } else if (jsonString.contains("thread.message.created")) {
          currentEvent = ThreadResponseEvent.threadMessageCreated;
        } else if (jsonString.contains("thread.message.delta")) {
          currentEvent = ThreadResponseEvent.threadMessageDelta;
        } else if (jsonString.contains("thread.run.requires_action")) {
          currentEvent = ThreadResponseEvent.threadRunRequiresAction;
        } else {
          currentEvent = ThreadResponseEvent.other;
        }
        continue;
      }

      try {
        final data = jsonDecode(jsonString);

        switch (currentEvent) {
          case ThreadResponseEvent.threadMessageDelta:
            final messageDelta = MessageDelta.fromJson(data);

            messageObj.id =
                messageObj.id.isEmpty ? messageDelta.id : messageObj.id;

            if (messageDelta.delta.content.isNotEmpty) {
              messageObj.content += messageDelta.delta.content.first.text.value;
              yield messageObj;
            }
            break;
          case ThreadResponseEvent.threadCreated:
            final thread = Thread.fromJson(data);
            yield thread;
            break;
          case ThreadResponseEvent.threadRunCreated:
            final threadRun = ThreadRun.fromJson(data);
            yield threadRun;
            break;
          case ThreadResponseEvent.threadRunRequiresAction:
            final toolCalls =
                data["required_action"]["submit_tool_outputs"]["tool_calls"];

            if (toolCalls.isNotEmpty) {
              final toolCall = toolCalls[0];
              threadFunctionTool.runId = data["id"];
              threadFunctionTool.callId = toolCall["id"];
              threadFunctionTool.name = toolCall["function"]["name"];
              threadFunctionTool.arguments = toolCall["function"]["arguments"];
              yield threadFunctionTool;
            }
            break;
          default:
            break;
        }
      } catch (e) {
        // Skip malformed JSON but log for debugging
        print("Error parsing JSON: $e, Data: $jsonString");
      }
    }
  }
}
