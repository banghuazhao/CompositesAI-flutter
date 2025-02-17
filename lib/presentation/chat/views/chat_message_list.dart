import 'dart:math';

import 'package:domain/domain.dart';
import 'package:domain/entities/thread.dart';
import 'package:domain/entities/thread_response.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
                  itemCount:
                      chatList(context, chatViewModel).length, // Pass context
                  itemBuilder: (context, index) {
                    return chatList(
                        context, chatViewModel)[index]; // Pass context
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

  List<Widget> chatList(BuildContext context, ChatViewModel viewModel) {
    List<Widget> messageWidgetsList = [];
    final messages = viewModel.messages;

    for (final message in messages) {
      if (message.role == "user") {
        messageWidgetsList.add(buildUserMessage(viewModel, message));
      } else {
        messageWidgetsList.add(buildAssistantMessage(viewModel, message));
      }
    }

    messageWidgetsList.add(messageStream(viewModel));

    return messageWidgetsList;
  }

  Widget buildUserMessage(
      ChatViewModel viewModel, Message message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IntrinsicWidth(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: max(280, MediaQuery.of(context).size.width * 0.6),
              ),
              margin:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
              padding: const EdgeInsets.symmetric(
                  vertical: 10.0, horizontal: 15.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: SelectableText(
                message.content ?? "",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: buildMessageActions(viewModel, message)
          ),
        ],
      ),
    );
  }

  Widget buildMessageActions(ChatViewModel viewModel, Message message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: viewModel.isMessageCopying(message)
              ? const Icon(Icons.check, size: 18)
              : const Icon(Icons.copy, size: 18),
          onPressed: viewModel.isMessageCopying(message)
              ? null
              : () async {
            viewModel.copyMessage(message);
          },
        ),
        IconButton(
          icon: viewModel.isMessageSelected(message)
              ? const Icon(Icons.check_box, size: 18)
              : const Icon(Icons.check_box_outline_blank, size: 18),
          onPressed: () {
            viewModel.toggleMessageSelection(message);
          },
        )
      ],
    );
  }

  Widget buildAssistantMessage(
      ChatViewModel viewModel, Message message) {
    final originalText = message.content;
    RegExp citationRegExp = RegExp(r'【.*?】');
    String cleanText = originalText.replaceAll(citationRegExp, '');
    return Align(
      alignment: Alignment.centerLeft, // Keep alignment
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            child: MarkdownWithMath(markdownData: cleanText),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: buildMessageActions(viewModel, message)
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
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
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
        return MarkdownWithMath(
            markdownData: "${threadResponse.chatContent} ●");
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
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter) {
                    // Check if the Shift key is pressed
                    final isShiftPressed = HardwareKeyboard
                            .instance.logicalKeysPressed
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
                      final text =
                          textController.text; // Remove extra spaces/newlines
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
