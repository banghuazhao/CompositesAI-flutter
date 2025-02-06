import 'dart:async';
import 'dart:convert';
import 'package:domain/entities/message.dart';
import 'package:domain/entities/thread.dart';
import 'package:domain/entities/thread_response.dart';
import 'package:domain/repositories_abstract/thread_runs_repository.dart';
import 'package:http/http.dart' as http;
import 'sse_stream.dart' if (dart.library.js) 'sse_stream_web.dart';

import '../utils/api_constants.dart';
import 'message_delta.dart';

enum ThreadResponseEvent {
  initial,
  threadCreated,
  runCreated,
  messageCreated,
  messageDelta,
  other
}

class ThreadRunsRepositoryImpl implements ThreadRunsRepository {
  // final http.Client client;
  //
  // ThreadRunsRepositoryImpl({required this.client});

  @override
  Stream<Message> createRunStream(String threadId, String assistantId) async* {
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

    final stream = await getStream(request);


    var threadResponseEvent = ThreadResponseEvent.initial;
    Message messageObj = Message(role: "assistant");

    await for (final line in stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      final jsonString = line.replaceFirst('data: ', '').trim();

      if (jsonString.isEmpty) continue;

      if (jsonString == '[DONE]') return;

      if (jsonString.contains("event: thread.created")) {
        threadResponseEvent = ThreadResponseEvent.threadCreated;
        continue;
      } else if (jsonString.contains("event: thread.run.created")) {
        threadResponseEvent = ThreadResponseEvent.runCreated;
        continue;
      } else if (jsonString.contains("event: thread.message.created")) {
        threadResponseEvent = ThreadResponseEvent.messageCreated;
        continue;
      } else if (jsonString.contains("event: thread.message.delta")) {
        threadResponseEvent = ThreadResponseEvent.messageDelta;
        continue;
      } else if (jsonString.contains("event:")) {
        threadResponseEvent = ThreadResponseEvent.other;
        continue;
      }

      try {
        final data = jsonDecode(jsonString);
        if (threadResponseEvent == ThreadResponseEvent.messageDelta) {
          final messageDelta = MessageDelta.fromJson(data);

          // Set message ID if it’s empty
          messageObj.id =
              messageObj.id.isEmpty ? messageDelta.id : messageObj.id;

          // Append new content
          if (messageDelta.delta.content.isNotEmpty) {
            messageObj.content += messageDelta.delta.content.first.text.value;
            yield messageObj;
          }
        }
      } catch (e) {
        // Skip malformed JSON but log for debugging
        print("Error parsing JSON: $e, Data: $jsonString");
      }
    }
  }

  @override
  Stream<ThreadResponse> createMessageAndRunStream(
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


    final stream = await getStream(request);

    var threadResponseEvent = ThreadResponseEvent.initial;
    Message messageObj = Message(role: "assistant");

    await for (final line in stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      final jsonString = line.replaceFirst('data: ', '').trim();
      print(jsonString);
      if (jsonString.isEmpty) continue;

      if (jsonString == '[DONE]') return;

      // Handle event lines
      if (jsonString.startsWith("event:")) {
        final eventName = jsonString.substring("event:".length).trim();
        switch (eventName) {
          case 'thread.created':
            threadResponseEvent = ThreadResponseEvent.threadCreated;
            break;
          case 'thread.run.created':
            threadResponseEvent = ThreadResponseEvent.runCreated;
            break;
          case 'thread.message.created':
            threadResponseEvent = ThreadResponseEvent.messageCreated;
            break;
          case 'thread.message.delta':
            threadResponseEvent = ThreadResponseEvent.messageDelta;
            break;
          default:
            threadResponseEvent = ThreadResponseEvent.other;
        }
        continue;
      }

      try {
        final data = jsonDecode(jsonString);
        if (threadResponseEvent == ThreadResponseEvent.messageDelta) {
          final messageDelta = MessageDelta.fromJson(data);

          messageObj.id =
              messageObj.id.isEmpty ? messageDelta.id : messageObj.id;
          if (messageDelta.delta.content.isNotEmpty) {
            messageObj.content = messageObj.content +
                messageDelta.delta.content.first.text.value;
            yield messageObj;
          }
        } else if (threadResponseEvent == ThreadResponseEvent.threadCreated) {
          final thread = Thread.fromJson(data);
          yield thread;
        }
      } catch (e) {
        // Consider using a logging framework here
        print("Error parsing JSON: $e, Data: $jsonString");
      }
    }
  }
}
