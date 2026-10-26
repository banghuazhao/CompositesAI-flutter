import 'dart:async';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/model/chat_exchange.dart';
import 'package:swiftcomp/presentation/chat/model/chat_export.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_copy_exchange_button.dart';
import 'package:swiftcomp/presentation/chat/views/message_list.dart';

Message _message(
  String id,
  String role,
  String content, {
  String? parent,
  int timestamp = 100,
}) =>
    Message.fromJson({
      'id': id,
      'role': role,
      'content': content,
      'parentId': parent,
      'timestamp': timestamp,
    });

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
    selectedChat = conversation;
    messages = [question, answer];
  }

  final conversation = Chat(id: 'a', title: 'Exchange A');
  final question = _message('q', 'user', '  碳纖維 α 🌍\n**Question?**  ');
  final answer = _message(
    'a',
    'assistant',
    '\n```dart\nfinal answer = "α";\n```\n\n**Result** 🌍  \n',
    parent: 'q',
    timestamp: 200,
  );
  final files = <ChatFile>[];
  final sends = <String>[];
  bool loading = false;
  bool sending = false;

  @override
  bool get isLoadingMessages => loading;
  @override
  bool get isSendingMessage => sending;
  @override
  bool get canRegenerate => false;
  @override
  List<ChatFile> get pendingFiles => files;
  @override
  Future<void> sendInputMessage(
    String text, {
    VoidCallback? onMessageAccepted,
  }) async {
    sends.add(text);
  }
}

Finder get _button => find.byKey(const ValueKey('chat-copy-exchange-a'));
VoidCallback _callback(WidgetTester tester) =>
    tester.widget<IconButton>(_button).onPressed!;

