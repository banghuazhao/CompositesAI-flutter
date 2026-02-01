import 'dart:math';

import 'package:domain/domain.dart';
import 'package:domain/entities/chat/chat_response.dart';
import 'package:domain/entities/chat/function_tool.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/chat/model/message_extension.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';
import 'package:ui_components/beating_text.dart';
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

        if (message.isAssistantMessage) ...[
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
    String finalText = cleanText.replaceAll('\n\n', '\n');
    return SelectionArea(
        child: GptMarkdown(
          finalText,
          style: const TextStyle(fontSize: 15, color: Colors.black),
          onLinkTab: (String url, String title) {
            launchUrl(Uri.parse(url));
          },
        ));
  }

  StreamBuilder<ChatResponse> messageStream(ChatViewModel viewModel) {
    return StreamBuilder<ChatResponse>(
        stream: viewModel.threadResponseController.stream,
        builder: (context, snapshot) {
          return Align(
              alignment: Alignment.centerLeft, child: streamWidget(snapshot));
        });
  }

  Widget streamWidget(AsyncSnapshot<ChatResponse> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Container();
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else if (snapshot.data != null) {
      final threadResponse = snapshot.data!;
      if (threadResponse is Message) {
        return gptResponseWidget("${threadResponse.content} ●");
      } else if (threadResponse is FunctionTool) {
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
}
