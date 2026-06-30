import 'dart:math';
import 'dart:typed_data';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';
import 'package:ui_components/blinking_text.dart';

import '../viewModels/chat_view_model.dart';
import 'ai_markdown_message.dart';

class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    final messageWidgets = messagesList(context, chatViewModel);

    return Stack(
      children: [
        ListView.separated(
          controller: chatViewModel.scrollController,
          padding: EdgeInsets.fromLTRB(
              context.horizontalSidePaddingForContentWidth,
              20,
              context.horizontalSidePaddingForContentWidth,
              20 + 100),
          itemCount: messageWidgets.length,
          itemBuilder: (context, index) {
            return messageWidgets[index];
          },
          separatorBuilder: (context, index) {
            return const SizedBox(height: 16);
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
        if (message.files.isNotEmpty) buildAttachedFiles(viewModel, message),
        if (message.content.isNotEmpty)
          IntrinsicWidth(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: min(
                  680,
                  max(280, MediaQuery.of(context).size.width * 0.72),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: SelectableText(
                message.content,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
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
              await _showResponseFeedbackSheet(
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
              await _showResponseFeedbackSheet(
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

  Future<void> _showResponseFeedbackSheet({
    required BuildContext context,
    required ChatViewModel viewModel,
    required Message message,
    required bool initialIsGood,
    required int messageIndex,
  }) async {
    if (viewModel.selectedChat == null) return;
    final BuildContext pageContext = context;

    const positiveReasons = [
      'Accurate information',
      'Followed instructions',
      'Clear explanation',
      'Useful detail',
      'Good structure',
      'Creative answer',
      'Other',
    ];
    const negativeReasons = [
      "Don't like the style",
      'Too verbose',
      'Not helpful',
      'Not factually correct',
      "Didn't follow instructions",
      "Refused incorrectly",
      'Other',
    ];

    final int initialRating = initialIsGood ? 10 : 1;
    final existingFeedbackMatches =
        message.feedbackRating == (initialIsGood ? 1 : -1);

    int rating = existingFeedbackMatches
        ? message.feedbackDetailsRating ?? initialRating
        : initialRating;
    final selectedReasons = existingFeedbackMatches
        ? <String>{...message.feedbackReasons}
        : <String>{};
    final commentController = TextEditingController(
        text: existingFeedbackMatches ? message.feedbackComment ?? '' : '');
    String? localError;
    bool isSaving = false;
    bool isGood = initialIsGood;

    final bool? saved = await showModalBottomSheet<bool>(
      context: pageContext,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (statefulContext, setState) {
            final activeReasons = isGood ? positiveReasons : negativeReasons;
            final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Rate response',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(sheetContext).pop(false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.thumb_up_alt_outlined),
                            label: Text('Good'),
                          ),
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.thumb_down_alt_outlined),
                            label: Text('Bad'),
                          ),
                        ],
                        selected: {isGood},
                        onSelectionChanged: isSaving
                            ? null
                            : (values) {
                                setState(() {
                                  isGood = values.first;
                                  rating = isGood ? 10 : 1;
                                  selectedReasons.clear();
                                  localError = null;
                                });
                              },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Quality score',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(10, (index) {
                          final value = index + 1;
                          final selected = value == rating;
                          return ChoiceChip(
                            label: Text('$value'),
                            selected: selected,
                            onSelected: isSaving
                                ? null
                                : (_) {
                                    setState(() {
                                      rating = value;
                                      localError = null;
                                    });
                                  },
                            selectedColor: Colors.black,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1 - Poor',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            '10 - Excellent',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Reason',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: activeReasons.map((reason) {
                          final selected = selectedReasons.contains(reason);
                          return FilterChip(
                            label: Text(reason),
                            selected: selected,
                            onSelected: isSaving
                                ? null
                                : (_) {
                                    setState(() {
                                      if (selected) {
                                        selectedReasons.remove(reason);
                                      } else {
                                        selectedReasons.add(reason);
                                      }
                                      localError = null;
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: commentController,
                        enabled: !isSaving,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Optional details',
                          filled: true,
                          fillColor: Colors.grey.shade100,
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
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (selectedReasons.isEmpty) {
                                    setState(() {
                                      localError =
                                          'Please select at least one reason.';
                                    });
                                    return;
                                  }

                                  setState(() {
                                    isSaving = true;
                                    localError = null;
                                  });

                                  final commentText =
                                      commentController.text.trim().isNotEmpty
                                          ? commentController.text.trim()
                                          : null;
                                  final ok =
                                      await viewModel.submitMessageFeedback(
                                    message: message,
                                    goodBadRating: isGood ? 1 : -1,
                                    detailsRating: rating,
                                    reasons: selectedReasons.toList(),
                                    comment: commentText,
                                    messageIndex: messageIndex + 1,
                                  );

                                  if (!sheetContext.mounted) return;
                                  if (ok) {
                                    Navigator.of(sheetContext).pop(true);
                                  } else {
                                    setState(() {
                                      isSaving = false;
                                      localError =
                                          'Failed to submit feedback. Please try again.';
                                    });
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(message.feedbackId == null
                                  ? 'Submit feedback'
                                  : 'Update feedback'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true && pageContext.mounted) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(
          content: Text('Feedback saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    commentController.dispose();
  }

  Widget buildAssistantMessage(
      ChatViewModel viewModel, Message message, int messageIndex) {
    final isLast =
        viewModel.messages.isNotEmpty && viewModel.messages.last == message;
    final isStreaming = isLast && viewModel.isSendingMessage;
    final statusWidget = buildToolStatus(message);

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
                child: AiMarkdownMessage(markdown: message.content),
              ),
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

  Widget? buildToolStatus(Message message) {
    final visibleStatuses =
        message.statusHistory.where((status) => !status.hidden).toList();
    if (visibleStatuses.isEmpty) return null;

    final status = visibleStatuses.last;
    final description = _toolStatusDescription(status);
    if (description.isEmpty) return null;

    final isRunning = status.done == false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRunning)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Colors.grey.shade600,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _toolStatusDescription(ToolStatus status) {
    if (status.action == 'knowledge_search' && status.query.isNotEmpty) {
      return 'Searching Knowledge for "${status.query}"';
    }

    var description = status.description;
    if (description.contains('{{searchQuery}}')) {
      description = description.replaceAll('{{searchQuery}}', status.query);
    }
    if (description.contains('{{count}}')) {
      description =
          description.replaceAll('{{count}}', '${status.urls.length}');
    }
    if (description.isNotEmpty) return description;
    if (status.query.isNotEmpty) return 'Searching "${status.query}"';
    if (status.action.isNotEmpty) return status.action.replaceAll('_', ' ');
    return '';
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
          style: const TextStyle(fontSize: 15.0),
        );
      }
      return Container();
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    return Container();
  }
}
