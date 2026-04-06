import 'dart:math';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';
import 'package:ui_components/blinking_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../viewModels/chat_view_model.dart';

class MessageList extends StatefulWidget {
  const MessageList({Key? key}) : super(key: key);

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  int? copyingMessageIndex;

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);

    return Stack(
      children: [
        ListView.separated(
          controller: chatViewModel.scrollController,
          padding: EdgeInsets.fromLTRB(
              context.horizontalSidePaddingForContentWidth,
              20,
              context.horizontalSidePaddingForContentWidth,
              20 + 100),
          itemCount: messagesList(context, chatViewModel).length,
          itemBuilder: (context, index) {
            return messagesList(context, chatViewModel)[index];
          },
          separatorBuilder: (context, index) {
            return SizedBox(height: 5);
          },
        )
      ],
    );
  }

  List<Widget> messagesList(BuildContext context, ChatViewModel viewModel) {
    List<Widget> messageWidgetsList = [];
    final messages = viewModel.messages;

    for (int messageIndex = 0; messageIndex < messages.length; messageIndex++) {
      final message = messages[messageIndex];
      if (message.role == "user") {
        messageWidgetsList.add(buildUserMessage(viewModel, message));
      } else {
        messageWidgetsList.add(
          buildAssistantMessage(viewModel, message, messageIndex),
        );
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
              message.content,
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
      children: [buildCopyIconButton(viewModel, message)],
    );
  }

  Widget buildCopyIconButton(ChatViewModel viewModel, Message message) {
    return IconButton(
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
    );
  }

  Widget buildAssistantMessageActions(
      ChatViewModel viewModel, Message message, int messageIndex) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildCopyIconButton(viewModel, message),
        IconButton(
          tooltip: 'Good response',
          icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
          onPressed: () async {
            await _showResponseFeedbackDialog(
              context: context,
              viewModel: viewModel,
              message: message,
              initialIsGood: true,
              messageIndex: messageIndex,
            );
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
            minimumSize: WidgetStateProperty.all(Size.zero),
          ),
        ),
        IconButton(
          tooltip: 'Bad response',
          icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
          onPressed: () async {
            await _showResponseFeedbackDialog(
              context: context,
              viewModel: viewModel,
              message: message,
              initialIsGood: false,
              messageIndex: messageIndex,
            );
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
            minimumSize: WidgetStateProperty.all(Size.zero),
          ),
        ),
      ],
    );
  }

  Future<void> _showResponseFeedbackDialog({
    required BuildContext context,
    required ChatViewModel viewModel,
    required Message message,
    required bool initialIsGood,
    required int messageIndex,
  }) async {
    if (viewModel.selectedChat == null) return;
    final BuildContext pageContext = context;

    final List<String> reasons = initialIsGood
        ? const [
            'Accurate information',
            'Followed instructions perfectly',
            'Showcased creativity',
            'Positive attitude',
            'Attention to detail',
            'Thorough explanation',
            'Other',
          ]
        : const [
            "Don't like the style",
            'Too verbose',
            'Not helpful',
            'Not factually correct',
            "Didn't fully follow instructions",
            "Refused when it shouldn't have",
            'Being lazy',
            'Other',
          ];

    final int initialRating = initialIsGood ? 10 : 1;

    int rating = initialRating;
    final selectedReasons = <String>{};
    final commentController = TextEditingController();
    String? localError;
    bool isSaving = false;

    final bool? saved = await showDialog<bool>(
      context: pageContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey.shade900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'How would you rate this response?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(10, (index) {
                        final value = index + 1;
                        final selected = value == rating;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              rating = value;
                              localError = null;
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? Colors.white : Colors.transparent,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$value',
                                style: TextStyle(
                                  color: selected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1 - Awful',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                        Text(
                          '10 - Amazing',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Why?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: reasons.map((reason) {
                        final bool selected = selectedReasons.contains(reason);
                        return FilterChip(
                          label: Text(
                            reason,
                            style: TextStyle(
                              color: selected ? Colors.black : Colors.white,
                            ),
                          ),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              if (selected) {
                                selectedReasons.remove(reason);
                              } else {
                                selectedReasons.add(reason);
                              }
                              localError = null;
                            });
                          },
                          selectedColor: Colors.white,
                          backgroundColor: Colors.grey.shade800,
                          checkmarkColor: Colors.black,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Feel free to add specific details',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      cursorColor: Colors.white,
                      cursorErrorColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type more details...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        localError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (selectedReasons.isEmpty) {
                            setState(() {
                              localError = 'Please select at least one reason.';
                            });
                            return;
                          }

                          setState(() {
                            isSaving = true;
                            localError = null;
                          });

                          final int goodBadRating =
                              initialIsGood ? 1 : -1; // data.rating: 1/-1
                          final int detailsRating = rating; // details.rating
                          final String? commentText =
                              commentController.text.trim().isNotEmpty
                                  ? commentController.text.trim()
                                  : null;

                          final ok = await viewModel.submitMessageFeedback(
                            message: message,
                            goodBadRating: goodBadRating,
                            detailsRating: detailsRating,
                            reasons: selectedReasons.toList(),
                            comment: commentText,
                            messageIndex: messageIndex + 1, // backend is 1-based
                          );

                          if (ok) {
                            Navigator.of(dialogContext).pop(true);
                          } else {
                            setState(() {
                              isSaving = false;
                              localError =
                                  'Failed to submit feedback. Please try again.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && pageContext.mounted) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(
          content: Text('Thanks for your feedback!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget buildAssistantMessage(
      ChatViewModel viewModel, Message message, int messageIndex) {
    final isLast =
        viewModel.messages.isNotEmpty && viewModel.messages.last == message;
    final isStreaming = isLast && viewModel.isSendingMessage;

    return message.content.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              gptResponseWidget(message.content),
              if (!isStreaming)
                buildAssistantMessageActions(
                  viewModel,
                  message,
                  messageIndex,
                ),
            ],
          )
        : Container();
  }

  Widget gptResponseWidget(String originalResponse) {
    RegExp citationRegExp = RegExp(r'【.*?】');
    String cleanText = originalResponse.replaceAll(citationRegExp, '');
    String finalText = cleanText.replaceAll('\n\n', '\n');
    return SelectionArea(
      child: GptMarkdown(
        finalText,
        style: const TextStyle(fontSize: 15, color: Colors.black),
        latexBuilder: (context, tex, textStyle, inline) {
          final math = Math.tex(
            tex,
            textStyle: textStyle,
            mathStyle: inline ? MathStyle.text : MathStyle.display,
          );

          // Keep normal short inline math unchanged, so existing rendering style stays intact.
          if (inline && tex.length < 50) {
            return math;
          }

          // For long or block formulas, provide horizontal scrolling container
          // to avoid overflow without affecting other markdown widgets.
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: math,
            ),
          );
        },
        onLinkTap: (String url, String title) {
          launchUrl(Uri.parse(url));
        },
      ),
    );
  }

  StreamBuilder<Message> messageStream(ChatViewModel viewModel) {
    return StreamBuilder<Message>(
        stream: viewModel.threadResponseController.stream,
        builder: (context, snapshot) {
          return Align(
              alignment: Alignment.centerLeft,
              child: streamWidget(snapshot, viewModel));
        });
  }

  Widget streamWidget(
      AsyncSnapshot<Message> snapshot, ChatViewModel viewModel) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      if (viewModel.isSendingMessage) {
        return BlinkingText(
          text: "Thinking...",
          style: TextStyle(fontSize: 15.0),
        );
      }
      return Container();
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    return Container();
  }
}
