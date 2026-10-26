import 'package:domain/auth/entities/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../../../util/app_interactions.dart';
import '../../../util/app_theme.dart';
import 'chat_layout.dart';

class ChatWelcomeView extends StatefulWidget {
  const ChatWelcomeView({
    super.key,
    required this.user,
    required this.questions,
    required this.bottomPadding,
    required this.onQuestionSelected,
    this.taskIndices = const [],
  });

  final User? user;
  final List<String> questions;
  final double bottomPadding;
  final ValueChanged<int> onQuestionSelected;

  /// Recognized fallback task identities, supplied independently of list order.
  /// Custom or unrecognized questions use a generic label.
  final List<int?> taskIndices;

  @override
  State<ChatWelcomeView> createState() => _ChatWelcomeViewState();
}

class _ChatWelcomeViewState extends State<ChatWelcomeView> {
  static const _initialCount = 3;
  List<String> _questions = const [];
  List<int?> _tasks = const [];
  String? _owner;
  int _revision = 0;
  bool _showAll = false;
  final Set<int> _previews = {};

  String? get _currentOwner {
    final user = widget.user;
    if (user == null) return null;
    return '${user.id ?? ''}\u0000${user.email}';
  }

  @override
  void initState() {
    super.initState();
    _synchronizeQuestions();
  }

  @override
  void didUpdateWidget(covariant ChatWelcomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _synchronizeQuestions();
  }

  void _synchronizeQuestions() {
    if (_owner == _currentOwner &&
        listEquals(_questions, widget.questions) &&
        listEquals(_tasks, widget.taskIndices)) {
      return;
    }
    _questions = List.unmodifiable(widget.questions);
    _tasks = List.unmodifiable(widget.taskIndices);
    _owner = _currentOwner;
    _revision++;
    _showAll = false;
    _previews.clear();
  }

  bool _isCurrent(int revision) {
    if (!mounted) {
      return false;
    }
    final route = ModalRoute.of(context);
    return revision == _revision &&
        _owner == _currentOwner &&
        listEquals(_questions, widget.questions) &&
        listEquals(_tasks, widget.taskIndices) &&
        (route == null || route.isCurrent);
  }

  void _selectQuestion(int index, int revision) {
    if (!_isCurrent(revision) || _questions[index].trim().isEmpty) {
      return;
    }
    AppHaptics.light();
    widget.onQuestionSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = S.maybeOf(context);
    final name = (widget.user?.name ?? '').trim();
    final email = (widget.user?.email ?? '').trim();
    final greetingTarget = name.isNotEmpty ? name : email;
    final greeting = greetingTarget.isNotEmpty
        ? (strings?.Chat_welcome_name(greetingTarget) ??
            'Welcome, $greetingTarget')
        : (strings?.Chat_welcome ?? 'Welcome');
    final revision = _revision;
    final count = _showAll || _questions.length <= _initialCount
        ? _questions.length
        : _initialCount;
    final bottomPadding = widget.bottomPadding.isFinite
        ? widget.bottomPadding.clamp(0.0, double.infinity).toDouble()
        : 0.0;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final padding = ChatLayout.horizontalPaddingFor(width);
      return CustomScrollView(
        key: const ValueKey('chat-welcome-view'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding, AppSpacing.lg, padding, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    greeting,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    strings?.Chat_working_on ?? 'What are you working on?',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    strings?.Chat_starter_review_hint ??
                        'Choose a starting point, then review your draft before sending.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_questions.isEmpty)
                    Text(
                      strings?.Chat_starter_empty ??
                          'Write your question below to begin.',
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            sliver: SliverList.builder(
              itemCount: count,
              itemBuilder: (context, index) {
                final task = _taskFor(
                  index < _tasks.length ? _tasks[index] : null,
                  strings,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _StarterCard(
                    key: ValueKey('chat-starter-card-$revision-$index'),
                    index: index,
                    title: task.$1,
                    icon: task.$2,
                    question: _questions[index],
                    previewing: _previews.contains(index),
                    onSelect: () => _selectQuestion(index, revision),
                    onPreview: () {
                      if (!_isCurrent(revision)) {
                        return;
                      }
                      setState(() {
                        if (!_previews.remove(index)) {
                          _previews.add(index);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                padding, 0, padding, bottomPadding + AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: _questions.length > _initialCount
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        key: const ValueKey('chat-welcome-more'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () {
                          if (!_isCurrent(revision)) {
                            return;
                          }
                          setState(() => _showAll = !_showAll);
                        },
                        icon: Icon(
                            _showAll ? Icons.expand_less : Icons.expand_more),
                        label: Text(_showAll
                            ? (strings?.Chat_starters_less ?? 'Show fewer')
                            : (strings?.Chat_starters_more ??
                                'See more starting points')),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      );
    });
  }
}

(String, IconData) _taskFor(int? task, S? strings) => switch (task) {
      0 => (
          strings?.Chat_task_materials ?? 'Compare materials',
          Icons.science_outlined,
        ),
      1 => (
          strings?.Chat_task_stiffness ?? 'Estimate stiffness',
          Icons.speed_outlined,
        ),
      2 => (
          strings?.Chat_task_failure ?? 'Understand failure',
          Icons.health_and_safety_outlined,
        ),
      3 => (
          strings?.Chat_task_laminate ?? 'Plan a laminate',
          Icons.layers_outlined,
        ),
      4 => (
          strings?.Chat_task_calculators ?? 'Choose a calculator',
          Icons.calculate_outlined,
        ),
      _ => (
          strings?.Chat_task_generic ?? 'Explore a question',
          Icons.chat_bubble_outline,
        ),
    };

class _StarterCard extends StatelessWidget {
  const _StarterCard({
    super.key,
    required this.index,
    required this.title,
    required this.icon,
    required this.question,
    required this.previewing,
    required this.onSelect,
    required this.onPreview,
  });

  final int index;
  final String title;
  final IconData icon;
  final String question;
  final bool previewing;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = S.maybeOf(context);
    final useLabel = strings?.Chat_starter_use_question ?? 'Use this question';
    final previewLabel = previewing
        ? (strings?.Chat_starter_hide_preview ?? 'Hide question')
        : (strings?.Chat_starter_preview ?? 'Preview question');
    return Card(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  label: '$useLabel: $title. $question',
                  button: true,
                  enabled: question.trim().isNotEmpty,
                  onTap: question.trim().isEmpty ? null : onSelect,
                  excludeSemantics: true,
                  child: InkWell(
                    key: ValueKey('chat-starter-$index'),
                    onTap: question.trim().isEmpty ? null : onSelect,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, size: 24, color: scheme.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(title,
                                    style: theme.textTheme.titleMedium),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            question,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacing.xs, right: AppSpacing.xs),
                child: IconButton(
                  key: ValueKey('chat-starter-preview-$index'),
                  tooltip: previewLabel,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  onPressed: onPreview,
                  icon: Icon(previewing
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded),
                ),
              ),
            ],
          ),
          if (previewing) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(
                  child: SelectableText(
                    question,
                    key: ValueKey('chat-starter-full-question-$index'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
