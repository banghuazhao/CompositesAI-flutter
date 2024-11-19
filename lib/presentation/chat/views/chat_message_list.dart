import 'dart:math';

import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'markdown_with_math.dart';
import '../viewModels/chat_view_model.dart';

class ChatMessageList extends StatefulWidget {
  @override
  _ChatMessageListState createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);

    final messages = chatViewModel.messages;

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? defaultQuestionView(chatViewModel)
              : ListView.builder(
                  controller: chatViewModel.scrollController,
                  itemCount: chatList(chatViewModel).length,
                  itemBuilder: (context, index) {
                    return chatList(chatViewModel)[index];
                  },
                ),
        ),
        if (messages.isNotEmpty || !kIsWeb) inputBar(chatViewModel)
      ],
    );
  }

  Widget defaultQuestionView(ChatViewModel viewModel) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey,
            ),
          ),
          Text(
            "What can I help with?",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          if (kIsWeb) inputBar(viewModel),
          // Default questions displayed as cards or buttons
          LayoutBuilder(
            builder: (context, constraints) {
              // Determine the number of columns based on the screen width
              double width = constraints.maxWidth;
              int crossAxisCount = 2;
              if (width >= 1000) {
                crossAxisCount = 5;
              } else if (width >= 800) {
                crossAxisCount = 4;
              } else if (width >= 600) {
                crossAxisCount = 3;
              }
              crossAxisCount = max(width ~/ 200, 2);

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  // Number of items in a row
                  childAspectRatio: 2,
                  // Width to height ratio of each item
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: viewModel.defaultQuestions.length,
                padding: EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      await viewModel.onDefaultQuestionsTapped(index);
                    },
                    child: _buildDefaultQuestionCard(
                        viewModel.defaultQuestions[index]),
                  );
                },
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> chatList(ChatViewModel viewModel) {
    List<Widget> result = [];
    final messages = viewModel.messages;
    for (final message in messages) {
      switch (message.role) {
        case "user":
          result.add(Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
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
          ));
          continue;
        case "assistant":
          result.add(Align(
            alignment: Alignment.centerLeft,
            child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                child: MarkdownWithMath(markdownData: message.chatContent)),
          ));
          continue;
        default:
          result.add(Container());
      }
    }

    result.add(StreamBuilder<Message>(
        stream: viewModel.messageStreamController.stream,
        builder: (context, snapshot) {
          return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  child: streamWidget(snapshot)));
        }));

    return result;
  }

  Widget inputBar(ChatViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(24.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    border: InputBorder.none, // Remove the line under the TextField
                    enabledBorder: InputBorder.none, // No border when active
                    focusedBorder: InputBorder.none, // No border when focused
                  ),
                  onSubmitted: (value) {
                    if (textController.text.isNotEmpty && !viewModel.isLoading) {
                      final text = textController.text;
                      textController.clear();
                      viewModel.sendInputMessage(text);
                    }
                  },
                  onChanged: (value) {
                    setState(() {});
                  }),
            ),
            viewModel.isLoading
                ? CircularProgressIndicator() // Show loading indicator
                : IconButton(
                    icon: Icon(Icons.send),
                    onPressed: textController.text.isEmpty
                        ? null
                        : () async {
                            final text = textController.text;
                            textController.clear();
                            await viewModel.sendInputMessage(text);
                          }),
          ],
        ),
      ),
    );
  }

  Widget streamWidget(AsyncSnapshot<Message> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Text("●"); // Loading indicator while waiting for data
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}'); // Display error message
    } else if (snapshot.data != null) {
      final message = snapshot.data!;
      return MarkdownWithMath(markdownData: message.chatContent + " ●");
    } else {
      return Container();
    }
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
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          question,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
      ),
    ),
  );
}
