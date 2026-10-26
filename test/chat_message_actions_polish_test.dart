import 'dart:async';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/ai_markdown_message.dart';
import 'package:swiftcomp/presentation/chat/views/chat_layout.dart';
import 'package:swiftcomp/presentation/chat/views/chat_reading_style.dart';
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
    user = User(id: 'a', email: 'a@example.test');
    selectedChat = conversation;
    question =
        Message(role: 'user', content: '  Carbon α\nOriginal question  ');
    answer = Message(
      role: 'assistant',
      content: 'A clear answer with **carbon** and glass.',
      parentId: question.id,
    );
    messages = [question, answer];
  }

  final conversation = Chat(id: 'a', title: 'A');
  late final Message question;
  late final Message answer;
  final copied = <String>[];
  var regenerated = 0;

  @override
  bool get canRegenerate => true;
  @override
  void copyMessage(Message message) => copied.add(message.content);
  @override
  Future<void> regenerateLastResponse() async {
    regenerated++;
  }
}

Finder _more(Message message) =>
    find.byKey(ValueKey('chat-message-more-${message.id}'));

Future<void> _openMore(WidgetTester tester, Message message) async {
  await tester.ensureVisible(_more(message));
  await tester.pumpAndSettle();
  await tester.tap(_more(message));
  await tester.pumpAndSettle();
}

Future<void> _closeMore(WidgetTester tester) async {
  await tester.tapAt(const Offset(2, 2));
  await tester.pumpAndSettle();
}

