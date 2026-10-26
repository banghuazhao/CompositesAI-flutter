import 'dart:typed_data';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../model/chat_citation.dart';
import '../viewModels/chat_view_model.dart';
import 'ai_markdown_message.dart';
import 'chat_answer_collapse_state.dart';
import 'chat_copy_exchange_button.dart';
import 'chat_layout.dart';
import 'chat_message_timestamp.dart';
import 'chat_progress_indicator.dart';
import 'chat_reading_style.dart';
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

class _MessageActionsMenu extends StatefulWidget {
  const _MessageActionsMenu({
    super.key,
    required this.messageId,
    required this.enabled,
    required this.isCurrent,
    required this.items,
  });

  final String messageId;
  final bool enabled;
  final bool Function() isCurrent;
  final List<Widget> Function(MenuController) items;

  @override
  State<_MessageActionsMenu> createState() => _MessageActionsMenuState();
}

class _MessageActionsMenuState extends State<_MessageActionsMenu> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final strings = S.maybeOf(context);
    final width =
        (MediaQuery.sizeOf(context).width - 40).clamp(160.0, 360.0).toDouble();
    return MenuAnchor(
      crossAxisUnconstrained: false,
      controller: _controller,
      consumeOutsideTap: true,
      style: MenuStyle(
        maximumSize: WidgetStatePropertyAll(Size(width, double.infinity)),
      ),
      menuChildren: widget.items(_controller),
      builder: (context, controller, _) => Tooltip(
        message: strings?.Chat_more_actions ?? 'More actions',
        child: TextButton.icon(
          key: ValueKey('chat-message-more-${widget.messageId}'),
          onPressed: widget.enabled
              ? () {
                  if (!mounted || !widget.isCurrent()) return;
                  controller.isOpen ? controller.close() : controller.open();
                }
              : null,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          icon: const Icon(Icons.more_horiz, size: ChatReadingStyle.iconSize),
          label: Text(strings?.Chat_more ?? 'More'),
        ),
      ),
    );
  }
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
        ChatLayout.horizontalPaddingFor(MediaQuery.sizeOf(context).width),
        20,
        ChatLayout.horizontalPaddingFor(MediaQuery.sizeOf(context).width),
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
                maxWidth: ChatLayout.contentWidthFor(
                    MediaQuery.sizeOf(context).width),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(ChatReadingStyle.messageRadius),
                  topRight: Radius.circular(ChatReadingStyle.messageRadius),
                  bottomLeft: Radius.circular(ChatReadingStyle.messageRadius),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: SelectableText(
                message.content,
                style: ChatReadingStyle.body(context,
                    color: scheme.onSecondaryContainer),
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
                                style: ChatReadingStyle.metadata(context),
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
    if (file.isKnowledgeFile) {
      return strings?.Chat_knowledge_file ?? 'Knowledge file';
    }
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
          borderRadius: BorderRadius.circular(ChatReadingStyle.codeRadius),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ChatReadingStyle.codeRadius),
          child: bytes != null
              ? Image.memory(bytes, fit: BoxFit.cover)
              : Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  bool _messageActionCurrent(
    ChatViewModel model,
    Message message,
    Object scope,
    int revision,
    String content,
    int index,
  ) =>
      mounted &&
      identical(model, _observedModel) &&
      !model.isDisposed &&
      model.isLoggedIn &&
      !model.isLoadingMessages &&
      _answerScope(model) == scope &&
      _answerControlRevision == revision &&
      ModalRoute.of(context)?.isCurrent == true &&
      message.content == content &&
      index >= 0 &&
      index < model.messages.length &&
      identical(model.messages[index], message);

  Widget _moreMenu(
    ChatViewModel model,
    Message message,
    List<Widget> Function(MenuController controller) items,
  ) {
    final scope = _answerScope(model);
    final revision = _answerControlRevision;
    final content = message.content;
    final index = model.messages.indexWhere((item) => identical(item, message));
    return _MessageActionsMenu(
      key: ValueKey((_answerScope(model), message, message.content)),
      messageId: message.id,
      enabled:
          !model.isDisposed && model.isLoggedIn && !model.isLoadingMessages,
      isCurrent: () => _messageActionCurrent(
          model, message, scope, revision, content, index),
      items: items,
    );
  }

  Widget buildMessageActions(ChatViewModel viewModel, Message message) {
    final isUnansweredLast = viewModel.messages.isNotEmpty &&
        identical(viewModel.messages.last, message) &&
        viewModel.canRegenerate;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        buildCopyIconButton(viewModel, message),
        if (isUnansweredLast || message.content.trim().isNotEmpty)
          _moreMenu(
              viewModel,
              message,
              (controller) => [
                    if (isUnansweredLast)
                      buildRegenerateMenuItem(viewModel, message,
                          label: S.maybeOf(context)?.Chat_get_response ??
                              'Get response'),
                    if (message.content.trim().isNotEmpty)
                      ChatUseAsDraftButton(
                        key: ValueKey(('reuse', message)),
                        viewModel: viewModel,
                        message: message,
                        menuItem: true,
                        onBeforeUse: widget.onBeforeReuse,
                        onApplied: () {
                          controller.close();
                          widget.onDraftApplied?.call();
                        },
                      ),
                  ]),
      ],
    );
  }

  Widget buildRegenerateMenuItem(ChatViewModel model, Message message,
      {String? label}) {
    final scope = _answerScope(model);
    final revision = _answerControlRevision;
    final content = message.content;
    final index = model.messages.indexWhere((item) => identical(item, message));
    return MenuItemButton(
      key: ValueKey('chat-regenerate-${message.id}'),
      onPressed: model.canRegenerate
          ? () {
              if (!_messageActionCurrent(
                      model, message, scope, revision, content, index) ||
                  !model.canRegenerate ||
                  !identical(model.messages.lastOrNull, message)) {
                return;
              }
              model.regenerateLastResponse();
            }
          : null,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(48, 48)),
      ),
      leadingIcon:
          const Icon(Icons.refresh_rounded, size: ChatReadingStyle.iconSize),
      child: Text(label ??
          S.maybeOf(context)?.Chat_regenerate_response ??
          'Regenerate response'),
    );
  }

  Widget buildCopyIconButton(ChatViewModel model, Message message) {
    final scope = _answerScope(model);
    final revision = _answerControlRevision;
    final content = message.content;
    final index = model.messages.indexWhere((item) => identical(item, message));
    return IconButton(
      tooltip: model.isMessageCopying(message)
          ? S.maybeOf(context)?.Chat_copied ?? 'Copied'
          : S.maybeOf(context)?.Chat_copy_message ?? 'Copy message',
      icon: Icon(model.isMessageCopying(message) ? Icons.check : Icons.copy,
          size: ChatReadingStyle.iconSize),
      onPressed: model.isMessageCopying(message)
          ? null
          : () {
              if (_messageActionCurrent(
                  model, message, scope, revision, content, index)) {
                model.copyMessage(message);
              }
            },
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }

  Widget _feedbackMenuItem(
    ChatViewModel model,
    Message message,
    int messageIndex, {
    required bool good,
  }) {
    final scope = _answerScope(model);
    final revision = _answerControlRevision;
    final content = message.content;
    final strings = S.maybeOf(context);
    final selected = message.feedbackRating == (good ? 1 : -1);
    final label = good
        ? selected
            ? strings?.Chat_edit_positive_feedback ?? 'Edit positive feedback'
            : strings?.Chat_good_response ?? 'Good response'
        : selected
            ? strings?.Chat_edit_negative_feedback ?? 'Edit negative feedback'
            : strings?.Chat_bad_response ?? 'Bad response';
    return MenuItemButton(
      key: ValueKey(
          'chat-feedback-${good ? 'positive' : 'negative'}-${message.id}'),
      onPressed: model.isSubmittingFeedbackFor(message)
          ? null
          : () async {
              if (!_messageActionCurrent(
                  model, message, scope, revision, content, messageIndex)) {
                return;
              }
              await showResponseFeedbackSheet(
                context: context,
                viewModel: model,
                message: message,
                initialIsGood: good,
                messageIndex: messageIndex,
              );
            },
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(48, 48)),
      ),
      leadingIcon: Icon(
        good
            ? selected
                ? Icons.thumb_up_alt_rounded
                : Icons.thumb_up_alt_outlined
            : selected
                ? Icons.thumb_down_alt_rounded
                : Icons.thumb_down_alt_outlined,
        size: ChatReadingStyle.iconSize,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      child: Text(label),
    );
  }

  Widget buildAssistantMessageActions(
    ChatViewModel viewModel,
    Message message,
    int messageIndex,
  ) {
    final isSubmitting = viewModel.isSubmittingFeedbackFor(message);
    final isLast = viewModel.messages.isNotEmpty &&
        identical(viewModel.messages.last, message);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        buildCopyIconButton(viewModel, message),
        _moreMenu(
            viewModel,
            message,
            (_) => [
                  ChatCopyExchangeButton(
                    key: ValueKey(('exchange', message)),
                    viewModel: viewModel,
                    answer: message,
                    menuItem: true,
                  ),
                  if (isLast && viewModel.canRegenerate)
                    buildRegenerateMenuItem(viewModel, message),
                  _feedbackMenuItem(viewModel, message, messageIndex,
                      good: true),
                  _feedbackMenuItem(viewModel, message, messageIndex,
                      good: false),
                ]),
        if (isSubmitting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox.square(
              dimension: ChatReadingStyle.iconSize,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (message.feedbackId != null)
          Tooltip(
            message: S.maybeOf(context)?.Chat_feedback_submitted ??
                'Feedback submitted',
            child: Icon(Icons.check_circle_outline_rounded,
                size: ChatReadingStyle.iconSize,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
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

    final maxContentWidth =
        ChatLayout.contentWidthFor(MediaQuery.sizeOf(context).width);

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
                        style: ChatReadingStyle.body(context),
                      )
                    : AiMarkdownMessage(
                        key: ValueKey((_answerScope(viewModel), message)),
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
