import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';

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
  final commentController = TextEditingController();

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
  if (existingFeedbackMatches) {
    commentController.text = message.feedbackComment ?? '';
  }
  String? localError;
  var isSaving = false;

  final saved = await showModalBottomSheet<bool>(
    context: pageContext,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final scheme = Theme.of(context).colorScheme;
          final activeReasons = isGood ? positiveReasons : negativeReasons;

          return SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    'Rate this response',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your feedback helps improve answer quality.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.thumb_up_alt_outlined),
                          label: Text('Helpful'),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.thumb_down_alt_outlined),
                          label: Text('Needs work'),
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
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                  ),
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
                        Text(
                          '1 · Poor',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '10 · Excellent',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
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
                        label: Text(reason),
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
                    decoration: const InputDecoration(
                      labelText: 'Additional details',
                      hintText: 'Optional',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      localError!,
                      style: TextStyle(color: scheme.error),
                    ),
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
                                  localError =
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
                                reasons:
                                    selectedReasons.toList(growable: false),
                                comment: comment.isEmpty ? null : comment,
                                messageIndex: messageIndex + 1,
                              );
                              if (!sheetContext.mounted) return;
                              if (submitted) {
                                Navigator.of(sheetContext).pop(true);
                              } else {
                                setSheetState(() {
                                  isSaving = false;
                                  localError =
                                      'Feedback could not be saved. Try again.';
                                });
                              }
                            },
                      child: isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              message.feedbackId == null
                                  ? 'Submit feedback'
                                  : 'Update feedback',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  commentController.dispose();
  if (saved == true && pageContext.mounted) {
    ScaffoldMessenger.of(pageContext).showSnackBar(
      const SnackBar(content: Text('Feedback saved.')),
    );
  }
}
