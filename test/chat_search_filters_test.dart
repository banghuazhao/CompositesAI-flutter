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
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/model/chat_message_search.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_search_sheet.dart';

class _Backend extends Fake implements ChatUseCase {
  int requests = 0;

  @override
  Future<List<Message>> fetchMessages(Chat chat) async {
    requests++;
    return [];
  }
}

class _Model extends ChatViewModel {
  _Model(this.backend)
      : super(
          chatUseCase: backend,
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'account-a', email: 'a@example.test');
  }

  final _Backend backend;
  bool streaming = false;
  @override
  bool get isSendingMessage => streaming;

  void show(Chat chat, List<Message> history) {
    selectedChat = chat;
    messages = List.of(history);
    notifyListeners();
  }

  void changed() => notifyListeners();
}

Message _message(String role, String text) =>
    Message(role: role, content: text);
final _chatA = Chat(id: 'a', title: 'A');
final _chatB = Chat(id: 'b', title: 'B');
const _open = Key('open-filter-search');
const _field = Key('chat-search-field');
const _results = Key('chat-search-results');
const _close = Key('chat-search-close');
Key _filterKey(ChatMessageSearchFilter filter) =>
    ValueKey('chat-search-filter-${filter.name}');

class _Launcher extends StatelessWidget {
  const _Launcher(this.model);
  final ChatViewModel model;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            key: _open,
            onPressed: () => showChatSearchSheet(context, model),
            child: const Text('Find'),
          ),
        ),
      );
}

Future<void> _pump(
  WidgetTester tester,
  ChatViewModel model, {
  Locale locale = const Locale('en'),
  Size size = const Size(600, 800),
  double scale = 1,
  double keyboardHeight = 0,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewInsets: EdgeInsets.only(bottom: keyboardHeight),
        ),
        child: child!,
      ),
      home: _Launcher(model),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_open));
  await tester.pumpAndSettle();
}

Future<void> _query(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(_field), text);
  await tester.pumpAndSettle();
}

