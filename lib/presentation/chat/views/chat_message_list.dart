import 'dart:math';

import 'package:domain/domain.dart';
import 'package:domain/entities/thread_function_tool.dart';
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
import 'package:url_launcher/url_launcher.dart';

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
                    'images/Icon-512.png', // Path to your image
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 10), // More spacing for a balanced look
                Flexible(
                  child: Text(
                    "Hi, I am Composites AI",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
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
          if (kIsWeb) ...[
            inputBar(viewModel),
            const SizedBox(height: 10),
          ],

          Center(
            // Center the grid
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 800, // Adjust as needed to keep it centered
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth;
                  int crossAxisCount = max(width ~/ 200, 2);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 2,
                      crossAxisSpacing: 12.0,
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
            ),
          ),

          const SizedBox(height: 30),
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
        // Copy Icon
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
            padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
            minimumSize: WidgetStateProperty.all(Size.zero),
          ),
        ),

        // Select Checkbox
        IconButton(
          icon: viewModel.isMessageSelected(message)
              ? const Icon(Icons.check_box, size: 15)
              : const Icon(Icons.check_box_outline_blank, size: 15),
          onPressed: () {
            viewModel.toggleMessageSelection(message);
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
            minimumSize: WidgetStateProperty.all(Size.zero),
          ),
        ),

        if (viewModel.isAssistantMessage(message)) ...[
          if (message.isLiked == null)
            IconButton(
              icon: const Icon(Icons.thumb_up_outlined, size: 15),
              onPressed: () {
                viewModel.toggleMessageLikeStatus(message, true);
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
                minimumSize: WidgetStateProperty.all(Size.zero),
              ),
            ),
          if (message.isLiked == null)
            IconButton(
              icon: const Icon(Icons.thumb_down_outlined, size: 15),
              onPressed: () {
                viewModel.toggleMessageLikeStatus(message, false);
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
                minimumSize: WidgetStateProperty.all(Size.zero),
              ),
            ),
          if (message.isLiked != null && message.isLiked!)
            IconButton(
              icon: Icon(Icons.thumb_up, size: 15, color: Colors.grey[700]),
              onPressed: () {
                viewModel.toggleMessageLikeStatus(message, message.isLiked!);
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
                minimumSize: WidgetStateProperty.all(Size.zero),
              ),
            ),
          if (message.isLiked != null && !message.isLiked!)
            IconButton(
              icon: Icon(Icons.thumb_down, size: 15, color: Colors.grey[700]),
              onPressed: () {
                viewModel.toggleMessageLikeStatus(message, message.isLiked!);
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
                minimumSize: WidgetStateProperty.all(Size.zero),
              ),
            ),
        ],
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
    String cleanTextWithImage = cleanText.replaceAll('![', '![280x280 ');
    final lines = cleanTextWithImage.split('\n\n');
    final responseLines = lines
        .map((line) => SelectionArea(
                child: GptMarkdown(
              line,
              style: const TextStyle(fontSize: 15, color: Colors.black),
              onLinkTab: (String url, String title) {
                launchUrl(Uri.parse(url));
              },
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
          return Align(alignment: Alignment.centerLeft, child: streamWidget(snapshot));
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
        return gptResponseWidget("${threadResponse.content} ●");
      } else if (threadResponse is ThreadFunctionTool) {
        return BlinkingText(
          text: "Calling Tools...",
          style: TextStyle(fontSize: 15.0), // Customize the style as needed
        );
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
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (KeyEvent event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                      final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed
                              .contains(LogicalKeyboardKey.shiftLeft) ||
                          HardwareKeyboard.instance.logicalKeysPressed
                              .contains(LogicalKeyboardKey.shiftRight);
                      if (isShiftPressed) {
                        // Insert newline
                        final text = textController.text;
                        textController.text = "$text\n";
                        textController.selection = TextSelection.fromPosition(
                          TextPosition(offset: textController.text.length),
                        );
                      } else if (!viewModel.isLoading) {
                        final text = textController.text.trim();
                        if (text.isNotEmpty) {
                          textController.clear();
                          viewModel.sendInputMessage(text);
                        }
                      }
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
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.done,
                    minLines: 2,
                    maxLines: 8,
                    onChanged: (text) {
                      setState(() {}); // Update UI for button state
                    },
                  ),
                ),
              ),
              viewModel.isLoading
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.send),
                      onPressed: textController.text.isEmpty
                          ? null
                          : () {
                              final text = textController.text.trim();
                              if (text.isNotEmpty) {
                                textController.clear();
                                viewModel.sendInputMessage(text);
                              }
                            },
                    ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// A helper function to create default question cards
Widget _buildDefaultQuestionCard(String question) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Colors.grey.shade200, width: 1.0),
    ),
    elevation: 2, // Lower elevation for a more compact look
    child: SizedBox(
      width: 80, // Reduce the width
      height: 30, // Reduce the height
      child: Padding(
        padding: const EdgeInsets.all(4.0), // Reduce padding
        child: Center(
          child: Text(
            question,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black), // Smaller font size
            maxLines: 3,
            overflow: TextOverflow.ellipsis, // Prevents overflow
          ),
        ),
      ),
    ),
  );
}
