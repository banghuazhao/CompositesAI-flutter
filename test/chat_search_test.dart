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

class _UseCase extends Fake implements ChatUseCase {
  int requests = 0;

  @override
  Future<List<Message>> fetchMessages(Chat chat) async {
    requests++;
    return [];
  }
}

class _Model extends ChatViewModel {
  _Model(this.useCase)
      : super(
          chatUseCase: useCase,
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'account-a', email: 'a@example.test');
  }

  final _UseCase useCase;
  bool loadingMessages = false;

  @override
  bool get isLoadingMessages => loadingMessages;

  void show(Chat? chat, List<Message> history) {
    selectedChat = chat;
    messages = List.of(history);
    notifyListeners();
  }

  void changed() => notifyListeners();
}

const _open = Key('open-search');
const _field = Key('chat-search-field');
const _results = Key('chat-search-results');
const _close = Key('chat-search-close');
final _chatA = Chat(id: 'a', title: 'Laminate A');
final _chatB = Chat(id: 'b', title: 'Laminate B');

Message _message(String text, {String role = 'assistant'}) =>
    Message(role: role, content: text);

class _Launcher extends StatelessWidget {
  const _Launcher(this.model);

  final ChatViewModel model;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            key: _open,
            onPressed: () => showChatSearchSheet(context, model),
            child: const Text('Open search'),
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
  ValueNotifier<bool>? hostPresent,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
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
    home: hostPresent == null
        ? _Launcher(model)
        : ValueListenableBuilder<bool>(
            valueListenable: hostPresent,
            builder: (_, present, __) => present
                ? _Launcher(model)
                : const Scaffold(body: Text('Replacement host')),
          ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.byKey(_open));
  await tester.pumpAndSettle();
  expect(find.byKey(_field), findsOneWidget);
}

