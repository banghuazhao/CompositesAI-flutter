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

    final messages = selectedSession.messages;

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Column(
                  children: [
                    // Optional: Add a logo or banner at the top like the second image
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      "Ask a question to get started!",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 20),
                    // Default questions displayed as cards or buttons
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        // You can adjust the number of columns
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        padding: EdgeInsets.all(16),
                        children: List.generate(chatViewModel.defaultQuestions.length, (index) {
                          return InkWell(
                            onTap: () {
                              chatViewModel.onDefaultQuestionsTapped(index);
                            },
                            child: _buildDefaultQuestionCard(chatViewModel.defaultQuestions[index]),
                          );
                        }),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: chatViewModel.scrollController,
                  itemCount: selectedSession.messages.length,
                  itemBuilder: (context, index) {
                    final message = selectedSession.messages[index];
                    switch (message.role) {
                      case "user":
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 10.0),
                            padding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 15.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Text(
                              message.content ?? "",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        );
                      case "assistant":
                        final assistantMessageContent =
                            chatViewModel.assistantMessageContent(message);
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 15.0),
                            child: MarkdownWithMath(
                                markdownData: assistantMessageContent),
                          ),
                        );
                      default:
                        return Container();
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
                              await chatViewModel.sendCurrentUserMessage();
                            },
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

// A helper function to create default question cards
Widget _buildDefaultQuestionCard(String question) {
  return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            question,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ),
  );
}