Future<void> _choose(
  WidgetTester tester,
  ChatMessageSearchFilter filter,
) async {
  final finder = find.byKey(_filterKey(filter));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.widget<ChoiceChip>(finder).selected, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('role filtering model', () {
    test('the optional filter preserves All and original loaded indices', () {
      final messages = [
        _message('system', 'Carbon context'),
        _message('user', 'CARBON [0/90]+ question'),
        _message('assistant', 'Carbon [0/90]+ answer'),
        _message('user', 'Glass question'),
        _message('assistant', 'Carbon later answer'),
      ];
      expect(
        ChatMessageSearch.find(messages, 'carbon').map((m) => m.messageIndex),
        [0, 1, 2, 4],
      );
      expect(
        ChatMessageSearch.find(
          messages,
          'carbon',
          filter: ChatMessageSearchFilter.all,
        ).map((m) => m.messageIndex),
        [0, 1, 2, 4],
      );
      expect(
        ChatMessageSearch.find(
          messages,
          'carbon',
          filter: ChatMessageSearchFilter.questions,
        ).map((m) => m.messageIndex),
        [1],
      );
      expect(
        ChatMessageSearch.find(
          messages,
          'carbon',
          filter: ChatMessageSearchFilter.answers,
        ).map((m) => m.messageIndex),
        [2, 4],
      );
    });

    test('literal Unicode matches retain their source excerpt offsets', () {
      final content = '${'İ' * 90}${'👨‍👩‍👧‍👦' * 12} ÉPOXY [0/90]+ 碳纖維';
      final messages = [
        _message('user', content),
        _message('assistant', content),
      ];
      for (final filter in [
        ChatMessageSearchFilter.questions,
        ChatMessageSearchFilter.answers,
      ]) {
        final result = ChatMessageSearch.find(
          messages,
          'époxy [0/90]+',
          filter: filter,
        ).single;
        expect(result.excerpt, contains('ÉPOXY [0/90]+ 碳纖維'));
        expect(result.excerpt.runes, isNot(contains(0xfffd)));
        expect(ChatMessageSearch.find(messages, '.*', filter: filter), isEmpty);
        expect(
          ChatMessageSearch.find(messages, '碳纖維', filter: filter),
          hasLength(1),
        );
        expect(ChatMessageSearch.find(messages, '  ', filter: filter), isEmpty);
      }
    });

    test(
      'filtered snapshots remain immutable after in-place message updates',
      () {
        final question = _message('user', 'Carbon question');
        final answer = _message('assistant', '${'x' * 4000} CARBON tail');
        final messages = [question, answer];
        final matches = ChatMessageSearch.find(
          messages,
          'carbon',
          filter: ChatMessageSearchFilter.answers,
        );
        final snapshot = matches.single;
        answer.content = 'New answer';
        expect(snapshot.messageIndex, 1);
        expect(snapshot.excerpt, contains('CARBON tail'));
        expect(
          snapshot.excerpt.length,
          lessThanOrEqualTo(ChatMessageSearch.maximumExcerptLength + 2),
        );
        expect(() => matches.clear(), throwsUnsupportedError);
        expect(question.content, 'Carbon question');
        expect(answer.content, 'New answer');
        expect(
          ChatMessageSearch.find(
            messages,
            'carbon',
            filter: ChatMessageSearchFilter.answers,
          ),
          isEmpty,
        );
      },
    );
  });

  late _Backend backend;
  late _Model model;
  late List<String> copied;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    backend = _Backend();
    model = _Model(backend)
      ..show(_chatA, [
        _message('user', 'Carbon [0/90]+ question'),
        _message('assistant', 'Carbon [0/90]+ answer'),
        _message('user', 'Glass second question'),
        _message('assistant', 'Glass second answer'),
      ]);
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

  testWidgets('default All, role counts and Copy retain original indices', (
    tester,
  ) async {
    model.composerTextController.value = const TextEditingValue(
      text: '  Keep draft\n',
      selection: TextSelection(baseOffset: 5, extentOffset: 2),
    );
    final draft = model.composerTextController.value;
    final history = model.messages.map((message) => message.toJson()).toList();
    await _pump(tester, model);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(_filterKey(ChatMessageSearchFilter.all)),
          )
          .selected,
      isTrue,
    );
    await _query(tester, 'carbon');
    expect(find.text('2 matching messages'), findsOneWidget);
    final oldQuestionCopy = tester
        .widget<IconButton>(find.byKey(const Key('chat-search-copy-0')))
        .onPressed!;
    await _choose(tester, ChatMessageSearchFilter.answers);
    oldQuestionCopy();
    await tester.pumpAndSettle();
    expect(copied, isEmpty);
    expect(find.text('1 matching messages'), findsOneWidget);
    expect(find.byKey(const Key('chat-search-result-0')), findsNothing);
    expect(find.byKey(const Key('chat-search-result-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-search-copy-1')));
    await tester.pumpAndSettle();
    expect(copied, ['Carbon [0/90]+ answer']);
    await _choose(tester, ChatMessageSearchFilter.questions);
    expect(find.byKey(const Key('chat-search-result-0')), findsOneWidget);
    expect(find.byKey(const Key('chat-search-result-1')), findsNothing);
    expect(model.messages.map((message) => message.toJson()).toList(), history);
    expect(model.composerTextController.value, draft);
    expect(backend.requests, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'filter survives query changes, clearing and literal no matches',
    (tester) async {
      await _pump(tester, model);
      await _choose(tester, ChatMessageSearchFilter.answers);
      await _query(tester, 'glass');
      expect(find.text('1 matching messages'), findsOneWidget);
      expect(find.text('Glass second answer'), findsOneWidget);
      expect(find.text('Glass second question'), findsNothing);
      await _query(tester, '.*');
      expect(find.text('0 matching messages'), findsOneWidget);
      expect(find.text('No matching messages.'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter text to search this conversation.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(_filterKey(ChatMessageSearchFilter.answers)),
            )
            .selected,
        isTrue,
      );
      await _query(tester, '[0/90]+');
      expect(find.text('Carbon [0/90]+ answer'), findsOneWidget);
      expect(find.text('1 matching messages'), findsOneWidget);
      expect(backend.requests, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('streamed and newly loaded answers retain the chosen filter', (
    tester,
  ) async {
    await _pump(tester, model);
    await _query(tester, 'carbon');
    await _choose(tester, ChatMessageSearchFilter.answers);
    final streaming = _message('assistant', '');
    model.messages.add(streaming);
    model.streaming = true;
    model.changed();
    await tester.pumpAndSettle();
    expect(find.text('1 matching messages'), findsOneWidget);
    streaming.content = 'Carbon streaming answer';
    model.changed();
    await tester.pumpAndSettle();
    expect(find.text('2 matching messages'), findsOneWidget);
    expect(find.byKey(const Key('chat-search-result-4')), findsOneWidget);
    model.messages.add(_message('user', 'Carbon new question'));
    model.changed();
    await tester.pumpAndSettle();
    expect(find.text('2 matching messages'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(_filterKey(ChatMessageSearchFilter.answers)),
          )
          .selected,
      isTrue,
    );
    await _choose(tester, ChatMessageSearchFilter.all);
    expect(find.text('4 matching messages'), findsOneWidget);
    expect(backend.requests, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'filtered results stay lazy and Copy uses the last original index',
    (tester) async {
      model.show(
        _chatA,
        List.generate(
          80,
          (i) => _message(i.isEven ? 'user' : 'assistant', 'Needle result $i'),
        ),
      );
      await _pump(tester, model);
      await _query(tester, 'needle');
      await _choose(tester, ChatMessageSearchFilter.answers);
      expect(find.text('40 matching messages'), findsOneWidget);
      const last = Key('chat-search-result-79');
      expect(find.byKey(last), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(last),
        600,
        scrollable: find.descendant(
          of: find.byKey(_results),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        ),
        maxScrolls: 50,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-search-copy-79')));
      await tester.pumpAndSettle();
      expect(copied, ['Needle result 79']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('covered filter callbacks cannot change the active selection', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await _pump(tester, model, navigatorKey: navigator);
    await _query(tester, 'carbon');
    await _choose(tester, ChatMessageSearchFilter.answers);
    final questions = tester
        .widget<ChoiceChip>(
          find.byKey(_filterKey(ChatMessageSearchFilter.questions)),
        )
        .onSelected!;
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    questions(true);
    await tester.pumpAndSettle();
    expect(find.text('Cover'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(_filterKey(ChatMessageSearchFilter.answers)),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Carbon [0/90]+ answer'), findsOneWidget);
    expect(find.text('Carbon [0/90]+ question'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'reopen starts at All and cannot reuse disposed filter callbacks',
    (tester) async {
      await _pump(tester, model);
      await _choose(tester, ChatMessageSearchFilter.questions);
      final answers = tester
          .widget<ChoiceChip>(
            find.byKey(_filterKey(ChatMessageSearchFilter.answers)),
          )
          .onSelected!;
      await tester.tap(find.byKey(_close));
      await tester.pumpAndSettle();
      answers(true);
      await tester.tap(find.byKey(_open));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(_filterKey(ChatMessageSearchFilter.all)),
            )
            .selected,
        isTrue,
      );
      expect(
        tester.widget<TextField>(find.byKey(_field)).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final transition in ['chat', 'ABA', 'account', 'logout', 'dispose']) {
    testWidgets(
      '$transition retires filters and Copy beneath a covering route',
      (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        await _pump(tester, model, navigatorKey: navigator);
        await _query(tester, 'carbon');
        await _choose(tester, ChatMessageSearchFilter.answers);
        final questions = tester
            .widget<ChoiceChip>(
              find.byKey(_filterKey(ChatMessageSearchFilter.questions)),
            )
            .onSelected!;
        final copy = tester
            .widget<IconButton>(find.byKey(const Key('chat-search-copy-1')))
            .onPressed!;
        unawaited(
          navigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Cover')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        switch (transition) {
          case 'chat':
            model.show(_chatB, [_message('assistant', 'Other private answer')]);
          case 'ABA':
            final history = List<Message>.of(model.messages);
            model.show(_chatB, []);
            model.show(_chatA, history);
          case 'account':
            model.user = User(id: 'account-b', email: 'b@example.test');
            model.changed();
          case 'logout':
            model.isLoggedIn = false;
            model.changed();
          case 'dispose':
            model.dispose();
        }
        questions(true);
        copy();
        await tester.pumpAndSettle();
        expect(copied, isEmpty);
        expect(find.text('Cover'), findsOneWidget);
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        expect(find.byKey(_field), findsNothing);
        expect(find.byKey(_open), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets(
      '$locale filters wrap with48px targets at320px/2x and keyboard',
      (tester) async {
        await _pump(
          tester,
          model,
          locale: locale,
          size: const Size(320, 700),
          scale: 2,
          keyboardHeight: 240,
        );
        final strings = S.of(tester.element(find.byKey(_field)));
        for (final filter in ChatMessageSearchFilter.values) {
          final key = find.byKey(_filterKey(filter));
          final size = tester.getSize(key);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
          final rect = tester.getRect(key);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
        }
        expect(find.text(strings.Chat_search_all), findsOneWidget);
        expect(find.text(strings.Chat_search_questions), findsOneWidget);
        expect(find.text(strings.Chat_search_answers), findsOneWidget);
        await _choose(tester, ChatMessageSearchFilter.questions);
        await _query(tester, 'carbon');
        expect(find.text(strings.Chat_search_match_count(1)), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