Future<void> _mount(WidgetTester tester,
    {required Widget child,
    _Model? model,
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
    Size size = const Size(600, 900),
    double scale = 1,
    GlobalKey<NavigatorState>? navigatorKey}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    navigatorKey: navigatorKey,
    theme: ThemeData(colorSchemeSeed: Colors.teal, brightness: brightness),
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data:
          MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: model == null
          ? child
          : ChangeNotifierProvider<ChatViewModel>.value(
              value: model, child: child),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _withModel(
    WidgetTester tester, Future<void> Function(_Model) action) async {
  final model = _Model();
  try {
    await action(model);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    model.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Copy stays primary while labeled secondary actions live in More',
      (tester) => _withModel(tester, (model) async {
            await _mount(tester,
                model: model,
                child: const MessageList(bottomContentPadding: 20));
            expect(find.byTooltip('Copy message'), findsNWidgets(2));
            expect(find.text('Good response'), findsNothing);
            expect(
                find.byKey(ValueKey('chat-copy-exchange-${model.answer.id}')),
                findsNothing);
            expect(
                find.byKey(ValueKey('chat-use-as-draft-${model.question.id}')),
                findsNothing);
            await tester.tap(find.byTooltip('Copy message').first);
            expect(model.copied, [model.question.content]);
            await _openMore(tester, model.question);
            expect(find.text('Use as draft'), findsOneWidget);
            await _closeMore(tester);
            await _openMore(tester, model.answer);
            expect(find.text('Copy question and answer'), findsOneWidget);
            expect(find.text('Regenerate response'), findsOneWidget);
            expect(find.text('Good response'), findsOneWidget);
            expect(find.text('Bad response'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }));

  testWidgets(
      'feedback and regenerate menu actions still invoke original flows',
      (tester) => _withModel(tester, (model) async {
            await _mount(tester,
                model: model,
                child: const MessageList(bottomContentPadding: 20));
            await _openMore(tester, model.answer);
            await tester.tap(find
                .byKey(ValueKey('chat-feedback-positive-${model.answer.id}')));
            await tester.pumpAndSettle();
            expect(find.text('Rate this response'), findsOneWidget);
            Navigator.of(tester.element(find.text('Rate this response'))).pop();
            await tester.pumpAndSettle();
            await _openMore(tester, model.answer);
            await tester.tap(
                find.byKey(ValueKey('chat-regenerate-${model.answer.id}')));
            await tester.pumpAndSettle();
            expect(model.regenerated, 1);
            expect(tester.takeException(), isNull);
          }));

  testWidgets(
      'reuse confirmation survives unrelated parent rebuilds and cancel',
      (tester) => _withModel(tester, (model) async {
            model.composerTextController.text = 'Keep until approved';
            var applied = 0;
            await _mount(tester,
                model: model,
                child: MessageList(
                    bottomContentPadding: 20, onDraftApplied: () => applied++));
            final use =
                find.byKey(ValueKey('chat-use-as-draft-${model.question.id}'));
            await _openMore(tester, model.question);
            await tester.tap(use);
            await tester.pumpAndSettle();
            expect(find.byKey(const Key('chat-replace-draft-dialog')),
                findsOneWidget);
            model.notifyListeners();
            await tester.pumpAndSettle();
            expect(find.byKey(const Key('chat-replace-draft-dialog')),
                findsOneWidget);
            await tester
                .tap(find.byKey(const Key('chat-replace-draft-cancel')));
            await tester.pumpAndSettle();
            expect(model.composerTextController.text, 'Keep until approved');
            expect(use, findsOneWidget);
            await tester.tap(use);
            await tester.pumpAndSettle();
            await tester
                .tap(find.byKey(const Key('chat-replace-draft-confirm')));
            await tester.pumpAndSettle();
            expect(model.composerTextController.text, model.question.content);
            expect(model.composerTextController.selection,
                TextSelection.collapsed(offset: model.question.content.length));
            expect(applied, 1);
            expect(use, findsNothing);
            expect(tester.takeException(), isNull);
          }));

  for (final transition in [
    'chat ABA',
    'account',
    'content',
    'replacement',
    'dispose'
  ]) {
    testWidgets(
        '$transition closes More and rejects retained secondary callbacks',
        (tester) => _withModel(tester, (model) async {
              await _mount(tester,
                  model: model,
                  child: const MessageList(bottomContentPadding: 20));
              await _openMore(tester, model.answer);
              final regenerate = tester
                  .widget<MenuItemButton>(find
                      .byKey(ValueKey('chat-regenerate-${model.answer.id}')))
                  .onPressed!;
              final feedback = tester
                  .widget<MenuItemButton>(find.byKey(
                      ValueKey('chat-feedback-positive-${model.answer.id}')))
                  .onPressed!;
              switch (transition) {
                case 'chat ABA':
                  model.selectedChat = Chat(id: 'b', title: 'B');
                  model.selectedChat = model.conversation;
                case 'account':
                  model.user = User(id: 'b', email: 'b@example.test');
                case 'content':
                  model.answer.content += ' changed';
                case 'replacement':
                  model.messages = [
                    model.question,
                    Message.fromJson(model.answer.toJson())
                  ];
                case 'dispose':
                  model.dispose();
              }
              model.notifyListeners();
              regenerate();
              feedback();
              await tester.pumpAndSettle();
              expect(model.regenerated, 0);
              expect(find.text('Rate this response'), findsNothing);
              expect(find.text('Good response'), findsNothing);
              expect(tester.takeException(), isNull);
            }));
  }

  testWidgets(
      'covered route blocks retained menu callbacks without popping it',
      (tester) => _withModel(tester, (model) async {
            final navigator = GlobalKey<NavigatorState>();
            await _mount(tester,
                model: model,
                navigatorKey: navigator,
                child: const MessageList(bottomContentPadding: 20));
            await _openMore(tester, model.answer);
            final feedback = tester
                .widget<MenuItemButton>(find.byKey(
                    ValueKey('chat-feedback-positive-${model.answer.id}')))
                .onPressed!;
            unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Cover page')))));
            await tester.pumpAndSettle();
            feedback();
            await tester.pumpAndSettle();
            expect(find.text('Cover page'), findsOneWidget);
            expect(find.text('Rate this response'), findsNothing);
            expect(tester.takeException(), isNull);
          }));

  testWidgets(
      'wide conversation uses shared measure and equal reading metrics',
      (tester) => _withModel(tester, (model) async {
            await _mount(tester,
                model: model,
                size: const Size(1280, 900),
                child: const MessageList(bottomContentPadding: 20));
            final question = tester.widget<SelectableText>(
                find.widgetWithText(SelectableText, model.question.content));
            final answer = tester.widget<GptMarkdown>(find.byType(GptMarkdown));
            expect(question.style!.fontSize, answer.style!.fontSize);
            expect(question.style!.height, answer.style!.height);
            expect(question.style!.letterSpacing, answer.style!.letterSpacing);
            final row = tester.getRect(find.byKey(ValueKey(model.answer.id)));
            expect(row.width, ChatLayout.maximumContentWidth);
            expect(row.left, ChatLayout.horizontalPaddingFor(1280));
            expect(tester.takeException(), isNull);
          }));

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK')
  ]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
          '$locale $brightness menus fit320px at2x with 48px actions',
          (tester) => _withModel(tester, (model) async {
                await _mount(tester,
                    model: model,
                    locale: locale,
                    brightness: brightness,
                    size: const Size(320, 900),
                    scale: 2,
                    child: const MessageList(bottomContentPadding: 20));
                final strings = S.of(tester.element(_more(model.answer)));
                expect(find.byTooltip(strings.Chat_more_actions),
                    findsNWidgets(2));
                expect(tester.getSize(_more(model.answer)).height,
                    greaterThanOrEqualTo(48));
                await _openMore(tester, model.answer);
                for (final key in [
                  'chat-copy-exchange-${model.answer.id}',
                  'chat-regenerate-${model.answer.id}',
                  'chat-feedback-positive-${model.answer.id}',
                  'chat-feedback-negative-${model.answer.id}',
                ]) {
                  final item = find.byKey(ValueKey(key));
                  await tester.ensureVisible(item);
                  await tester.pumpAndSettle();
                  expect(item.hitTestable(), findsOneWidget);
                  expect(tester.getSize(item).height, greaterThanOrEqualTo(48));
                  expect(tester.getRect(item).left, greaterThanOrEqualTo(0));
                  expect(tester.getRect(item).right, lessThanOrEqualTo(320));
                }
                expect(tester.takeException(), isNull);
              }));
    }
  }

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var fail = false;
  Completer<void>? gate;
  late List<String> copied;
  setUp(() {
    copied = [];
    fail = false;
    gate = null;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
        await gate?.future;
        if (fail) throw PlatformException(code: 'clipboard-denied');
      }
      return null;
    });
  });
  tearDown(() {
    if (gate != null && !gate!.isCompleted) gate!.complete();
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  const code = '```dart\nfinal value = "碳纖維 🌍";\n```';
  testWidgets('retained code copy callback is inert after disposal',
      (tester) async {
    await _mount(tester, child: const AiMarkdownMessage(markdown: code));
    final copy = tester
        .widget<IconButton>(find.ancestor(
            of: find.byTooltip('Copy code'), matching: find.byType(IconButton)))
        .onPressed!;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    copy();
    await tester.pump();
    expect(copied, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('code copy catches platform failure, retries and resets safely',
      (tester) async {
    try {
      await _mount(tester, child: const AiMarkdownMessage(markdown: code));
      final rendered = tester
          .widget<SelectableText>(find.byWidgetPredicate((widget) =>
              widget is SelectableText &&
              widget.style?.fontFamily == 'monospace'))
          .data!;
      fail = true;
      await tester.tap(find.byTooltip('Copy code'));
      await tester.pumpAndSettle();
      expect(find.text('Could not copy this code.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      fail = false;
      gate = Completer<void>();
      final retry = tester
          .widget<IconButton>(find.ancestor(
              of: find.byTooltip('Copy code'),
              matching: find.byType(IconButton)))
          .onPressed!;
      retry();
      retry();
      await tester.pump();
      expect(find.byKey(const Key('chat-code-copy-error')), findsNothing);
      expect(copied, [rendered, rendered]);
      gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Copied'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byTooltip('Copy code'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
      'streaming code copies visible bytes without stale success after growth',
      (tester) async {
    final markdown = ValueNotifier('```dart\nfinal first = "α";');
    try {
      await _mount(tester,
          child: ValueListenableBuilder<String>(
              valueListenable: markdown,
              builder: (_, text, __) => AiMarkdownMessage(markdown: text)));
      expect(find.textContaining('streaming'), findsOneWidget);
      gate = Completer<void>();
      await tester.tap(find.byTooltip('Copy code'));
      await tester.pump();
      expect(copied.single, contains('final first = "α";'));
      markdown.value = '```dart\nfinal second = "β";\n```';
      await tester.pump();
      gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Copied'), findsNothing);
      expect(find.textContaining('streaming'), findsNothing);
      gate = null;
      await tester.tap(find.byTooltip('Copy code'));
      await tester.pumpAndSettle();
      expect(copied.last, contains('final second = "β";'));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      markdown.dispose();
    }
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets(
        '$brightness code uses theme surfaces at320px2x and cancels disposal timers',
        (tester) async {
      try {
        await _mount(tester,
            child: const AiMarkdownMessage(markdown: code),
            brightness: brightness,
            size: const Size(320, 700),
            scale: 2);
        final surface = find.byKey(const Key('chat-code-surface'));
        final context = tester.element(surface);
        final decoration =
            tester.widget<Container>(surface).decoration! as BoxDecoration;
        expect(decoration.color, ChatReadingStyle.codeSurface(context));
        expect(decoration.border,
            Border.all(color: ChatReadingStyle.codeBorder(context)));
        final header =
            tester.widget<Container>(find.byKey(const Key('chat-code-header')));
        expect(header.color, ChatReadingStyle.codeHeader(context));
        final copy = find.byTooltip('Copy code');
        expect(tester.getSize(copy).height, greaterThanOrEqualTo(48));
        await tester.tap(copy);
        await tester.pumpAndSettle();
        expect(find.byTooltip('Copied'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  }
}
