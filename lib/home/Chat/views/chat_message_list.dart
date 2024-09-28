import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'markdown_with_math.dart';
import '../viewModels/chat_view_model.dart';

class ChatMessageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);

    final selectedSession = chatViewModel.selectedSession;

    if (selectedSession == null) {
      return Center(child: Text('No session selected.'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: chatViewModel.scrollController,
            itemCount: selectedSession.messages.length,
            itemBuilder: (context, index) {
              final message = selectedSession.messages[index];
              final isUserMessage = chatViewModel.isUserMessage(message);

              if (isUserMessage) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              } else {
                final assistantMessageContent =
                    chatViewModel.assistantMessageContent(message);
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    child:
                        MarkdownWithMath(markdownData: assistantMessageContent),
                  ),
                );
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatViewModel.controller,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                  ),
                ),
              ),
              chatViewModel.isLoading
                  ? CircularProgressIndicator() // Show loading indicator
                  : IconButton(
                      icon: Icon(Icons.send),
                      onPressed: chatViewModel.isUserInputEmpty()
                          ? null
                          : () async {
                              await chatViewModel.sendMessage();
                            },
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
