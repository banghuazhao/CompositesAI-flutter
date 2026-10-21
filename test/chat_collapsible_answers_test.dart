import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/model/chat_export.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/ai_markdown_message.dart';
import 'package:swiftcomp/presentation/chat/views/chat_answer_collapse_state.dart';
import 'package:swiftcomp/presentation/chat/views/chat_progress_indicator.dart';
import 'package:swiftcomp/presentation/chat/views/message_list.dart';

class _UseCase extends Fake implements ChatUseCase {}

class _Model extends ChatViewModel {
  _Model()
      : super(
          chatUseCase: _UseCase(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'account-a', email: 'a@example.test');
  }

  bool streaming = false;
  bool loading = false;

  @override
  bool get isSendingMessage => streaming;
  @override
  bool get isLoadingMessages => loading;
  @override
  bool get canRegenerate => false;

  void show(Chat? chat, List<Message> history) {
    selectedChat = chat;
    messages = List.of(history);
    notifyListeners();
  }

  void changed() => notifyListeners();
}

final _chatA = Chat(id: 'a', title: 'A');
final _chatB = Chat(id: 'b', title: 'B');

Message _answer([String? text]) => Message(
      role: 'assistant',
      content: text ?? ('Long engineering answer with carbon and glass. ' * 36),
    );

Finder _toggle(Message message) =>
    find.byKey(ValueKey('chat-answer-toggle-${message.id}'));
Finder _preview(Message message) =>
    find.byKey(ValueKey('chat-answer-preview-${message.id}'));
VoidCallback _action(WidgetTester tester, Message message) =>
    tester.widget<TextButton>(_toggle(message)).onPressed!;