Future<void> _mount(
  WidgetTester tester,
  _Model model, {
  bool messageList = false,
  bool localized = true,
  bool menuItem = false,
  VoidCallback? onCopied,
  Locale locale = const Locale('en'),
  double scale = 1,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      locale: locale,
      supportedLocales:
          localized ? S.delegate.supportedLocales : const [Locale('en')],
      localizationsDelegates: [
        if (localized) S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: messageList
            ? ChangeNotifierProvider<ChatViewModel>.value(
                value: model,
                child: const MessageList(bottomContentPadding: 20),
              )
            : Align(
                alignment: Alignment.topLeft,
                child: menuItem
                    ? MenuAnchor(
                        menuChildren: [
                          ChatCopyExchangeButton(
                            viewModel: model,
                            answer: model.answer,
                            menuItem: true,
                            onCopied: onCopied,
                          ),
                        ],
                        builder: (context, controller, _) => TextButton(
                          key: const Key('exchange-test-menu'),
                          onPressed: controller.open,
                          child: const Text('More'),
                        ),
                      )
                    : ChatCopyExchangeButton(
                        viewModel: model,
                        answer: model.answer,
                        onCopied: onCopied,
                      ),
              ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _withModel(
  WidgetTester tester,
  Future<void> Function(_Model) action,
) async {
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

  test(
    'explicit nonadjacent parent preserves full raw Markdown and Unicode',
    () {
      final question = _message('q', 'user', '  **碳纖維** 🌍\n  ');
      final unrelated = _message('other', 'user', 'Do not guess this neighbor');
      final answer = _message(
        'a',
        'assistant',
        '\n```dart\nconst x = "α";\n```\n  ',
        parent: 'q',
        timestamp: 200,
      );
      final exchange = ChatExchangeSnapshot.resolve(
        messages: [question, unrelated, answer],
        answer: answer,
      )!;
      expect(exchange.question, same(question));
      expect(
        exchange.toMarkdown(),
        '## Question\n\n${question.content}\n\n## Answer\n\n${answer.content}',
      );
      expect(
        exchange.toMarkdown(questionLabel: '問題', answerLabel: '答案'),
        '## 問題\n\n${question.content}\n\n## 答案\n\n${answer.content}',
      );
      final original = exchange.toMarkdown();
      question.content = 'A changed question';
      answer.content = 'A changed answer';
      expect(exchange.toMarkdown(), original);
      expect(
        exchange.matches(
          ChatExchangeSnapshot.resolve(
            messages: [question, answer],
            answer: answer,
          )!,
        ),
        isFalse,
      );
    },
  );

  test(
    'missing, ambiguous, detached and reversed relationships are rejected',
    () {
      final question = _message('q', 'user', 'Question');
      final answer = _message(
        'a',
        'assistant',
        'Answer',
        parent: 'q',
        timestamp: 200,
      );
      void rejected(List<Message> messages, Message selected) => expect(
            ChatExchangeSnapshot.resolve(messages: messages, answer: selected),
            isNull,
          );
      rejected([question, answer], Message.fromJson(answer.toJson()));
      rejected([question, answer, Message.fromJson(answer.toJson())], answer);
      rejected([question, Message.fromJson(question.toJson()), answer], answer);
      rejected([question, question, answer], answer);
      rejected([answer, question], answer);
      rejected([answer], answer);
      rejected([_message('q', 'assistant', 'Not a user'), answer], answer);
      for (final parent in <String?>[null, '', ' ', 'missing', ' q ']) {
        answer.parentId = parent;
        rejected([question, answer], answer);
      }
      answer.parentId = 'q';
      question.timestamp = 201;
      rejected([question, answer], answer);
      question.timestamp = 100;
      answer.content = ' \n ';
      rejected([question, answer], answer);
      final emptyId = _message('', 'assistant', 'Answer', parent: 'q');
      rejected([question, emptyId], emptyId);
      rejected([question], question);
    },
  );

  test(
    'legacy unknown dates and omitted done flags keep explicit links usable',
    () {
      final question = _message('q', 'user', '', timestamp: 0);
      final answer = _message(
        'a',
        'assistant',
        'Loaded answer',
        parent: 'q',
        timestamp: 0,
      );
      expect(answer.isDone, isFalse);
      expect(
        ChatExchangeSnapshot.resolve(
          messages: [question, answer],
          answer: answer,
        )?.toMarkdown(),
        '## Question\n\n\n\n## Answer\n\nLoaded answer',
      );
    },
  );

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> clipboard;
  Completer<void>? gate;
  var fail = false;
  setUp(() {
    clipboard = [];
    gate = null;
    fail = false;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add((call.arguments as Map)['text'] as String);
        await gate?.future;
        if (fail) throw PlatformException(code: 'clipboard-unavailable');
      }
      return null;
    });
  });
  tearDown(() {
    if (gate != null && !gate!.isCompleted) gate!.complete();
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'clipboard receives exact exchange without mutating any draft data',
    (tester) => _withModel(tester, (model) async {
      const file = ChatFile(id: 'file', name: 'layup.pdf', url: '');
      model.files.add(file);
      model.question.files.add(file);
      model.composerTextController.value = const TextEditingValue(
        text: '  Unsent α\nquestion  ',
        selection: TextSelection.collapsed(offset: 4),
      );
      final draft = model.composerTextController.value;
      final history = model.messages.map((m) => m.toJson()).toList();
      final exportedAt = DateTime.utc(2026, 10, 25);
      final export = ChatExport.toMarkdown(
        title: 'Original',
        messages: model.messages,
        exportedAt: exportedAt,
      );
      await _mount(tester, model);
      final expected = ChatExchangeSnapshot.resolve(
        messages: model.messages,
        answer: model.answer,
      )!
          .toMarkdown();
      await tester.tap(_button);
      await tester.pumpAndSettle();
      expect(clipboard, [expected]);
      expect(find.text('Question and answer copied'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(model.composerTextController.value, draft);
      expect(model.files, [file]);
      expect(model.messages.map((m) => m.toJson()).toList(), history);
      expect(
        ChatExport.toMarkdown(
          title: 'Original',
          messages: model.messages,
          exportedAt: exportedAt,
        ),
        export,
      );
      expect(model.sends, isEmpty);
      expect(tester.takeException(), isNull);
    }),
  );

  for (final unavailable in [
    'loading',
    'sending',
    'logout',
    'parent',
    'dispose',
  ]) {
    testWidgets(
      '$unavailable disables copying and rejects a retained callback',
      (tester) => _withModel(tester, (model) async {
        await _mount(tester, model);
        final stale = _callback(tester);
        switch (unavailable) {
          case 'loading':
            model.loading = true;
          case 'sending':
            model.sending = true;
          case 'logout':
            model.isLoggedIn = false;
          case 'parent':
            model.answer.parentId = 'missing';
          case 'dispose':
            model.dispose();
        }
        model.notifyListeners();
        stale();
        await tester.pumpAndSettle();
        expect(tester.widget<IconButton>(_button).onPressed, isNull);
        expect(clipboard, isEmpty);
        expect(tester.takeException(), isNull);
      }),
    );
  }

  for (final changed in [
    'question',
    'answer',
    'timestamp',
    'replacement',
    'content ABA',
    'chat ABA',
    'account ABA',
  ]) {
    testWidgets(
      '$changed invalidates old copy callbacks after rebuilding',
      (tester) => _withModel(tester, (model) async {
        await _mount(tester, model);
        final stale = _callback(tester);
        switch (changed) {
          case 'question':
            model.question.content += ' Changed';
          case 'answer':
            model.answer.content += ' Changed';
          case 'timestamp':
            model.answer.timestamp++;
          case 'replacement':
            model.messages = [
              model.question,
              Message.fromJson(model.answer.toJson()),
            ];
          case 'content ABA':
            final original = model.question.content;
            model.question.content = 'An intermediate edit';
            model.notifyListeners();
            model.question.content = original;
          case 'chat ABA':
            model.selectedChat = Chat(id: 'b', title: 'B');
            model.selectedChat = model.conversation;
          case 'account ABA':
            final original = model.user;
            model.user = User(id: 'account-b', email: 'b@example.test');
            model.notifyListeners();
            model.user = original;
        }
        model.notifyListeners();
        await tester.pumpAndSettle();
        stale();
        await tester.pumpAndSettle();
        expect(clipboard, isEmpty);
        expect(tester.takeException(), isNull);
      }),
    );
  }

  testWidgets(
    'pending duplicate taps, platform failure and retry are recoverable',
    (tester) => _withModel(tester, (model) async {
      await _mount(tester, model);
      final copy = _callback(tester);
      gate = Completer<void>();
      fail = true;
      copy();
      copy();
      await tester.pump();
      expect(clipboard, hasLength(1));
      expect(tester.widget<IconButton>(_button).onPressed, isNull);
      gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Could not copy this exchange.'), findsOneWidget);
      expect(tester.widget<IconButton>(_button).onPressed, isNotNull);
      fail = false;
      gate = null;
      await tester.tap(_button);
      await tester.pumpAndSettle();
      expect(clipboard, hasLength(2));
      expect(clipboard.last, clipboard.first);
      expect(find.text('Question and answer copied'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    }),
  );

  for (final changed in ['answer', 'chat', 'dispose', 'unmount']) {
    testWidgets(
      'pending $changed keeps its snapshot and suppresses stale feedback',
      (tester) => _withModel(tester, (model) async {
        await _mount(tester, model);
        final original = ChatExchangeSnapshot.resolve(
          messages: model.messages,
          answer: model.answer,
        )!
            .toMarkdown();
        gate = Completer<void>();
        await tester.tap(_button);
        await tester.pump();
        switch (changed) {
          case 'answer':
            model.answer.content = 'A changed answer after tap';
            model.notifyListeners();
          case 'chat':
            model.selectedChat = Chat(id: 'b', title: 'B');
            model.notifyListeners();
          case 'dispose':
            model.dispose();
          case 'unmount':
            await tester.pumpWidget(const SizedBox.shrink());
        }
        await tester.pump();
        gate!.complete();
        await tester.pumpAndSettle();
        expect(clipboard, [original]);
        expect(find.text('Question and answer copied'), findsNothing);
        expect(find.text('Could not copy this exchange.'), findsNothing);
        expect(tester.takeException(), isNull);
      }),
    );
  }

  testWidgets(
    'covered route rejects old actions and pending success feedback',
    (tester) => _withModel(tester, (model) async {
      final navigator = GlobalKey<NavigatorState>();
      await _mount(tester, model, navigatorKey: navigator);
      final stale = _callback(tester);
      gate = Completer<void>();
      stale();
      await tester.pump();
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Cover page')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      stale();
      gate!.complete();
      await tester.pumpAndSettle();
      expect(clipboard, hasLength(1));
      expect(find.text('Question and answer copied'), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      stale();
      await tester.pumpAndSettle();
      expect(clipboard, hasLength(1));
      expect(tester.takeException(), isNull);
    }),
  );

  testWidgets(
    'folded answer copies its complete text while original Copy stays',
    (tester) => _withModel(tester, (model) async {
      model.answer.content = '${'Carbon α results. ' * 100}\n'
          '```text\nTAIL_VALUE = 135.123456789\n```\n  ';
      await _mount(tester, model, messageList: true);
      final toggle = find.byKey(const ValueKey('chat-answer-toggle-a'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-answer-preview-a')),
        findsOneWidget,
      );
      expect(find.byTooltip('Copy message'), findsNWidgets(2));
      final more = find.byKey(const ValueKey('chat-message-more-a'));
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      await tester.tap(_button);
      await tester.pumpAndSettle();
      expect(
        clipboard.single,
        ChatExchangeSnapshot.resolve(
          messages: model.messages,
          answer: model.answer,
        )!
            .toMarkdown(),
      );
      expect(clipboard.single, contains('TAIL_VALUE = 135.123456789'));
      expect(model.answer.content, endsWith('```\n  '));
      expect(tester.takeException(), isNull);
    }),
  );

  testWidgets(
    'English fallbacks work without app delegates',
    (tester) => _withModel(tester, (model) async {
      await _mount(tester, model, localized: false);
      expect(find.byTooltip('Copy question and answer'), findsOneWidget);
      await tester.tap(_button);
      await tester.pumpAndSettle();
      expect(clipboard.single, startsWith('## Question\n\n'));
      expect(clipboard.single, contains('\n\n## Answer\n\n'));
      expect(tester.takeException(), isNull);
    }),
  );

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets(
      '$locale copy control fits320px2x and localizes Markdown headings',
      (tester) => _withModel(tester, (model) async {
        await _mount(tester, model, locale: locale, scale: 2);
        final strings = S.of(tester.element(_button));
        expect(
          tester.widget<IconButton>(_button).tooltip,
          strings.Chat_copy_exchange,
        );
        expect(tester.getSize(_button).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(_button).height, greaterThanOrEqualTo(48));
        expect(_button.hitTestable(), findsOneWidget);
        await tester.tap(_button);
        await tester.pumpAndSettle();
        expect(
          clipboard.single,
          '## ${strings.Chat_exchange_question}\n\n${model.question.content}'
          '\n\n## ${strings.Chat_exchange_answer}\n\n${model.answer.content}',
        );
        expect(find.text(strings.Chat_exchange_copied), findsOneWidget);
        expect(tester.takeException(), isNull);
      }),
    );
  }

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK')
  ]) {
    testWidgets(
        '$locale exchange menu stays open with inline success at320px2x',
        (tester) => _withModel(tester, (model) async {
              var copied = 0;
              await _mount(tester, model,
                  menuItem: true,
                  locale: locale,
                  scale: 2,
                  onCopied: () => copied++);
              await tester.tap(find.byKey(const Key('exchange-test-menu')));
              await tester.pumpAndSettle();
              final strings = S.of(tester.element(_button));
              expect(tester.widget<MenuItemButton>(_button).closeOnActivate,
                  isFalse);
              expect(tester.getSize(_button).height, greaterThanOrEqualTo(48));
              await tester.tap(_button);
              await tester.pumpAndSettle();
              expect(_button.hitTestable(), findsOneWidget);
              expect(find.text(strings.Chat_exchange_copied), findsOneWidget);
              expect(find.byType(SnackBar), findsNothing);
              expect(find.byIcon(Icons.check_rounded), findsOneWidget);
              expect(copied, 1);
              expect(clipboard.single, contains(model.answer.content));
              expect(tester.takeException(), isNull);
            }));
  }

  testWidgets(
      'menu clipboard failure stays visible and retryable without dismissing',
      (tester) => _withModel(tester, (model) async {
            await _mount(tester, model, menuItem: true);
            await tester.tap(find.byKey(const Key('exchange-test-menu')));
            await tester.pumpAndSettle();
            fail = true;
            await tester.tap(_button);
            await tester.pumpAndSettle();
            expect(find.text('Could not copy this exchange.'), findsOneWidget);
            expect(tester.widget<MenuItemButton>(_button).onPressed, isNotNull);
            expect(_button.hitTestable(), findsOneWidget);
            expect(find.byType(SnackBar), findsNothing);
            fail = false;
            await tester.tap(_button);
            await tester.pumpAndSettle();
            expect(clipboard, hasLength(2));
            expect(clipboard.first, clipboard.last);
            expect(find.text('Question and answer copied'), findsOneWidget);
            expect(find.text('Could not copy this exchange.'), findsNothing);
            expect(find.byType(SnackBar), findsNothing);
            expect(tester.takeException(), isNull);
          }));

  testWidgets(
      'menu keeps pending copy mounted and ignores duplicate activation',
      (tester) => _withModel(tester, (model) async {
            await _mount(tester, model, menuItem: true);
            await tester.tap(find.byKey(const Key('exchange-test-menu')));
            await tester.pumpAndSettle();
            final callback = tester.widget<MenuItemButton>(_button).onPressed!;
            gate = Completer<void>();
            try {
              callback();
              callback();
              await tester.pump();
              expect(clipboard, hasLength(1));
              expect(_button, findsOneWidget);
              expect(find.byType(CircularProgressIndicator), findsOneWidget);
              expect(tester.widget<MenuItemButton>(_button).onPressed, isNull);
              gate!.complete();
              await tester.pumpAndSettle();
              expect(find.text('Question and answer copied'), findsOneWidget);
              expect(find.byType(SnackBar), findsNothing);
              expect(tester.takeException(), isNull);
            } finally {
              if (!gate!.isCompleted) gate!.complete();
              await tester.pumpAndSettle();
            }
          }));
}
