import 'dart:async';
import 'package:uuid/uuid.dart';

import 'package:domain/entities/message.dart';
import 'package:domain/repositories_abstract/chat_repository.dart';
import '../data_sources/function_tools_data_source.dart';
import '../data_sources/open_ai_data_source.dart';
import '../models/chat_chunk.dart';

class ChatRepositoryImp implements ChatRepository {
  final OpenAIDataSource openAIDataSource;
  final FunctionToolsDataSource functionToolsDataSource;

  ChatRepositoryImp(
      {required this.openAIDataSource, required this.functionToolsDataSource});

  @override
  Stream<Message> sendMessages(List<Message> messages) {
    // Create a StreamController to accumulate and emit the content as strings
    final StreamController<Message> controller = StreamController<Message>();

    final functionTools = functionToolsDataSource.getAllFunctionTools();

    // Call the original sendMessages method that returns Stream<ChatChunk>
    final chatChunks = openAIDataSource.sendMessages(messages, functionTools);

    Message? buffer;
    // Listen to the incoming stream of ChatChunks
    chatChunks.listen((ChatChunk chunk) {
      // Accumulate or extract the content from the ChatChunk and add it to the stream
      buffer ??= Message(id: chunk.id ?? const Uuid().v1(), role: "assistant");

      final token = chunk.choices?.first.delta?.content;
      if (token != null) {
        buffer!.content = (buffer?.content ?? "") + token;
      }

      final toolCalls = chunk.choices?.first.delta?.toolCalls;
      if (toolCalls != null) {
        if (buffer!.toolCalls == null) {
          buffer!.toolCalls = toolCalls;
        } else {
          final newArguments = toolCalls.first.function?.arguments;
          if (newArguments != null) {
            final currentArg =
                buffer!.toolCalls?.first.function?.arguments ?? "";
            buffer!.toolCalls?.first.function?.arguments =
                currentArg + newArguments;
          }
        }
      }

      controller.add(buffer!); // Emit the content to the stream
    }, onError: (error) {
      controller.addError(error); // Handle errors
    }, onDone: () {
      print("on close of chatChunks");
      controller.close(); // Close the stream when done
    });

    return controller.stream;
  }
}
