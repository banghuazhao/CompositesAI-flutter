import 'dart:async';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/chat_knowledge.dart';
import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/util/app_interactions.dart';
import 'package:swiftcomp/util/app_theme.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

import '../../auth/login_page.dart';
import '../../conponents/base64-image.dart';
import '../../settings/views/settings_page.dart';
import '../../tools/page/tool_page.dart';
import '../../../util/export/file_share.dart';
import '../model/chat_export.dart';
import '../viewModels/chat_view_model.dart';
import 'chat_error_snack_bar.dart';
import 'chat_expanded_composer.dart';
import 'chat_header_title.dart';
import 'message_list.dart';
import 'chat_list.dart';
import 'chat_welcome_view.dart';
import 'knowledge_document_page.dart';
import 'chat_latest_button.dart';
import 'chat_search_sheet.dart';
import 'pending_image_attachment.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _KnowledgePickerCard extends StatelessWidget {
  final ChatKnowledge knowledge;
  final ChatViewModel viewModel;

  const _KnowledgePickerCard({
    required this.knowledge,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<ChatViewModel>(
      builder: (context, chat, _) {
        final collectionSelected = chat.isKnowledgeSelected(knowledge.id);
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.library_books_outlined),
                  title: Text(
                    knowledge.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    knowledge.description.isNotEmpty
                        ? knowledge.description
                        : (S
                                .maybeOf(context)
                                ?.Chat_file_count(knowledge.files.length) ??
                            '${knowledge.files.length} files'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: collectionSelected
                      ? Icon(Icons.check_rounded, color: scheme.primary)
                      : null,
                  onTap: () {
                    AppHaptics.light();
                    viewModel.toggleKnowledgeCollection(knowledge);
                  },
                ),
                if (knowledge.files.isNotEmpty) ...[
                  Divider(height: 1, indent: 56, endIndent: 16),
                  ...knowledge.files.map((file) {
                    final selected = chat.isKnowledgeSelected(file.id);
                    final unavailable = !file.isSelectableKnowledgeFile;
                    final statusText = file.hasProcessingFailed
                        ? file.processingError.isNotEmpty
                            ? (S
                                    .maybeOf(context)
                                    ?.Chat_processing_failed_detail(
                                      file.processingError,
                                    ) ??
                                'Processing failed: ${file.processingError}')
                            : S.maybeOf(context)?.Chat_processing_failed ??
                                'Processing failed'
                        : file.isProcessing
                            ? S.maybeOf(context)?.Chat_processing_document ??
                                'Processing document…'
                            : null;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(
                        left: 56,
                        right: 16,
                      ),
                      leading: Icon(
                        file.hasProcessingFailed
                            ? Icons.error_outline_rounded
                            : file.isProcessing
                                ? Icons.hourglass_empty_rounded
                                : Icons.description_outlined,
                        size: 20,
                        color: file.hasProcessingFailed ? scheme.error : null,
                      ),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: statusText == null
                          ? null
                          : Text(
                              statusText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: file.hasProcessingFailed
                                  ? TextStyle(color: scheme.error)
                                  : null,
                            ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip:
                                S.maybeOf(context)?.Chat_read_file(file.name) ??
                                    'Read ${file.name}',
                            icon: const Icon(Icons.menu_book_outlined),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => KnowledgeDocumentPage(
                                    file: file,
                                    useCase: sl<ChatUseCase>(),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (selected)
                            Icon(Icons.check_rounded, color: scheme.primary),
                        ],
                      ),
                      onTap: unavailable
                          ? null
                          : () {
                              AppHaptics.light();
                              viewModel.toggleKnowledgeFile(file);
                            },
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _ExportFormat { markdown, pdf }

class _ChatScreenState extends State<ChatScreen>
    with
        AutomaticKeepAliveClientMixin,
        RouteAware,
        WidgetsBindingObserver,
        TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  TextEditingController get textController => viewModel.composerTextController;
  final FocusNode focusNode = FocusNode();
  final GlobalKey _inputBarKey = GlobalKey();
  double _inputBarHeight = 120;
  int? _lastPresentedErrorId;

  late ChatViewModel viewModel;

  // Voice input
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _startingVoiceInput = false;
  int _voiceInputRevision = 0;
  Object? _voiceInputSession;
  String? _voiceInputConversation;
  int? _voiceComposerReplacementRevision;
  Future<bool>? _voiceInitialization;
  Future<void>? _voiceStopping;
  SpeechErrorListener? _voiceErrorListener;
  SpeechStatusListener? _voiceStatusListener;
  bool _isExporting = false;
  bool _isSearchOpen = false;
  bool _isComposerExpanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    viewModel = Provider.of<ChatViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await viewModel.fetchAuthSessionNew();
      if (mounted && viewModel.isLoggedIn) {
        await Future.wait([viewModel.fetchChats(), viewModel.fetchTools()]);
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    viewModel.addListener(_onChatContextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    viewModel.removeListener(_onChatContextChanged);
    _voiceInputRevision++;
    if (identical(_speech.errorListener, _voiceErrorListener)) {
      _speech.errorListener = null;
    }
    if (identical(_speech.statusListener, _voiceStatusListener)) {
      _speech.statusListener = null;
    }
    focusNode.dispose();
    _pulseController.dispose();
    _speech.cancel().catchError((Object error) {
      debugPrint('Stopping voice input failed: $error');
    });
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!mounted ||
        viewModel.isDisposed ||
        !viewModel.isLoggedIn ||
        _isComposerExpanded ||
        ModalRoute.of(context)?.isCurrent != true ||
        _startingVoiceInput ||
        _isListening) {
      return;
    }
    final revision = ++_voiceInputRevision;
    _voiceInputSession = viewModel.chatSessionKey;
    _voiceInputConversation = viewModel.selectedChat?.id;
    _voiceComposerReplacementRevision = viewModel.composerReplacementRevision;
    _startingVoiceInput = true;
    void onError(Object _) {
      if (!_isCurrentVoiceInput(revision)) return;
      _invalidateVoiceInput();
      _showVoiceInputError();
    }

    void onStatus(String status) {
      if (!_isCurrentVoiceInput(revision)) return;
      if (status == SpeechToText.doneStatus) {
        // The plugin keeps its pause timer after a native done event. Retire
        // it before a new attempt can replace that timer's handle.
        _invalidateVoiceInput();
      } else if (status == SpeechToText.notListeningStatus) {
        _resetVoiceInput();
      }
    }

    _voiceErrorListener = onError;
    _voiceStatusListener = onStatus;
    Future<bool>? initialization;
    try {
      // A native Stop may emit notListening before its Future finishes. Wait
      // for it to finish setting up the old final-result timer before a new
      // listen cancels that timer and starts its own recognition session.
      final stopping = _voiceStopping;
      if (stopping != null) {
        try {
          await stopping;
        } catch (_) {
          // The originating Stop reports its own platform failure.
        }
        if (!mounted || !_isCurrentVoiceInput(revision)) return;
      }
      initialization = _voiceInitialization ??= _speech.initialize(
        onError: onError,
        onStatus: onStatus,
      );
      final available = await initialization;
      if (!mounted || !_isCurrentVoiceInput(revision)) return;
      // The plugin caches successful initialization and retains its old
      // callbacks. Refresh them for every recognition attempt, including when
      // this attempt reused an initialization that began in another chat.
      _speech.errorListener = onError;
      _speech.statusListener = onStatus;
      if (!available) {
        _invalidateVoiceInput();
        _showVoiceInputError();
        return;
      }
      setState(() => _isListening = true);
      if (!MediaQuery.disableAnimationsOf(context)) {
        _pulseController.repeat(reverse: true);
      }
      await _speech.listen(
        onResult: (result) {
          if (!_isCurrentVoiceInput(revision)) return;
          textController.text = result.recognizedWords;
          textController.selection = TextSelection.fromPosition(
            TextPosition(offset: textController.text.length),
          );
          setState(() {});
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
        ),
      );
    } catch (error) {
      if (!_isCurrentVoiceInput(revision)) return;
      debugPrint('Voice input failed: $error');
      _resetVoiceInput();
      _showVoiceInputError();
    } finally {
      if (identical(_voiceInitialization, initialization)) {
        _voiceInitialization = null;
      }
      if (revision == _voiceInputRevision) _startingVoiceInput = false;
    }
  }

  bool _isCurrentVoiceInput(int revision) =>
      mounted &&
      !viewModel.isDisposed &&
      revision == _voiceInputRevision &&
      viewModel.isLoggedIn &&
      _voiceInputSession == viewModel.chatSessionKey &&
      _voiceInputConversation == viewModel.selectedChat?.id &&
      _voiceComposerReplacementRevision ==
          viewModel.composerReplacementRevision;

  void _onChatContextChanged() {
    // A recognizer may report notListening before its final result. Keep
    // tracking that attempt until it is invalidated, even after its UI stops.
    if (_voiceInputSession != null &&
        !_isCurrentVoiceInput(_voiceInputRevision)) {
      _invalidateVoiceInput();
    }
  }

  void _invalidateVoiceInput() {
    _voiceInputRevision++;
    _voiceInputSession = null;
    _voiceInputConversation = null;
    _voiceComposerReplacementRevision = null;
    _startingVoiceInput = false;
    _resetVoiceInput();
    _speech.cancel().catchError((Object error) {
      debugPrint('Stopping voice input failed: $error');
    });
  }

  Future<void> _stopListening() async {
    if (_voiceStopping != null) return;
    final revision = _voiceInputRevision;
    // Keep the current scope eligible for the recognizer's final result.
    // A chat change or a subsequent attempt invalidates that result instead.
    _startingVoiceInput = false;
    final stopping = _speech.stop();
    _voiceStopping = stopping;
    try {
      await stopping;
    } catch (error) {
      debugPrint('Stopping voice input failed: $error');
    } finally {
      if (identical(_voiceStopping, stopping)) _voiceStopping = null;
      if (_isCurrentVoiceInput(revision)) _resetVoiceInput();
    }
  }

  void _resetVoiceInput() {
    if (!mounted) return;
    _pulseController.stop();
    setState(() => _isListening = false);
  }

  void _showVoiceInputError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.maybeOf(context)?.Chat_voice_unavailable ??
              'Voice input is unavailable. Please check microphone permissions.',
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && viewModel.isLoggedIn) {
      viewModel.fetchChats();
      viewModel.fetchTools();
      if (viewModel.knowledgeBases.isNotEmpty) {
        viewModel.fetchKnowledgeBases();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ChatViewModel>(
      //Consumer widget dynamically rebuilds the UI whenever the ChatViewModel changes
      builder: (context, viewModel, _) {
        if (viewModel.isDisposed) return const SizedBox.shrink();
        if (viewModel.isLoggedIn) _scheduleInputBarMeasurement();

        final activeError = viewModel.activeError;
        if (activeError != null && activeError.id != _lastPresentedErrorId) {
          _lastPresentedErrorId = activeError.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || viewModel.activeError?.id != activeError.id) return;
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            final controller = messenger.showSnackBar(
              buildChatErrorSnackBar(
                context: context,
                notice: activeError,
                onRetry: activeError.canRetry
                    ? () {
                        viewModel.retryError(activeError.id);
                      }
                    : null,
              ),
            );
            controller.closed.whenComplete(() {
              if (mounted) viewModel.dismissError(activeError.id);
            });
          });
        }

        return Focus(
          autofocus: true,
          skipTraversal: true,
          includeSemantics: false,
          onKeyEvent: _handleChatKeyEvent,
          child: Scaffold(
            appBar: AppBar(
              title: ChatHeaderTitle(viewModel: viewModel),
              actionsPadding: const EdgeInsetsDirectional.only(end: 12),
              actions: [
                Builder(
                  builder: (context) {
                    if (!viewModel.isLoggedIn) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.manage_accounts),
                            tooltip:
                                S.maybeOf(context)?.Chat_sign_in ?? "Sign In",
                            onPressed: _openLogin,
                          ),
                          IconButton(
                            icon: const Icon(Icons.calculate_outlined),
                            tooltip: S
                                    .maybeOf(context)
                                    ?.Chat_composite_calculators ??
                                'Composite Calculators',
                            onPressed: _openCompositeCalculators,
                          ),
                        ],
                      );
                    } else {
                      // If the user is logged in, show profile info
                      return Row(
                        mainAxisSize: MainAxisSize.min, // Keep it compact
                        children: [
                          if (viewModel.selectedChat != null &&
                              !viewModel.isLoadingMessages &&
                              viewModel.messages.isNotEmpty)
                            IconButton(
                              key: const ValueKey('chat-find-in-chat'),
                              tooltip: S.maybeOf(context)?.Chat_find_in_chat ??
                                  'Find in chat',
                              icon: const Icon(Icons.search_rounded),
                              onPressed: _openChatSearch,
                            ),
                          if (viewModel.selectedChat != null &&
                              viewModel.messages.isNotEmpty)
                            _buildExportMenu(),
                          // Avatar or Profile Button
                          IconButton(
                            tooltip:
                                S.maybeOf(context)?.Chat_account_settings ??
                                    'Account & settings',
                            constraints: const BoxConstraints.tightFor(
                              width: 48,
                              height: 48,
                            ),
                            padding: const EdgeInsets.all(8),
                            onPressed: () async {
                              AppHaptics.light();
                              final result = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                              if (!context.mounted) return;
                              await viewModel.checkAuthStatus();
                              if (viewModel.isLoggedIn) {
                                await Future.wait([
                                  viewModel.fetchChats(),
                                  viewModel.fetchTools(),
                                ]);
                              }
                              if (result == "refresh" && mounted) {
                                setState(() {});
                              }
                            },
                            icon: SizedBox.square(
                              dimension: 32,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: (viewModel.user?.avatarUrl ?? '')
                                            .trim()
                                            .isNotEmpty
                                        ? ClipOval(
                                            child: Base64Image(
                                              viewModel.user!.avatarUrl!,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.account_circle,
                                            size: 32,
                                          ),
                                  ),
                                  if (viewModel.user?.isCompositeExpert == true)
                                    PositionedDirectional(
                                      end: -2,
                                      bottom: -2,
                                      child: Semantics(
                                        label: S
                                                .maybeOf(context)
                                                ?.Chat_composite_expert ??
                                            'Composite expert',
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.verified,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
            drawer: viewModel.isLoggedIn ? ChatList() : null,
            body: Stack(
              children: [
                if (viewModel.isLoggedIn) ...[
                  Positioned.fill(
                    child: viewModel.selectedChat != null
                        ? (viewModel.isLoadingMessages
                            ? const Center(child: CircularProgressIndicator())
                            : ChatLatestOverlay(
                                scrollController: viewModel.scrollController,
                                conversationId: viewModel.selectedChat?.id,
                                sessionToken: viewModel.chatSessionKey,
                                isConversationLoaded: viewModel.isLoggedIn &&
                                    !viewModel.isLoadingMessages,
                                bottomOffset: _inputBarHeight + 12,
                                child: MessageList(
                                  onBeforeReuse: () {
                                    if (_voiceInputSession != null) {
                                      _invalidateVoiceInput();
                                    }
                                  },
                                  onDraftApplied: () {
                                    if (mounted &&
                                        viewModel.isLoggedIn &&
                                        ModalRoute.of(context)?.isCurrent ==
                                            true) {
                                      focusNode.requestFocus();
                                    }
                                  },
                                  bottomContentPadding: _inputBarHeight + 20,
                                ),
                              ))
                        : ChatWelcomeView(
                            user: viewModel.user,
                            questions: viewModel.defaultQuestions,
                            bottomPadding: _inputBarHeight,
                            onQuestionSelected:
                                viewModel.onDefaultQuestionsTapped,
                          ),
                  ),
                  Positioned(left: 0, right: 0, bottom: 0, child: inputBar()),
                ] else
                  noLoginView(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportMenu() {
    return PopupMenuButton<_ExportFormat>(
      tooltip:
          S.maybeOf(context)?.Chat_export_conversation ?? 'Export conversation',
      icon: _isExporting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share_rounded),
      enabled: !_isExporting && !viewModel.isSendingMessage,
      onSelected: _exportConversation,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ExportFormat.markdown,
          child: ListTile(
            leading: const Icon(Icons.notes_rounded),
            title: Text(
              S.maybeOf(context)?.Chat_share_markdown ?? 'Share as Markdown',
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _ExportFormat.pdf,
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(S.maybeOf(context)?.Chat_share_pdf ?? 'Share as PDF'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _exportConversation(_ExportFormat format) async {
    final chat = viewModel.selectedChat;
    if (chat == null || _isExporting) return;
    final messages = List<Message>.from(viewModel.messages);
    final messenger = ScaffoldMessenger.of(context);
    final exportFailureMessage = S.maybeOf(context)?.Chat_export_failed ??
        'Could not export this conversation.';
    setState(() => _isExporting = true);
    try {
      switch (format) {
        case _ExportFormat.markdown:
          await FileShare.shareText(
            context,
            text: ChatExport.toMarkdown(title: chat.title, messages: messages),
            fileName: FileShare.safeFileName(chat.title, 'md'),
            mimeType: 'text/markdown',
            subject: chat.title,
          );
        case _ExportFormat.pdf:
          final bytes = await ChatExport.toPdf(
            title: chat.title,
            messages: messages,
          );
          if (!mounted) return;
          await FileShare.shareBytes(
            context,
            bytes: bytes,
            fileName: FileShare.safeFileName(chat.title, 'pdf'),
            mimeType: 'application/pdf',
            subject: chat.title,
          );
      }
    } catch (error) {
      debugPrint('Export conversation failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(exportFailureMessage)));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget inputBar() {
    final scheme = Theme.of(context).colorScheme;
    final hPad = context.horizontalSidePaddingForContentWidth;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      key: _inputBarKey,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        hPad,
        0,
        hPad,
        bottomInset > 0 ? bottomInset : 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPendingFiles(),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Focus(
                  canRequestFocus: false,
                  onKeyEvent: _handleComposerKeyEvent,
                  child: TextField(
                    key: const Key('chat-composer'),
                    controller: textController,
                    focusNode: focusNode,
                    readOnly: _isComposerExpanded,
                    canRequestFocus: !_isComposerExpanded,
                    selectAllOnFocus: false,
                    decoration: InputDecoration(
                      hintText: S.maybeOf(context)?.Chat_composer_hint ??
                          'Ask about composites engineering…',
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 8,
                    onChanged: (_) {
                      setState(() {});
                      _scheduleInputBarMeasurement();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildAttachButton(),
                    IconButton(
                      key: const Key('chat-expand-composer'),
                      tooltip: S.maybeOf(context)?.Chat_expand_composer ??
                          'Expand composer',
                      onPressed: _isComposerExpanded ? null : _expandComposer,
                      icon: const Icon(Icons.open_in_full_rounded),
                    ),
                    if (viewModel.isAdmin) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            if (viewModel.shouldShowModelSelector) ...[
                              Flexible(
                                child: viewModel.canSelectModels
                                    ? _buildModelPickerButton()
                                    : _buildModelLoadingChip(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const SizedBox(width: 8),
                    _buildRightButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleInputBarMeasurement() {
    if (!mounted || viewModel.isDisposed) return;
    final sessionKey = viewModel.chatSessionKey;
    final conversationId = viewModel.selectedChat?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          viewModel.isDisposed ||
          viewModel.chatSessionKey != sessionKey ||
          viewModel.selectedChat?.id != conversationId) {
        return;
      }
      final renderObject =
          _inputBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderObject == null || !renderObject.hasSize) return;

      final measuredHeight = renderObject.size.height;
      if ((measuredHeight - _inputBarHeight).abs() < 0.5) return;

      final shouldKeepLatestMessageVisible =
          viewModel.scrollController.hasClients &&
              viewModel.scrollController.position.extentAfter < 80;
      setState(() => _inputBarHeight = measuredHeight);

      if (shouldKeepLatestMessageVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted ||
              viewModel.isDisposed ||
              viewModel.chatSessionKey != sessionKey ||
              viewModel.selectedChat?.id != conversationId ||
              !viewModel.scrollController.hasClients) {
            return;
          }
          viewModel.scrollController.jumpTo(
            viewModel.scrollController.position.maxScrollExtent,
          );
        });
      }
    });
  }

  KeyEventResult _handleComposerKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }

    final keyboard = HardwareKeyboard.instance;
    final composing = textController.value.composing;
    if (keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed ||
        (composing.isValid && !composing.isCollapsed)) {
      return KeyEventResult.ignored;
    }

    unawaited(_sendComposerMessage());
    return KeyEventResult.handled;
  }

  bool get _canFindInChat =>
      mounted &&
      !viewModel.isDisposed &&
      viewModel.isLoggedIn &&
      viewModel.selectedChat != null &&
      !viewModel.isLoadingMessages &&
      viewModel.messages.isNotEmpty &&
      !_isSearchOpen &&
      !_isComposerExpanded &&
      ModalRoute.of(context)?.isCurrent == true;

  KeyEventResult _handleChatKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyF) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed ||
        keyboard.isAltPressed ||
        keyboard.isControlPressed == keyboard.isMetaPressed ||
        !_canFindInChat) {
      return KeyEventResult.ignored;
    }
    final composing = textController.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    unawaited(_openChatSearch());
    return KeyEventResult.handled;
  }

  Future<void> _openChatSearch() async {
    if (!_canFindInChat) return;
    _isSearchOpen = true;
    try {
      await showChatSearchSheet(context, viewModel);
    } finally {
      _isSearchOpen = false;
    }
  }

  Future<void> _expandComposer() async {
    if (!mounted ||
        viewModel.isDisposed ||
        !viewModel.isLoggedIn ||
        _isComposerExpanded ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    if (_voiceInputSession != null) _invalidateVoiceInput();
    final session = viewModel.chatSessionKey;
    final selection = viewModel.chatSelectionRevision;
    setState(() => _isComposerExpanded = true);
    try {
      await showExpandedChatComposer(context, viewModel);
    } finally {
      if (mounted) {
        setState(() => _isComposerExpanded = false);
        _scheduleInputBarMeasurement();
        if (!viewModel.isDisposed &&
            viewModel.isLoggedIn &&
            viewModel.chatSessionKey == session &&
            viewModel.chatSelectionRevision == selection &&
            ModalRoute.of(context)?.isCurrent == true) {
          // The inline field must first rebuild with canRequestFocus restored.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                !viewModel.isDisposed &&
                viewModel.isLoggedIn &&
                !_isComposerExpanded &&
                viewModel.chatSessionKey == session &&
                viewModel.chatSelectionRevision == selection &&
                ModalRoute.of(context)?.isCurrent == true) {
              focusNode.requestFocus();
            }
          });
        }
      }
    }
  }

  Future<void> _sendComposerMessage() async {
    if (!mounted ||
        viewModel.isDisposed ||
        !viewModel.isLoggedIn ||
        _isComposerExpanded ||
        ModalRoute.of(context)?.isCurrent != true ||
        !_canSendMessage()) {
      return;
    }
    if (_voiceInputSession != null) _invalidateVoiceInput();
    // Keep keyboard focus at submission time; a late response must not focus
    // the composer in a different conversation or a newly opened route.
    focusNode.requestFocus();
    await viewModel.sendComposerMessage();
  }

  bool _canSendMessage() {
    return !viewModel.isSendingMessage &&
        !viewModel.isUploadingFile &&
        (textController.text.trim().isNotEmpty ||
            viewModel.pendingFiles.isNotEmpty);
  }

  Widget _buildModelPickerButton() {
    final scheme = Theme.of(context).colorScheme;
    final selectedModel = viewModel.selectedModel;
    final label = selectedModel?.name ??
        S.maybeOf(context)?.Chat_select_model ??
        'Select model';

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: viewModel.isSendingMessage
                  ? null
                  : () {
                      AppHaptics.light();
                      _showModelPickerSheet();
                    },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _closeSheet(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
  }

  Widget _buildModelLoadingChip() {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                S.maybeOf(context)?.Chat_models ?? 'Models',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightButton() {
    final scheme = Theme.of(context).colorScheme;
    if (viewModel.isSendingMessage) {
      return Tooltip(
        message: S.maybeOf(context)?.Chat_stop_generating ?? 'Stop generating',
        child: Semantics(
          button: true,
          liveRegion: true,
          label: S.maybeOf(context)?.Chat_generating_response_stop ??
              'Generating response. Stop generating',
          child: Pressable(
            haptic: true,
            borderRadius: BorderRadius.circular(22),
            onTap: viewModel.stopGenerating,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: scheme.onSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stop_rounded,
                      color: scheme.surface,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_isListening) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final stopButton = Pressable(
        haptic: true,
        borderRadius: BorderRadius.circular(17),
        onTap: _stopListening,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.error,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.stop_rounded, color: scheme.onError, size: 20),
        ),
      );
      final accessibleStopButton = Tooltip(
        message:
            S.maybeOf(context)?.Chat_stop_voice_input ?? 'Stop voice input',
        child: Semantics(
          button: true,
          label:
              S.maybeOf(context)?.Chat_stop_voice_input ?? 'Stop voice input',
          child: stopButton,
        ),
      );
      if (reduceMotion) return accessibleStopButton;
      return ScaleTransition(
        scale: _pulseAnimation,
        child: accessibleStopButton,
      );
    }
    if (_canSendMessage()) {
      return Tooltip(
        message: S.maybeOf(context)?.Chat_send_message ?? 'Send message',
        child: Semantics(
          button: true,
          label: S.maybeOf(context)?.Chat_send_message ?? 'Send message',
          child: Pressable(
            haptic: true,
            borderRadius: BorderRadius.circular(17),
            onTap: _sendComposerMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: scheme.onPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      );
    }
    return Tooltip(
      message:
          S.maybeOf(context)?.Chat_start_voice_input ?? 'Start voice input',
      child: Semantics(
        button: true,
        label:
            S.maybeOf(context)?.Chat_start_voice_input ?? 'Start voice input',
        child: Pressable(
          borderRadius: BorderRadius.circular(17),
          haptic: true,
          onTap: viewModel.isUploadingFile ? null : _startListening,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outline, width: 1.5),
            ),
            child: Icon(
              Icons.mic_none,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachButton() {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: S.maybeOf(context)?.Chat_add_attachment ?? 'Add attachment',
      child: Semantics(
        button: true,
        label: S.maybeOf(context)?.Chat_add_attachment ?? 'Add attachment',
        child: Pressable(
          borderRadius: BorderRadius.circular(17),
          haptic: true,
          onTap: viewModel.isUploadingFile || viewModel.isSendingMessage
              ? null
              : _showAttachmentSheet,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outline, width: 1.5),
            ),
            child: viewModel.isUploadingFile
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.add, size: 22, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  void _showModelPickerSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    final models = List<ChatModel>.from(viewModel.models);
    final selectedId = viewModel.selectedModel?.id;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.maybeOf(context)?.Chat_select_model ?? 'Select model',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: models.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: Colors.grey.shade300,
                        ),
                        itemBuilder: (context, index) {
                          final model = models[index];
                          final isSelected = model.id == selectedId;
                          final showId = model.id != model.name;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            title: Text(
                              model.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: showId
                                ? Text(
                                    model.id,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              _closeSheet(context);
                              viewModel.selectModel(model);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  S.maybeOf(context)?.Chat_photo_library ?? 'Photo Library',
                ),
                onTap: () {
                  _closeSheet(sheetContext);
                  viewModel.pickAndUploadImages(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(S.maybeOf(context)?.Chat_camera ?? 'Camera'),
                onTap: () {
                  _closeSheet(sheetContext);
                  viewModel.pickAndUploadImages(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(S.maybeOf(context)?.Chat_files ?? 'Files'),
                onTap: () {
                  _closeSheet(sheetContext);
                  viewModel.pickAndUploadFiles();
                },
              ),
              ListTile(
                leading: viewModel.isLoadingKnowledge
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.library_books_outlined),
                title: Text(S.maybeOf(context)?.Chat_knowledge ?? 'Knowledge'),
                subtitle: Text(
                  S.maybeOf(context)?.Chat_attach_knowledge_sources ??
                      'Attach RAG sources',
                ),
                enabled: !viewModel.isLoadingKnowledge,
                onTap: () {
                  _closeSheet(sheetContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _showKnowledgePickerSheet();
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showKnowledgePickerSheet() {
    if (viewModel.knowledgeBases.isEmpty && !viewModel.isLoadingKnowledge) {
      viewModel.fetchKnowledgeBases();
    }

    final searchController = TextEditingController();
    var query = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer<ChatViewModel>(
              builder: (context, chat, _) {
                final lowerQuery = query.trim().toLowerCase();
                final knowledgeItems = chat.knowledgeBases.where((item) {
                  if (lowerQuery.isEmpty) return true;
                  final text =
                      '${item.name} ${item.description} ${item.files.map((f) => f.name).join(' ')}'
                          .toLowerCase();
                  return text.contains(lowerQuery);
                }).toList();

                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.sizeOf(sheetContext).height * 0.75,
                      ),
                      child: CustomScrollView(
                        shrinkWrap: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        S.maybeOf(context)?.Chat_knowledge ??
                                            'Knowledge',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: S
                                              .maybeOf(context)
                                              ?.Chat_refresh_knowledge ??
                                          'Refresh knowledge',
                                      icon: const Icon(Icons.refresh_rounded),
                                      onPressed: chat.isLoadingKnowledge
                                          ? null
                                          : chat.fetchKnowledgeBases,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: S
                                            .maybeOf(context)
                                            ?.Chat_search_knowledge ??
                                        'Search knowledge',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                    suffixIcon: query.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: S
                                                    .maybeOf(context)
                                                    ?.Chat_clear_search ??
                                                'Clear search',
                                            icon: const Icon(
                                              Icons.close_rounded,
                                            ),
                                            onPressed: () {
                                              searchController.clear();
                                              setSheetState(() => query = '');
                                            },
                                          ),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.55),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onChanged: (value) =>
                                      setSheetState(() => query = value),
                                ),
                                const SizedBox(height: 14),
                              ],
                            ),
                          ),
                          if (chat.isLoadingKnowledge)
                            const SliverToBoxAdapter(
                              child: SizedBox(
                                height: 96,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            )
                          else if (knowledgeItems.isEmpty)
                            SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    S
                                            .maybeOf(context)
                                            ?.Chat_no_knowledge_sources ??
                                        'No knowledge sources found',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverList.separated(
                              itemCount: knowledgeItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final knowledge = knowledgeItems[index];
                                return _KnowledgePickerCard(
                                  knowledge: knowledge,
                                  viewModel: chat,
                                );
                              },
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
      },
    ).whenComplete(() {
      FocusManager.instance.primaryFocus?.unfocus();
      searchController.dispose();
    });
  }

  static bool _isImageFile(ChatFile file) {
    final ext = file.name.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'}.contains(ext);
  }

  Widget _buildPendingFiles() {
    final scheme = Theme.of(context).colorScheme;
    if (viewModel.pendingFiles.isEmpty &&
        viewModel.uploadingFileNames.isEmpty) {
      return const SizedBox.shrink();
    }

    final images = viewModel.pendingFiles.where(_isImageFile).toList();
    final files =
        viewModel.pendingFiles.where((f) => !_isImageFile(f)).toList();
    final attachmentCount =
        viewModel.pendingFiles.length + viewModel.uploadingFileNames.length;

    return Container(
      width: context.contentWidth,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    S
                            .maybeOf(context)
                            ?.Chat_attachment_count(attachmentCount) ??
                        '$attachmentCount attachment${attachmentCount == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (!viewModel.isSendingMessage &&
                    viewModel.pendingFiles.isNotEmpty)
                  TextButton(
                    onPressed: viewModel.clearPendingFiles,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(S.maybeOf(context)?.Chat_clear ?? 'Clear'),
                  ),
              ],
            ),
          ),
          if (images.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _buildPendingImageThumb(images[i]),
              ),
            ),
          if (images.isNotEmpty && files.isNotEmpty) const SizedBox(height: 6),
          if (files.isNotEmpty || viewModel.uploadingFileNames.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ...viewModel.uploadingFileNames.map(
                  _buildUploadingAttachmentChip,
                ),
                ...files.map(_buildPendingFileChip),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUploadingAttachmentChip(String name) {
    return Chip(
      avatar: const SizedBox.square(
        dimension: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      label: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPendingFileChip(ChatFile file) {
    final detail = _pendingFileDetail(file);
    return InputChip(
      avatar: Icon(_pendingFileIcon(file), size: 18),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (detail.isNotEmpty)
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      onDeleted: viewModel.isSendingMessage
          ? null
          : () => viewModel.removePendingFile(file),
    );
  }

  String _pendingFileDetail(ChatFile file) {
    if (file.isKnowledgeCollection)
      return S.maybeOf(context)?.Chat_knowledge_collection ??
          'Knowledge collection';
    if (file.isKnowledgeFile)
      return S.maybeOf(context)?.Chat_knowledge_file ?? 'Knowledge file';
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

  IconData _pendingFileIcon(ChatFile file) {
    if (file.isKnowledgeCollection) return Icons.library_books_outlined;
    if (file.isKnowledgeFile) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Widget _buildPendingImageThumb(ChatFile file) {
    final sessionKey = viewModel.chatSessionKey;
    return PendingImageAttachment(
      file: file,
      bytes: viewModel.pendingImageBytes[file.id],
      sessionListenable: viewModel,
      isAvailable: () =>
          viewModel.isLoggedIn &&
          viewModel.chatSessionKey == sessionKey &&
          viewModel.pendingFiles.any((pending) => pending.id == file.id),
      onRemove: viewModel.isSendingMessage
          ? null
          : () {
              if (!viewModel.isLoggedIn ||
                  viewModel.chatSessionKey != sessionKey ||
                  viewModel.isSendingMessage) {
                return;
              }
              AppHaptics.light();
              viewModel.removePendingFile(file);
            },
    );
  }

  Widget noLoginView() {
    return Center(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('images/app_icon.png', width: 60, height: 60),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                S.maybeOf(context)?.Chat_sign_in_description ??
                    "Sign in to access chat, or use the composite calculators without signing in.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: _openLogin,
              icon: const Icon(Icons.manage_accounts, size: 22),
              label: Text(
                S.maybeOf(context)?.Chat_sign_in_to_chat ?? 'Sign In to Chat',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openCompositeCalculators,
              icon: const Icon(Icons.calculate_outlined, size: 22),
              label: Text(
                S.maybeOf(context)?.Chat_open_calculators ??
                    'Open Composite Calculators',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCompositeCalculators() {
    AppHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ToolPage()),
    );
  }

  Future<void> _openLogin() async {
    final user = await Navigator.push<User>(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (user == null || !mounted) return;

    AppHaptics.light();
    await viewModel.checkAuthStatus();
    if (!mounted || !viewModel.isLoggedIn) return;
    await Future.wait([viewModel.fetchChats(), viewModel.fetchTools()]);
  }
}
