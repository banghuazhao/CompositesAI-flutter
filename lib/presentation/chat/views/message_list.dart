import 'dart:math';
import 'dart:typed_data';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../model/chat_citation.dart';
import '../viewModels/chat_view_model.dart';
import 'ai_markdown_message.dart';
import 'chat_answer_collapse_state.dart';
import 'chat_message_timestamp.dart';
import 'chat_progress_indicator.dart';
import 'chat_use_as_draft_button.dart';
import 'response_feedback_sheet.dart';

class MessageList extends StatefulWidget {
  final double bottomContentPadding;
  final VoidCallback? onBeforeReuse;
  final VoidCallback? onDraftApplied;

  const MessageList({
    super.key,
    required this.bottomContentPadding,
    this.onBeforeReuse,
    this.onDraftApplied,
  });

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final _answerCollapse = ChatAnswerCollapseState();
  ChatViewModel? _observedModel;
  bool _rebuildScheduled = false;
  int _answerControlRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final model = context.read<ChatViewModel>();
    if (!identical(model, _observedModel)) {
      _stopObserving();
      _observedModel = model;
      _answerControlRevision++;
      if (!model.isDisposed) {
        model.addListener(_onConversationChanged);
        model.disposalListenable.addListener(_onConversationChanged);
      }
      _answerCollapse.clear();
    }
    _synchronizeAnswers(model);
  }

  Object _answerScope(ChatViewModel model) => (
        model,
        model.chatSessionKey,
        model.selectedChat?.id,
        model.chatSelectionRevision,
      );

  void _synchronizeAnswers(ChatViewModel model) {
    _answerCollapse.synchronize(
      scope: _answerScope(model),
      available:
          !model.isDisposed && model.isLoggedIn && !model.isLoadingMessages,
      messages: model.messages,
      streamingMessage: model.isSendingMessage && model.messages.isNotEmpty
          ? model.messages.last
          : null,
    );
  }

  void _onConversationChanged() {
    final model = _observedModel;
    if (model == null || !mounted) return;
    _answerControlRevision++;
    _synchronizeAnswers(model);
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_rebuildScheduled) return;
      _rebuildScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildScheduled = false;
        if (mounted) setState(() {});
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    } else {
      setState(() {});
    }
  }

  void _stopObserving() {
    _observedModel?.removeListener(_onConversationChanged);
    _observedModel?.disposalListenable.removeListener(_onConversationChanged);
    _observedModel = null;
  }

  @override
  void dispose() {
    _stopObserving();
    _answerCollapse.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = context.watch<ChatViewModel>();
    _synchronizeAnswers(chatViewModel);
    if (chatViewModel.isDisposed) return const SizedBox.shrink();
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
        if (message.content.isNotEmpty || message.files.isNotEmpty)
          buildMessageTimestamp(viewModel, message),
        buildMessageActions(viewModel, message),
      ],
    );
  }

  Widget buildMessageTimestamp(ChatViewModel viewModel, Message message) {
    return KeyedSubtree(
      // Retire any visible tooltip when its conversation/account is replaced,
      // including histories that reuse message IDs in another conversation.
      key: ValueKey((
        viewModel.chatSessionKey,
        viewModel.selectedChat?.id,
        message.id,
        message.timestamp,
      )),
      child: ChatMessageTimestamp(
        key: ValueKey('chat-message-time-${message.id}'),
        timestamp: message.timestamp,
      ),
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
                  .map(
                    (file) => Chip(
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
                    ),
                  )
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
    final strings = S.maybeOf(context);
    if (file.isKnowledgeCollection) {
      return strings?.Chat_knowledge_collection ?? 'Knowledge collection';
    }
    if (file.isKnowledgeFile)
      return strings?.Chat_knowledge_file ?? 'Knowledge file';
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
                  child: Icon(
                    Icons.image_outlined,
                    size: 36,
                    color: Colors.grey,
                  ),
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
          child: InteractiveViewer(child: Image.memory(bytes)),
        ),
      ),
    );
  }

  Widget buildMessageActions(ChatViewModel viewModel, Message message) {
    final isUnansweredLast = viewModel.messages.isNotEmpty &&
        viewModel.messages.last == message &&
        viewModel.canRegenerate;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isUnansweredLast)
          buildRegenerateButton(
            viewModel,
            label: S.maybeOf(context)?.Chat_get_response ?? 'Get response',
          ),
        buildCopyIconButton(viewModel, message),
        if (message.content.trim().isNotEmpty)
          ChatUseAsDraftButton(
            viewModel: viewModel,
            message: message,
            onBeforeUse: widget.onBeforeReuse,
            onApplied: widget.onDraftApplied,
          ),
      ],
    );
  }

  Widget buildRegenerateButton(ChatViewModel viewModel, {String? label}) {
    final tooltip =
        S.maybeOf(context)?.Chat_regenerate_response ?? 'Regenerate response';
    final onPressed = viewModel.canRegenerate
        ? () => viewModel.regenerateLastResponse()
        : null;
    if (label != null) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: Text(label),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
        minimumSize: WidgetStateProperty.all(Size.zero),
      ),
    );
  }

  Widget buildCopyIconButton(ChatViewModel viewModel, Message message) {
    return IconButton(
      tooltip: viewModel.isMessageCopying(message)
          ? S.maybeOf(context)?.Chat_copied ?? 'Copied'
          : S.maybeOf(context)?.Chat_copy_message ?? 'Copy message',
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
    ChatViewModel viewModel,
    Message message,
    int messageIndex,
  ) {
    final isSubmitting = viewModel.isSubmittingFeedbackFor(message);
    final liked = message.feedbackRating == 1;
    final disliked = message.feedbackRating == -1;
    final isLast =
        viewModel.messages.isNotEmpty && viewModel.messages.last == message;

    final strings = S.maybeOf(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        buildCopyIconButton(viewModel, message),
        if (isLast && viewModel.canRegenerate) buildRegenerateButton(viewModel),
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
            tooltip: liked
                ? strings?.Chat_edit_positive_feedback ??
                    'Edit positive feedback'
                : strings?.Chat_good_response ?? 'Good response',
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
            tooltip: disliked
                ? strings?.Chat_edit_negative_feedback ??
                    'Edit negative feedback'
                : strings?.Chat_bad_response ?? 'Bad response',
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
              message: strings?.Chat_feedback_submitted ?? 'Feedback submitted',
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
    ChatViewModel viewModel,
    Message message,
    int messageIndex,
  ) {
    final isLast =
        viewModel.messages.isNotEmpty && viewModel.messages.last == message;
    final isStreaming = isLast && viewModel.isSendingMessage;
    // Loaded legacy messages may omit `done`; use the same terminal-display
    // policy as message actions rather than hiding folding from those histories.
    final canFold = !viewModel.isDisposed &&
        viewModel.isLoggedIn &&
        !viewModel.isLoadingMessages &&
        !isStreaming &&
        ChatAnswerCollapseState.isLongAnswer(message);
    final collapsed = canFold && _answerCollapse.isCollapsed(message);
    final activity = ChatResponseActivity(
      message: message,
      isStreaming: isStreaming,
    );
    final citations = ChatCitationParser.parse(
      markdown: message.content,
      statusHistory: message.statusHistory,
      sources: message.sources,
    );

    final hasVisibleActivity = isStreaming ||
        message.statusHistory.any(
          (status) =>
              !status.hidden &&
              (status.action == 'response_interrupted' ||
                  status.action == 'response_stopped'),
        );
    if (message.content.isEmpty && !hasVisibleActivity) {
      return const SizedBox.shrink();
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
            if (hasVisibleActivity) activity,
            if (canFold)
              buildAnswerToggle(viewModel, message, collapsed: collapsed),
            if (message.content.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: collapsed
                    ? Text(
                        '${message.content.characters.take(280).toString().replaceAll(RegExp(r'\s+'), ' ').trim()}…',
                        key: ValueKey('chat-answer-preview-${message.id}'),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              height: 1.5,
                            ),
                      )
                    : AiMarkdownMessage(
                        markdown: message.content,
                        citations: citations,
                      ),
              ),
            if (message.content.isNotEmpty)
              buildMessageTimestamp(viewModel, message),
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

  Widget buildAnswerToggle(
    ChatViewModel model,
    Message message, {
    required bool collapsed,
  }) {
    final scope = _answerScope(model);
    final revision = _answerControlRevision;
    final content = message.content;
    final strings = S.maybeOf(context);
    final label = collapsed
        ? strings?.Chat_expand_answer ?? 'Expand answer'
        : strings?.Chat_collapse_answer ?? 'Collapse answer';

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        expanded: !collapsed,
        child: TextButton.icon(
          key: ValueKey('chat-answer-toggle-${message.id}'),
          onPressed: () {
            if (!mounted ||
                !identical(model, _observedModel) ||
                model.isDisposed ||
                !model.isLoggedIn ||
                model.isLoadingMessages ||
                _answerControlRevision != revision ||
                _answerScope(model) != scope ||
                ModalRoute.of(context)?.isCurrent != true ||
                !model.messages.any((current) => identical(current, message)) ||
                message.content != content ||
                (model.isSendingMessage &&
                    identical(model.messages.lastOrNull, message)) ||
                !ChatAnswerCollapseState.isLongAnswer(message)) {
              return;
            }
            setState(() => _answerCollapse.toggle(message));
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          icon: Icon(collapsed ? Icons.expand_more : Icons.expand_less),
          label: Text(label, textAlign: TextAlign.start),
        ),
      ),
    );
  }

  StreamBuilder<Message> messageStream(ChatViewModel viewModel) {
    return StreamBuilder<Message>(
      stream: viewModel.threadResponseController.stream,
      builder: (context, snapshot) {
        return Align(
          alignment: Alignment.centerLeft,
          child: streamWidget(snapshot, viewModel),
        );
      },
    );
  }

  Widget streamWidget(
    AsyncSnapshot<Message> snapshot,
    ChatViewModel viewModel,
  ) {
    // Thinking/knowledge status is rendered on the assistant message itself.
    if (snapshot.hasError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            S.maybeOf(context)?.Chat_response_interrupted ??
                'Response interrupted',
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
