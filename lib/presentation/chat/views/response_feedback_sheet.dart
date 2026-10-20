import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../viewModels/chat_view_model.dart';

Future<void> showResponseFeedbackSheet({
  required BuildContext context,
  required ChatViewModel viewModel,
  required Message message,
  required bool initialIsGood,
  required int messageIndex,
}) async {
  if (viewModel.selectedChat == null) return;
  final pageContext = context;

  const positiveReasons = <String>[
    'Accurate',
    'Clear explanation',
    'Useful detail',
    'Followed instructions',
    'Good structure',
    'Other',
  ];
  const negativeReasons = <String>[
    'Inaccurate',
    'Unclear',
    'Too verbose',
    'Not useful',
    "Didn't follow instructions",
    'Other',
  ];

  var isGood = initialIsGood;
  final existingFeedbackMatches =
      message.feedbackRating == (initialIsGood ? 1 : -1);
  var rating = existingFeedbackMatches
      ? message.feedbackDetailsRating ?? (initialIsGood ? 10 : 1)
      : (initialIsGood ? 10 : 1);
  final selectedReasons = existingFeedbackMatches
      ? <String>{...message.feedbackReasons}
      : <String>{};
  final initialComment =
      existingFeedbackMatches ? message.feedbackComment ?? '' : '';
  String? localError;
  var isSaving = false;

  final saved = await showModalBottomSheet<bool>(
    context: pageContext,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _FeedbackCommentScope(
        initialComment: initialComment,
        builder: (context, commentController) => StatefulBuilder(
          builder: (context, setSheetState) {
            final scheme = Theme.of(context).colorScheme;
            final strings = S.maybeOf(context);
            // Keep canonical reason values stable for saved feedback and API calls.
            final reasonLabels = <String, String>{
              "Accurate": strings?.Chat_feedback_accurate ?? "Accurate",
              "Clear explanation": strings?.Chat_feedback_clear_explanation ??
                  "Clear explanation",
              "Useful detail":
                  strings?.Chat_feedback_useful_detail ?? "Useful detail",
              "Followed instructions":
                  strings?.Chat_feedback_followed_instructions ??
                      "Followed instructions",
              "Good structure":
                  strings?.Chat_feedback_good_structure ?? "Good structure",
              "Other": strings?.Chat_feedback_other ?? "Other",
              "Inaccurate": strings?.Chat_feedback_inaccurate ?? "Inaccurate",
              "Unclear": strings?.Chat_feedback_unclear ?? "Unclear",
              "Too verbose":
                  strings?.Chat_feedback_too_verbose ?? "Too verbose",
              "Not useful": strings?.Chat_feedback_not_useful ?? "Not useful",
              "Didn't follow instructions":
                  strings?.Chat_feedback_did_not_follow ??
                      "Didn't follow instructions",
            };
            final activeReasons = isGood ? positiveReasons : negativeReasons;

            return SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings?.Chat_feedback_title ?? 'Rate this response',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings?.Chat_feedback_help ??
                          'Your feedback helps improve answer quality.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: true,
                            icon: const Icon(Icons.thumb_up_alt_outlined),
                            label: Text(
                              strings?.Chat_feedback_helpful ?? 'Helpful',
                            ),
                          ),
                          ButtonSegment(
                            value: false,
                            icon: const Icon(Icons.thumb_down_alt_outlined),
                            label: Text(
                              strings?.Chat_feedback_needs_work ?? 'Needs work',
                            ),
                          ),
                        ],
                        selected: {isGood},
                        onSelectionChanged: isSaving
                            ? null
                            : (values) {
                                setSheetState(() {
                                  isGood = values.first;
                                  rating = isGood ? 10 : 1;
                                  selectedReasons.clear();
                                  localError = null;
                                });
                              },
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings?.Chat_feedback_quality_score ??
                                'Quality score',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 42),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '$rating',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: scheme.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: rating.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$rating',
                      onChanged: isSaving
                          ? null
                          : (value) => setSheetState(() {
                                rating = value.round();
                                localError = null;
                              }),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              strings?.Chat_feedback_poor ?? '1 · Poor',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              strings?.Chat_feedback_excellent ??
                                  '10 · Excellent',
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      strings?.Chat_feedback_reason_prompt ??
                          'What influenced your rating?',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activeReasons.map((reason) {
                        final selected = selectedReasons.contains(reason);
                        return FilterChip(
                          label: Text(reasonLabels[reason] ?? reason),
                          selected: selected,
                          onSelected: isSaving
                              ? null
                              : (_) => setSheetState(() {
                                    selected
                                        ? selectedReasons.remove(reason)
                                        : selectedReasons.add(reason);
                                    localError = null;
                                  }),
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      enabled: !isSaving,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: strings?.Chat_feedback_additional_details ??
                            'Additional details',
                        hintText: strings?.Chat_feedback_optional ?? 'Optional',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 10),
                      Text(localError!, style: TextStyle(color: scheme.error)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (selectedReasons.isEmpty) {
                                  setSheetState(() {
                                    localError = strings
                                            ?.Chat_feedback_reason_required ??
                                        'Select at least one reason to continue.';
                                  });
                                  return;
                                }
                                setSheetState(() {
                                  isSaving = true;
                                  localError = null;
                                });

                                final comment = commentController.text.trim();
                                final submitted =
                                    await viewModel.submitMessageFeedback(
                                  message: message,
                                  goodBadRating: isGood ? 1 : -1,
                                  detailsRating: rating,
                                  reasons: selectedReasons.toList(
                                    growable: false,
                                  ),
                                  comment: comment.isEmpty ? null : comment,
                                  messageIndex: messageIndex + 1,
                                );
                                if (!sheetContext.mounted) return;
                                if (submitted) {
                                  Navigator.of(sheetContext).pop(true);
                                } else {
                                  setSheetState(() {
                                    isSaving = false;
                                    localError = strings
                                            ?.Chat_feedback_save_failed ??
                                        'Feedback could not be saved. Try again.';
                                  });
                                }
                              },
                        child: isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                message.feedbackId == null
                                    ? strings?.Chat_feedback_submit ??
                                        'Submit feedback'
                                    : strings?.Chat_feedback_update ??
                                        'Update feedback',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
  if (saved == true && pageContext.mounted) {
    ScaffoldMessenger.of(pageContext).showSnackBar(
      SnackBar(
        content: Text(
          S.maybeOf(pageContext)?.Chat_feedback_saved ?? 'Feedback saved.',
        ),
      ),
    );
  }
}

/// Keeps the controller alive throughout the modal route's reverse animation.
class _FeedbackCommentScope extends StatefulWidget {
  const _FeedbackCommentScope({
    required this.initialComment,
    required this.builder,
  });

  final String initialComment;
  final Widget Function(BuildContext, TextEditingController) builder;

  @override
  State<_FeedbackCommentScope> createState() => _FeedbackCommentScopeState();
}

class _FeedbackCommentScopeState extends State<_FeedbackCommentScope> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
