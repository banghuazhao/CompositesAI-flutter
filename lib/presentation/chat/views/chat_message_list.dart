import 'dart:math';

import 'package:domain/domain.dart';
import 'package:domain/entities/thread_response.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';
import 'package:ui_components/beating_text.dart';
import 'package:ui_components/blinking_text.dart';

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
              : ListView.separated(
                  controller: chatViewModel.scrollController,
                  padding: EdgeInsets.fromLTRB(20, 10, 10, 15),
                  itemCount: chatList(context, chatViewModel).length,
                  itemBuilder: (context, index) {
                    return chatList(context, chatViewModel)[index];
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 5);
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30), // More spacing from the top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo with rounded corners
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'images/Icon-512.png',  // Path to your image
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 10), // More spacing for a balanced look
                  Flexible( // Prevents text from overflowing
                    child: Text(
                      "Hi, I am Composites AI",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal, // Make it stand out
                        color: Colors.black87, // Slightly softer than pure black
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "How can I help you today?",
              style: TextStyle(
                fontSize: 28, // Slightly larger for better readability
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // Input Bar only on Web
            if (kIsWeb) inputBar(viewModel),

            LayoutBuilder(
              builder: (context, constraints) {
                double width = constraints.maxWidth;
                int crossAxisCount = max(width ~/ 200, 2);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 2,
                    crossAxisSpacing: 12.0, // More spacing
                    mainAxisSpacing: 12.0,
                  ),
                  itemCount: viewModel.defaultQuestions.length,
                  padding: const EdgeInsets.all(16),
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

            const SizedBox(height: 30),
          ],
        )

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

  Widget buildUserMessage(ChatViewModel viewModel, Message message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IntrinsicWidth(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: max(280, MediaQuery.of(context).size.width * 0.6),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
        buildMessageActions(viewModel, message),
      ],
    );
  }

  Widget buildMessageActions(ChatViewModel viewModel, Message message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: viewModel.isMessageCopying(message)
              ? const Icon(Icons.check, size: 15)
              : const Icon(Icons.copy, size: 15),
          onPressed: viewModel.isMessageCopying(message)
              ? null
              : () async {
                  viewModel.copyMessage(message);
                },
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.all(6)),
            minimumSize: WidgetStateProperty.all(Size.zero),
          ),
        ),
        IconButton(
          icon: viewModel.isMessageSelected(message)
              ? const Icon(Icons.check_box, size: 15)
              : const Icon(Icons.check_box_outline_blank, size: 15),
          onPressed: () {
            viewModel.toggleMessageSelection(message);
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.all(6)),
            minimumSize: WidgetStateProperty.all(Size.zero),
          ),
        )
      ],
    );
  }

  Widget buildAssistantMessage(ChatViewModel viewModel, Message message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        gptResponseWidget(message.content),
        buildMessageActions(viewModel, message),
      ],
    );
  }

  Widget gptResponseWidget(String originalResponse) {
    RegExp citationRegExp = RegExp(r'【.*?】');
    String cleanText = originalResponse.replaceAll(citationRegExp, '');
    final lines = cleanText.split('\n\n');
    final responseLines = lines
        .map((line) => SelectionArea(
                child: GptMarkdown(
              line,
              style: const TextStyle(fontSize: 15, color: Colors.black),
            )))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: responseLines,
    );
  }

  StreamBuilder<ThreadResponse> messageStream(ChatViewModel viewModel) {
    return StreamBuilder<ThreadResponse>(
        stream: viewModel.threadResponseController.stream,
        builder: (context, snapshot) {
          return Align(
              alignment: Alignment.centerLeft, child: streamWidget(snapshot));
        });
  }

  Widget streamWidget(AsyncSnapshot<ThreadResponse> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return BeatingText(
        text: "●",
        style: TextStyle(fontSize: 15.0),
        // Customize your text style as needed
        period: Duration(milliseconds: 1000),
        // Adjust the period for speed of beat
        minScale: 0.8,
        maxScale: 1.2,
      );
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else if (snapshot.data != null) {
      final threadResponse = snapshot.data!;
      if (threadResponse is Message) {
        return gptResponseWidget("${threadResponse.chatContent} ●");
      } else {
        return BlinkingText(
          text: "Thinking...",
          style: TextStyle(fontSize: 15.0), // Customize the style as needed
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
                    } else if (!viewModel.isLoading) {
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
                    hintText: 'Ask anything about Composites...',
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
