import 'dart:math';
import 'dart:typed_data';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

import '../model/chat_citation.dart';
import '../viewModels/chat_view_model.dart';
import 'ai_markdown_message.dart';
import 'chat_citation_widgets.dart';
import 'chat_progress_indicator.dart';
import 'response_feedback_sheet.dart';

class MessageList extends StatefulWidget {
  final double bottomContentPadding;

  const MessageList({
    super.key,
    required this.bottomContentPadding,
  });

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  @override
  Widget build(BuildContext context) {
    final chatViewModel = context.watch<ChatViewModel>();
    final messages = chatViewModel.messages;

    return ListView.separated(
      controller: chatViewModel.scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        context.horizontalSidePaddingForContentWidth,
        20,
        context.horizontalSidePaddingForContentWidth,
        widget.bottomContentPadding,
      ),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return messageStream(chatViewModel);
        }

        final message = messages[index];
        return RepaintBoundary(
          key: ValueKey(message.id),
          child: message.role == 'user'
              ? buildUserMessage(chatViewModel, message)
              : buildAssistantMessage(chatViewModel, message, index),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 16),
    );
  }

  Widget buildUserMessage(ChatViewModel viewModel, Message message) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.files.isNotEmpty) buildAttachedFiles(viewModel, message),
        if (message.content.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: min(
                  680,
                  max(280, MediaQuery.of(context).size.width * 0.72),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        buildMessageActions(viewModel, message),
      ],
    );
  }

  static bool _isImageFile(ChatFile file) {
    final ext = file.name.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'}.contains(ext);
  }

  Widget buildAttachedFiles(ChatViewModel viewModel, Message message) {
    final images = message.files.where(_isImageFile).toList();
    final files = message.files.where((f) => !_isImageFile(f)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: images
                  .map((f) => _buildMessageImageThumb(viewModel, f))
                  .toList(),
            ),
          ),
        if (files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: files
                  .map((file) => Chip(
                        avatar: Icon(_attachedFileIcon(file), size: 16),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_attachedFileDetail(file).isNotEmpty)
                                Text(
                                  _attachedFileDetail(file),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  IconData _attachedFileIcon(ChatFile file) {
    if (file.isKnowledgeCollection) return Icons.library_books_outlined;
    if (file.isKnowledgeFile) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String _attachedFileDetail(ChatFile file) {
    if (file.isKnowledgeCollection) return 'Knowledge collection';
    if (file.isKnowledgeFile) return 'Knowledge file';
    if (file.size > 0) return _formatFileSize(file.size);
    return '';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }

  Widget _buildMessageImageThumb(ChatViewModel viewModel, ChatFile file) {
    final bytes = viewModel.pendingImageBytes[file.id];
    return GestureDetector(
      onTap: bytes != null ? () => _showFullImage(bytes) : null,
      child: Container(
        width: 160,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade300,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: bytes != null
              ? Image.memory(bytes, fit: BoxFit.cover)
              : const Center(
                  child:
                      Icon(Icons.image_outlined, size: 36, color: Colors.grey),
                ),
        ),
      ),
    );
  }

  void _showFullImage(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.memory(bytes),
          ),
        ),
      ),
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
      tooltip: viewModel.isMessageCopying(message) ? 'Copied' : 'Copy message',
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
    final isSubmitting = viewModel.isSubmittingFeedbackFor(message);
    final liked = message.feedbackRating == 1;
    final disliked = message.feedbackRating == -1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildCopyIconButton(viewModel, message),
        if (isSubmitting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else ...[
          IconButton(
            tooltip: liked ? 'Edit positive feedback' : 'Good response',
            icon: Icon(
              liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
              size: 18,
              color: liked ? Colors.green.shade700 : null,
            ),
            onPressed: () async {
              await showResponseFeedbackSheet(
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
            tooltip: disliked ? 'Edit negative feedback' : 'Bad response',
            icon: Icon(
              disliked
                  ? Icons.thumb_down_alt_rounded
                  : Icons.thumb_down_alt_outlined,
              size: 18,
              color: disliked ? Colors.red.shade700 : null,
            ),
            onPressed: () async {
              await showResponseFeedbackSheet(
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
        if (message.feedbackId != null)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Tooltip(
              message: 'Feedback submitted',
              child: Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ),
      ],
    );
  }

  Widget buildAssistantMessage(
      ChatViewModel viewModel, Message message, int messageIndex) {
    final isLast =
        viewModel.messages.isNotEmpty && viewModel.messages.last == message;
    final isStreaming = isLast && viewModel.isSendingMessage;
    final statusWidget = buildToolStatus(message, isStreaming: isStreaming);
    final citations = ChatCitationParser.parse(
      markdown: message.content,
      statusHistory: message.statusHistory,
      sources: message.sources,
    );

    if (message.content.isEmpty && statusWidget == null) {
      return Container();
    }

    final maxContentWidth = min(MediaQuery.of(context).size.width, 820.0);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            if (statusWidget != null) statusWidget,
            if (message.content.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: AiMarkdownMessage(
                  markdown: message.content,
                  citations: citations,
                ),
              ),
            if (!isStreaming && citations.isNotEmpty)
              ChatSourcesButton(citations: citations),
            if (!isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: buildAssistantMessageActions(
                  viewModel,
                  message,
                  messageIndex,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? buildToolStatus(
    Message message, {
    required bool isStreaming,
  }) {
    final visibleStatuses =
        message.statusHistory.where((status) => !status.hidden).toList();
    if (visibleStatuses.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ChatProgressIndicator(
        statuses: visibleStatuses,
        isStreaming: isStreaming,
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
        return const ChatThinkingIndicator();
      }
      return Container();
    } else if (snapshot.hasError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          const Text('Response interrupted'),
        ],
      );
    }
    return Container();
  }
}
