import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/chat/views/chat_progress_indicator.dart';

void main() {
  testWidgets('shows Thinking while waiting for the first token',
      (tester) async {
    final message = Message(role: 'assistant');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatResponseActivity(
            message: message,
            isStreaming: true,
          ),
        ),
      ),
    );

    expect(find.text('Thinking…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('replaces thinking with knowledge search status', (tester) async {
    final message = Message(
      role: 'assistant',
      statusHistory: const [
        ToolStatus(
          action: 'knowledge_search',
          query: 'laminate failure',
          done: false,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatResponseActivity(
            message: message,
            isStreaming: true,
          ),
        ),
      ),
    );

    expect(find.text('Thinking…'), findsNothing);
    expect(
      find.text('Searching Knowledge for “laminate failure”'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('hides activity once answer content arrives', (tester) async {
    final message = Message(
      role: 'assistant',
      content: 'Answer ready.',
      statusHistory: const [
        ToolStatus(
          action: 'knowledge_search',
          query: 'laminate failure',
          done: true,
        ),
      ],
    )..isDone = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatResponseActivity(
            message: message,
            isStreaming: false,
          ),
        ),
      ),
    );

    expect(find.text('Thinking…'), findsNothing);
    expect(find.textContaining('Searching Knowledge'), findsNothing);
  });

  testWidgets('legacy progress card still expands activity history',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatProgressIndicator(
            isStreaming: true,
            statuses: [
              ToolStatus(
                action: 'knowledge_search',
                query: 'laminate failure',
                done: true,
              ),
              ToolStatus(
                action: 'sources_found',
                description: 'Found {{count}} relevant sources',
                urls: ['https://example.com/one', 'https://example.com/two'],
                done: false,
              ),
              ToolStatus(
                description: 'Internal event',
                hidden: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Working'), findsOneWidget);
    expect(find.text('Found 2 relevant sources'), findsWidgets);
    expect(find.text('Internal event'), findsNothing);
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_more_rounded));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(
      find.text('Searching Knowledge for “laminate failure”'),
      findsOneWidget,
    );
  });
}