Future<void> _query(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(_field), text);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('loaded-message search', () {
    test('is literal and case insensitive with one result per message', () {
      final messages = [
        _message('Compare [0/90]+ with [0/90]+', role: 'user'),
        _message('COMPARE [0/90]+ with aluminum'),
        _message('Compare 0 or 90'),
      ];
      final results = ChatMessageSearch.find(messages, '  compare [0/90]+  ');
      expect(results.map((result) => result.messageIndex), [0, 1]);
      expect(results.map((result) => result.role), ['user', 'assistant']);
      expect(ChatMessageSearch.find(messages, '.*'), isEmpty);
      expect(ChatMessageSearch.find(messages, '   '), isEmpty);
      expect(ChatMessageSearch.find([], 'compare'), isEmpty);
    });

    test('original Unicode indices and complete graphemes form excerpts', () {
      const family = '👨‍👩‍👧‍👦';
      final content = '${'İ' * 80}${family * 30} NEEDLE ${'e\u0301' * 200}';
      final result =
          ChatMessageSearch.find([_message(content)], 'needle').single;
      final excerpt = result.excerpt;
      expect(excerpt, contains('NEEDLE'));
      expect(excerpt.startsWith('…$family'), isTrue);
      expect(excerpt.endsWith('e\u0301…'), isTrue);
      expect(excerpt.runes, isNot(contains(0xfffd)));
      expect(ChatMessageSearch.find([_message('ÉPOXY 碳纖維')], 'époxy'),
          hasLength(1));
      expect(
          ChatMessageSearch.find([_message('ÉPOXY 碳纖維')], '碳纖維'), hasLength(1));
    });

    test('long messages yield bounded immutable excerpts without mutation', () {
      final message = _message('${'a' * 20000} TARGET ${'b' * 20000}');
      final original = message.content;
      final result = ChatMessageSearch.find([message], 'target').single;
      message.content = 'New streaming value';
      expect(result.excerpt.length,
          lessThanOrEqualTo(ChatMessageSearch.maximumExcerptLength + 2));
      expect(result.excerpt, contains('TARGET'));
      expect(result.excerpt.startsWith('…'), isTrue);
      expect(result.excerpt.endsWith('…'), isTrue);
      expect(original, contains(' TARGET '));
      expect(message.content, 'New streaming value');
      expect(ChatMessageSearch.find([message], 'target'), isEmpty);
    });
  });

  late _UseCase useCase;
  late _Model model;
  late List<String> copied;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    useCase = _UseCase();
    model = _Model(useCase)
      ..show(_chatA, [
        _message('Carbon laminate question', role: 'user'),
        _message('Carbon elastic response'),
        _message('Glass response'),
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

  testWidgets('search, copy and clear retain drafts and complete history',
      (tester) async {
    model.composerTextController.text = '  Unsent draft\n';
    final history = List<Message>.of(model.messages);
    await _pump(tester, model);
    await _openSearch(tester);
    expect(
        find.text('Enter text to search this conversation.'), findsOneWidget);
    await _query(tester, 'CARBON');
    expect(find.text('2 matching messages'), findsOneWidget);
    expect(find.text('Carbon laminate question'), findsOneWidget);
    expect(find.text('Carbon elastic response'), findsOneWidget);
    expect(find.text('Glass response'), findsNothing);
    await tester.tap(find.byKey(const Key('chat-search-copy-1')));
    await tester.pumpAndSettle();
    expect(copied, ['Carbon elastic response']);
    expect(find.text('Excerpt copied'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byKey(_field)).controller!.text, isEmpty);
    expect(
        find.text('Enter text to search this conversation.'), findsOneWidget);
    expect(model.messages, orderedEquals(history));
    expect(model.messages.map((message) => message.content), [
      'Carbon laminate question',
      'Carbon elastic response',
      'Glass response',
    ]);
    expect(model.composerTextController.text, '  Unsent draft\n');
    expect(useCase.requests, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('no matches and in-place streaming edits update loaded results',
      (tester) async {
    await _pump(tester, model);
    await _openSearch(tester);
    await _query(tester, 'delamination');
    expect(find.text('No matching messages.'), findsOneWidget);
    model.messages.last.content = 'Delamination grows';
    model.changed();
    await tester.pumpAndSettle();
    expect(find.text('1 matching messages'), findsOneWidget);
    expect(find.text('Delamination grows'), findsOneWidget);
    model.messages.last.content += ' under cyclic loading';
    model.changed();
    await tester.pumpAndSettle();
    expect(
        find.text('Delamination grows under cyclic loading'), findsOneWidget);
    expect(find.text('Delamination grows'), findsNothing);
    model.messages.add(_message('Delamination second result'));
    model.changed();
    await tester.pumpAndSettle();
    expect(find.text('2 matching messages'), findsOneWidget);
    expect(useCase.requests, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a retained open callback rejects history while messages load',
      (tester) async {
    await _pump(tester, model);
    final open = tester.widget<FilledButton>(find.byKey(_open)).onPressed!;
    model.loadingMessages = true;
    model.changed();
    open();
    await tester.pumpAndSettle();
    expect(find.byKey(_field), findsNothing);
    expect(find.byKey(_open), findsOneWidget);
    expect(useCase.requests, 0);
    model.loadingMessages = false;
    model.changed();
    open();
    await tester.pumpAndSettle();
    expect(find.byKey(_field), findsOneWidget);
    expect(
        find.text('Enter text to search this conversation.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('loading closes covered results and disables retained copy',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await _pump(tester, model, navigatorKey: navigator);
    await _openSearch(tester);
    await _query(tester, 'carbon');
    final oldCopy = tester
        .widget<IconButton>(find.byKey(const Key('chat-search-copy-0')))
        .onPressed!;
    unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Cover page')),
    )));
    await tester.pumpAndSettle();
    // A same-chat refresh may keep the old loaded messages until it finishes.
    model.loadingMessages = true;
    model.changed();
    oldCopy();
    await tester.pumpAndSettle();
    expect(find.text('Cover page'), findsOneWidget);
    expect(copied, isEmpty);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_field), findsNothing);
    expect(find.byKey(_open), findsOneWidget);
    expect(find.text('Carbon elastic response'), findsNothing);
    expect(useCase.requests, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('results are lazy and a late result remains reachable',
      (tester) async {
    model.show(
        _chatA, List.generate(80, (index) => _message('Needle result $index')));
    await _pump(tester, model);
    await _openSearch(tester);
    await _query(tester, 'needle');
    expect(find.text('80 matching messages'), findsOneWidget);
    const last = Key('chat-search-result-79');
    expect(find.byKey(last), findsNothing);
    await tester.scrollUntilVisible(find.byKey(last), 600,
        scrollable: find.descendant(
            of: find.byKey(_results),
            // The one-line editor owns a separate horizontal Scrollable.
            matching: find.byWidgetPredicate((widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down)),
        maxScrolls: 50);
    await tester.pumpAndSettle();
    expect(find.text('Needle result 79'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('switching chats disables stale copy before removing the sheet',
      (tester) async {
    await _pump(tester, model);
    await _openSearch(tester);
    await _query(tester, 'carbon');
    final oldCopy = tester
        .widget<IconButton>(find.byKey(const Key('chat-search-copy-0')))
        .onPressed!;
    model.show(_chatB, [_message('Private B content')]);
    oldCopy();
    await tester.pumpAndSettle();
    expect(find.byKey(_field), findsNothing);
    expect(copied, isEmpty);
    expect(find.byKey(_open), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final change in ['account', 'logout', 'dispose']) {
    testWidgets('$change closes search even while another route covers it',
        (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await _pump(tester, model, navigatorKey: navigator);
      await _openSearch(tester);
      await _query(tester, 'carbon');
      unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Cover page')),
      )));
      await tester.pumpAndSettle();
      if (change == 'dispose') {
        model.dispose();
      } else if (change == 'account') {
        model.user = User(id: 'account-b', email: 'b@example.test');
        model.changed();
      } else {
        model.isLoggedIn = false;
        model.changed();
      }
      await tester.pumpAndSettle();
      expect(find.text('Cover page'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(_field), findsNothing);
      expect(find.byKey(_open), findsOneWidget);
      expect(find.text('Carbon elastic response'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('removing the caller closes only its covered search route',
      (tester) async {
    final host = ValueNotifier(true);
    addTearDown(host.dispose);
    final navigator = GlobalKey<NavigatorState>();
    await _pump(tester, model, navigatorKey: navigator, hostPresent: host);
    await _openSearch(tester);
    await _query(tester, 'carbon');
    unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Cover page')),
    )));
    await tester.pumpAndSettle();
    host.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Cover page'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Replacement host'), findsOneWidget);
    expect(find.byKey(_field), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('repeated close is safe and reopening starts with an empty query',
      (tester) async {
    await _pump(tester, model);
    await _openSearch(tester);
    await _query(tester, 'carbon');
    final close = tester.widget<IconButton>(find.byKey(_close)).onPressed!;
    close();
    close();
    await tester.pumpAndSettle();
    expect(find.byKey(_open), findsOneWidget);
    await _openSearch(tester);
    expect(
        tester.widget<TextField>(find.byKey(_field)).controller!.text, isEmpty);
    expect(
        find.text('Enter text to search this conversation.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets(
        '${locale.toLanguageTag()} supports 320px, 2x text and keyboard',
        (tester) async {
      await _pump(tester, model,
          locale: locale,
          size: const Size(320, 640),
          scale: 2,
          keyboardHeight: 240);
      await _openSearch(tester);
      final strings = S.of(tester.element(find.byKey(_field)));
      expect(find.text(strings.Chat_find_in_chat), findsOneWidget);
      expect(find.text(strings.Chat_search_loaded_messages), findsOneWidget);
      await _query(tester, 'carbon');
      expect(find.text(strings.Chat_search_match_count(2)), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
