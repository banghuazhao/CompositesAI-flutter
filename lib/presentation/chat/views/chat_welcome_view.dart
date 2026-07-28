import 'package:domain/auth/entities/user.dart';
import 'package:flutter/material.dart';

import '../../../util/app_interactions.dart';
import '../../../util/context_extension_screen_width.dart';

class ChatWelcomeView extends StatelessWidget {
  const ChatWelcomeView({
    super.key,
    required this.user,
    required this.questions,
    required this.bottomPadding,
    required this.onQuestionSelected,
  });

  final User? user;
  final List<String> questions;
  final double bottomPadding;
  final ValueChanged<int> onQuestionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = (user?.name ?? '').trim();
    final email = (user?.email ?? '').trim();
    final greetingTarget = name.isNotEmpty ? name : email;
    final greeting =
        greetingTarget.isNotEmpty ? 'Welcome, $greetingTarget' : 'Welcome';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: SingleChildScrollView(
        key: const ValueKey('chat-welcome-view'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding + 20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.contentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'images/app_icon.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Composites engineering copilot',
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'What are you working on?',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Ask about materials, laminate design, failure analysis, '
                  'manufacturing, or engineering calculations.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Suggested questions',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                ...List.generate(
                  questions.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == questions.length - 1 ? 0 : 10,
                    ),
                    child: _SuggestionCard(
                      question: questions[index],
                      icon: _iconForQuestion(questions[index]),
                      onTap: () {
                        AppHaptics.light();
                        onQuestionSelected(index);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForQuestion(String question) {
    final normalized = question.toLowerCase();
    if (normalized.contains('calculator') ||
        normalized.contains('estimate') ||
        normalized.contains('modulus')) {
      return Icons.calculate_outlined;
    }
    if (normalized.contains('failure') ||
        normalized.contains('delamination') ||
        normalized.contains('prevent')) {
      return Icons.health_and_safety_outlined;
    }
    if (normalized.contains('orientation') ||
        normalized.contains('stacking') ||
        normalized.contains('laminate')) {
      return Icons.layers_outlined;
    }
    if (normalized.contains('material') ||
        normalized.contains('carbon') ||
        normalized.contains('glass')) {
      return Icons.science_outlined;
    }
    return Icons.auto_awesome_outlined;
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.question,
    required this.icon,
    required this.onTap,
  });

  final String question;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Ask: $question',
      child: Card(
        color: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
