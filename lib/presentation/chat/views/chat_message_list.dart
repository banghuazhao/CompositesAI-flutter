import 'dart:math';

import 'package:domain/domain.dart';
import 'package:domain/entities/thread.dart';
import 'package:domain/entities/thread_response.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ui_components/beating_text.dart';
import 'package:ui_components/blinking_text.dart';

import 'markdown_with_math.dart';
import '../viewModels/chat_view_model.dart';

class ChatMessageList extends StatefulWidget {
  @override
  _ChatMessageListState createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final TextEditingController textController =
      TextEditingController(); // final means can assign the TextEditingController object to the variable only once.
  final FocusNode focusNode = FocusNode();
  int? copyingMessageIndex;

  @override
  void dispose() {
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }

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
              color: Colors.blueGrey,
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
                    child: _buildDefaultQuestionCard(viewModel.defaultQuestions[index]),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: max(280, MediaQuery.of(context).size.width * 0.6),
                  ),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: viewModel.copyingMessage == message.content
                            ? Icon(Icons.check, size: 18)
                            : Icon(Icons.copy, size: 18),
                        onPressed: viewModel.copyingMessage == message.content
                            ? null
                            : () async {
                                viewModel.copyMessage(message.content ?? "");
                              },
                      ),
                      if (viewModel.copyingMessage.isNotEmpty &&
                          viewModel.copyingMessage == message.content)
                        Padding(
                          padding: EdgeInsets.only(right: 15.0),
                          child: Text("Copied"),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ));
          continue;
        case "assistant":
          result.add(buildAssistantMessage(viewModel, message.chatContent ?? ""));
          continue;
        default:
          result.add(Container());
      }
    }

    result.add(messageStream(viewModel));

    return result;
  }

  Widget buildAssistantMessage(ChatViewModel viewModel, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: MarkdownWithMath(markdownData: text),
          ),
          Row(
            children: [
              IconButton(
                icon: viewModel.copyingMessage == text
                    ? Icon(Icons.check, size: 18) // Adjust size for the check icon
                    : Icon(Icons.copy, size: 18), // Adjust size for the copy icon
                onPressed: viewModel.copyingMessage == text
                    ? null
                    : () async {
                        viewModel.copyMessage(text);
                      },
              ),
              if (viewModel.copyingMessage.isNotEmpty && viewModel.copyingMessage == text)
                Text("Copied")
              // You can add other buttons here if needed, e.g. thumbs up/down, etc.
            ],
          ),
        ],
      ),
    );
  }

  StreamBuilder<ThreadResponse> messageStream(ChatViewModel viewModel) {
    return StreamBuilder<ThreadResponse>(
        stream: viewModel.threadResponseController.stream,
        builder: (context, snapshot) {
          return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  child: streamWidget(snapshot)));
        });
  }

  Widget streamWidget(AsyncSnapshot<ThreadResponse> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return BeatingText(
        text: "●",
        style: TextStyle(fontSize: 16.0),
        // Customize your text style as needed
        period: Duration(milliseconds: 1000),
        // Adjust the period for speed of beat
        minScale: 1.0,
        maxScale: 1.2,
      );
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else if (snapshot.data != null) {
      final threadResponse = snapshot.data!;
      if (threadResponse is Message) {
        return MarkdownWithMath(markdownData: "${threadResponse.chatContent} ●");
      } else {
        return BlinkingText(
          text: "Thinking...",
          style: TextStyle(fontSize: 16.0), // Customize the style as needed
        );
      }
    } else {
      return Container();
    }
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
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (KeyEvent event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                    // Check if the Shift key is pressed
                    final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed
                            .contains(LogicalKeyboardKey.shiftLeft) ||
                        HardwareKeyboard.instance.logicalKeysPressed
                            .contains(LogicalKeyboardKey.shiftRight);

                    if (isShiftPressed) {
                      // Add a newline only when Shift + Enter is pressed
                      final text = textController.text; // Clean up text
                      textController.text = "$text\n";
                      textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: textController.text.length),
                      );
                    } else {
                      // Submit the text and clear TextField on Enter
                      final text = textController.text; // Remove extra spaces/newlines
                      if (text.isNotEmpty) {
                        textController.clear(); // Clear input immediately
                        viewModel.sendInputMessage(text); // Send message
                      }
                    }
                    // Defer the cursor position update to avoid timing issues
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      focusNode.requestFocus();
                    });
                  }
                },
                child: TextField(
                  controller: textController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  // Treat Enter as Done
                  maxLines: null,
                  onChanged: (text) {
                    setState(() {}); // Ensure the button updates
                  }, // Allow multiple lines if Shift + Enter is used
                ),
              ),
            ),
            viewModel.isLoading
                ? CircularProgressIndicator()
                : IconButton(
                    icon: Icon(Icons.send),
                    onPressed: textController.text.isEmpty
                        ? null
                        : () {
                            final text = textController.text; // Clean text
                            if (text.isNotEmpty) {
                              textController.clear(); // Clear input field
                              viewModel.sendInputMessage(text);
                              focusNode.requestFocus();
                            }
                          },
                  ),
          ],
        ),
      ),
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