Future<void> _pump(WidgetTester tester, ChatViewModel model,
    {Locale locale = const Locale('en'),
    Size size = const Size(600, 700),
    double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<ChatViewModel>.value(
    value: model,
    child: MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const Scaffold(body: MessageList(bottomContentPadding: 20)),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _collapse(WidgetTester tester, Message message) async {
  await tester.tap(_toggle(message));
  await tester.pumpAndSettle();
  expect(_preview(message), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bounded answer presentation state', () {
    test('threshold includes legacy finished text and many short lines', () {
      expect(
          ChatAnswerCollapseState.isLongAnswer(_answer('a' * 1199)), isFalse);
      expect(ChatAnswerCollapseState.isLongAnswer(_answer('a' * 1200)), isTrue);
      expect(
          ChatAnswerCollapseState.isLongAnswer(
              _answer(List.filled(16, 'Line').join('\n'))),
          isTrue);
      expect(
          ChatAnswerCollapseState.isLongAnswer(
              _answer(List.filled(15, 'Line').join('\n'))),
          isFalse);
      expect(
          ChatAnswerCollapseState.isLongAnswer(_answer(' ' * 2000)), isFalse);
      expect(
          ChatAnswerCollapseState.isLongAnswer(
              Message(role: 'user', content: 'a' * 2000)),
          isFalse);
    });

    test('cache stays bounded and replacement, content and streaming retire it',
        () {
      final state = ChatAnswerCollapseState(maximumEntries: 3);
      final answers = List.generate(4, (_) => _answer());
      state.synchronize(scope: 'a', available: true, messages: answers);
      for (final answer in answers) {
        state.toggle(answer);
      }
      expect(state.collapsedCount, 3);
      expect(state.isCollapsed(answers.first), isFalse);
      expect(state.isCollapsed(answers.last), isTrue);
      final replacement = Message.fromJson(answers.last.toJson());
      expect(replacement.id, answers.last.id);
      final current = [answers[1], answers[2], replacement];
      state.synchronize(scope: 'a', available: true, messages: current);
      expect(state.collapsedCount, 2);
      expect(state.isCollapsed(replacement), isFalse);
      answers[1].content += ' Updated';
      state.synchronize(
          scope: 'a',
          available: true,
          messages: current,
          streamingMessage: answers[2]);
      expect(state.collapsedCount, 0);
      state.toggle(replacement);
      state.synchronize(scope: 'b', available: true, messages: current);
      expect(state.collapsedCount, 0);
      state.toggle(replacement);
      state.synchronize(scope: 'b', available: false, messages: current);
      expect(state.collapsedCount, 0);
    });
  });

  late _Model model;
  late Message answer;
  late List<String> copied;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    model = _Model();
    answer = _answer();
    model.show(_chatA, [answer]);
    copied = [];
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
  });
  tearDown(() {
    model.dispose();
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('answers start expanded and folding keeps timestamps and actions',
      (tester) async {
    expect(answer.isDone, isFalse,
        reason: 'Legacy loaded history may omit the done flag.');
    answer.statusHistory.add(const ToolStatus(
        action: 'response_stopped', description: 'Stopped', done: true));
    await _pump(tester, model);
    expect(find.byType(AiMarkdownMessage), findsOneWidget);
    expect(find.text('Collapse answer'), findsOneWidget);
    await _collapse(tester, answer);
    expect(find.byType(AiMarkdownMessage), findsNothing);
    expect(find.text('Expand answer'), findsOneWidget);
    expect(find.byType(ChatResponseActivity), findsOneWidget);
    expect(
        find.byKey(ValueKey('chat-message-time-${answer.id}')), findsOneWidget);
    expect(find.byTooltip('Copy message'), findsOneWidget);
    expect(find.byTooltip('Good response'), findsOneWidget);
    await tester.tap(_toggle(answer));
    await tester.pumpAndSettle();
    expect(find.byType(AiMarkdownMessage), findsOneWidget);
    expect(_preview(answer), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('plain Unicode preview never parses partial Markdown',
      (tester) async {
    const family = '👨‍👩‍👧‍👦';
    answer.content = '```dart\n${family * 300}\n${r'$$\frac{1}{2}$$'}';
    await _pump(tester, model);
    await _collapse(tester, answer);
    final preview = tester.widget<Text>(_preview(answer)).data!;
    expect(preview, startsWith('```dart '));
    expect(preview, contains(family));
    expect(preview.runes, isNot(contains(0xfffd)));
    expect(preview.characters.length, lessThanOrEqualTo(281));
    expect(find.byType(AiMarkdownMessage), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('collapsed Copy and Markdown export retain the complete answer',
      (tester) async {
    answer.content = '${'Carbon results. ' * 100}\n'
        '```text\nTAIL_VALUE = 135.123456789\n```';
    final original = answer.toJson();
    final exportedAt = DateTime(2026, 10, 21);
    final before = ChatExport.toMarkdown(
        title: 'Complete data',
        messages: model.messages,
        exportedAt: exportedAt);
    await _pump(tester, model);
    await _collapse(tester, answer);
    expect(tester.widget<Text>(_preview(answer)).data,
        isNot(contains('TAIL_VALUE')));
    await tester.tap(find.byTooltip('Copy message'));
    await tester.pump();
    expect(copied, [answer.content]);
    expect(copied.single, contains('TAIL_VALUE = 135.123456789'));
    expect(answer.toJson(), original);
    expect(
        ChatExport.toMarkdown(
            title: 'Complete data',
            messages: model.messages,
            exportedAt: exportedAt),
        before);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('streaming expands and retires folding and old toggle callbacks',
      (tester) async {
    await _pump(tester, model);
    await _collapse(tester, answer);
    final stale = _action(tester, answer);
    model.streaming = true;
    model.changed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_preview(answer), findsNothing);
    expect(_toggle(answer), findsNothing);
    expect(find.byType(AiMarkdownMessage), findsOneWidget);
    expect(find.byType(ChatResponseActivity), findsOneWidget);
    model.streaming = false;
    model.changed();
    stale();
    await tester.pumpAndSettle();
    expect(find.text('Collapse answer'), findsOneWidget);
    expect(_preview(answer), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('new content and a replacement with the same ID start expanded',
      (tester) async {
    await _pump(tester, model);
    await _collapse(tester, answer);
    answer.content += ' Regenerated contents';
    model.changed();
    await tester.pumpAndSettle();
    expect(_preview(answer), findsNothing);
    expect(find.text('Collapse answer'), findsOneWidget);
    await _collapse(tester, answer);
    final stale = _action(tester, answer);
    final replacement = Message.fromJson(answer.toJson());
    model.show(_chatA, [replacement]);
    stale();
    await tester.pumpAndSettle();
    expect(_preview(replacement), findsNothing);
    expect(find.text('Collapse answer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('folding survives lazy row eviction within the same conversation',
      (tester) async {
    model.show(_chatA, [
      answer,
      ...List.generate(60, (index) => _answer('Short answer $index')),
    ]);
    await _pump(tester, model, size: const Size(600, 500));
    await _collapse(tester, answer);
    for (var step = 0; step < 4; step++) {
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
    }
    expect(_toggle(answer), findsNothing);
    model.scrollController.jumpTo(0);
    await tester.pumpAndSettle();
    expect(_preview(answer), findsOneWidget);
    expect(find.text('Expand answer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('A to B to A before a frame clears folds and retained callbacks',
      (tester) async {
    await _pump(tester, model);
    await _collapse(tester, answer);
    final stale = _action(tester, answer);
    model.show(_chatB, [_answer()]);
    model.show(_chatA, [answer]);
    stale();
    await tester.pumpAndSettle();
    expect(_preview(answer), findsNothing);
    expect(find.text('Collapse answer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final transition in ['account', 'logout', 'loading', 'dispose']) {
    testWidgets('$transition retires collapsed state and stale actions',
        (tester) async {
      await _pump(tester, model);
      await _collapse(tester, answer);
      final stale = _action(tester, answer);
      switch (transition) {
        case 'account':
          model.user = User(id: 'account-b', email: 'b@example.test');
          model.changed();
        case 'logout':
          model.isLoggedIn = false;
          model.changed();
        case 'loading':
          model.loading = true;
          model.changed();
        case 'dispose':
          model.dispose();
      }
      stale();
      await tester.pumpAndSettle();
      expect(_preview(answer), findsNothing);
      if (transition == 'dispose') {
        expect(find.byType(ListView), findsNothing);
      } else {
        model.isLoggedIn = true;
        model.loading = false;
        model.changed();
        await tester.pumpAndSettle();
        expect(find.text('Collapse answer'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('folding changes scroll extent without a stale bottom jump',
      (tester) async {
    answer.content =
        List.generate(80, (index) => 'Engineering result $index.').join('\n\n');
    await _pump(tester, model, size: const Size(600, 500));
    final fullExtent = model.scrollController.position.maxScrollExtent;
    expect(fullExtent, greaterThan(0));
    await _collapse(tester, answer);
    final foldedExtent = model.scrollController.position.maxScrollExtent;
    expect(foldedExtent, lessThan(fullExtent));
    expect(model.scrollController.offset, inInclusiveRange(0, foldedExtent));
    await tester.tap(_toggle(answer));
    await tester.pumpAndSettle();
    expect(model.scrollController.position.maxScrollExtent,
        greaterThan(foldedExtent));
    expect(model.scrollController.offset, 0);
    expect(tester.takeException(), isNull);
    final stale = _action(tester, answer);
    await tester.pumpWidget(const SizedBox.shrink());
    stale();
    model.changed();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets('$locale fold control is accessible at320px and2x text',
        (tester) async {
      await _pump(tester, model,
          locale: locale, size: const Size(320, 700), scale: 2);
      final strings = S.of(tester.element(_toggle(answer)));
      expect(find.text(strings.Chat_collapse_answer), findsOneWidget);
      final size = tester.getSize(_toggle(answer));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Semantics && widget.properties.expanded == true),
          findsOneWidget);
      await _collapse(tester, answer);
      expect(find.text(strings.Chat_expand_answer), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Semantics && widget.properties.expanded == false),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
