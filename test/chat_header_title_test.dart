import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_header_title.dart';

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

  bool loading = false;
  bool get observing => hasListeners;

  @override
  bool get isLoadingMessages => loading;

  void show(Chat? chat) {
    selectedChat = chat;
    notifyListeners();
  }

  void changed() => notifyListeners();
}

const _title = Key('chat-header-title');
const _semantics = Key('chat-header-title-semantics');
Finder get _tooltip =>
    find.ancestor(of: find.byKey(_title), matching: find.byType(Tooltip));

Finder _tooltipText(String text) => find.byWidgetPredicate(
    (widget) => widget is Text && widget.textSpan?.toPlainText() == text);

String _displayed(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(_title)).data!;

Future<void> _pump(
  WidgetTester tester,
  ChatViewModel model, {
  Locale locale = const Locale('en'),
  bool localized = true,
  double scale = 1,
  ValueNotifier<bool>? present,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 800);
  addTearDown(tester.view.reset);

  Widget page() => Scaffold(
        appBar: AppBar(
          title: ChatHeaderTitle(viewModel: model),
          leading: IconButton(
              key: const Key('header-menu'),
              tooltip: 'Menu',
              onPressed: () {},
              icon: const Icon(Icons.menu)),
          actions: [
            for (final action in ['search', 'export', 'account'])
              IconButton(
                key: ValueKey('header-$action'),
                constraints:
                    const BoxConstraints.tightFor(width: 48, height: 48),
                tooltip: action,
                onPressed: () {},
                icon: const Icon(Icons.more_horiz),
              ),
          ],
        ),
        body: const Text('History stays here'),
      );

  await tester.pumpWidget(MaterialApp(
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
      data:
          MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: present == null
        ? page()
        : ValueListenableBuilder<bool>(
            valueListenable: present,
            builder: (_, shown, __) =>
                shown ? page() : const Scaffold(body: Text('Replacement page')),
          ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _showTitle(WidgetTester tester, String title) async {
  expect(_tooltip, findsOneWidget);
  expect(tester.widget<Tooltip>(_tooltip).message, title);
  await tester.longPress(find.byKey(_title));
  await tester.pump(const Duration(milliseconds: 200));
  expect(_tooltipText(title), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Model model;
  late Chat conversation;

  setUp(() {
    model = _Model();
    conversation = Chat(id: 'a', title: 'Carbon laminate α');
    model.show(conversation);
  });
  tearDown(() => model.dispose());

  testWidgets('active title updates on rename, switch, loading and New chat',
      (tester) async {
    await _pump(tester, model);
    expect(_displayed(tester), conversation.title);
    conversation.title = 'Renamed laminate';
    model.changed();
    await tester.pumpAndSettle();
    expect(_displayed(tester), 'Renamed laminate');
    final next = Chat(id: 'b', title: 'Glass laminate');
    model.loading = true;
    model.show(next);
    await tester.pumpAndSettle();
    expect(_displayed(tester), next.title);
    model.loading = false;
    model.changed();
    await tester.pumpAndSettle();
    expect(_displayed(tester), next.title);
    model.show(null);
    await tester.pumpAndSettle();
    expect(_displayed(tester), 'Chat');
    expect(_tooltip, findsNothing);
    expect(find.text('History stays here'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('full title semantics and tooltip accompany single-line ellipsis',
      (tester) async {
    conversation.title = '${'Very long laminate design title ' * 8}碳纖維';
    await _pump(tester, model);
    final label = tester.widget<Text>(find.byKey(_title));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
    expect(label.data, conversation.title);
    final semantics = tester.widget<Semantics>(find.byKey(_semantics));
    expect(semantics.properties.label, conversation.title);
    expect(semantics.properties.header, isTrue);
    await _showTitle(tester, conversation.title);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final transition in [
    'rename',
    'switch',
    'new',
    'logout',
    'account',
    'dispose',
  ]) {
    testWidgets('$transition removes an already open private title tooltip',
        (tester) async {
      await _pump(tester, model);
      final previous = conversation.title;
      await _showTitle(tester, previous);
      switch (transition) {
        case 'rename':
          conversation.title = 'New title';
          model.changed();
        case 'switch':
          model.show(Chat(id: 'b', title: 'Another conversation'));
        case 'new':
          model.show(null);
        case 'logout':
          // Intentionally retain selectedChat to exercise the display guard.
          model.isLoggedIn = false;
          model.changed();
        case 'account':
          // A selected record from A must not become B's visible title.
          model.user = User(id: 'account-b', email: 'b@example.test');
          model.changed();
        case 'dispose':
          model.dispose();
      }
      await tester.pumpAndSettle();
      expect(_tooltipText(previous), findsNothing);
      expect(find.text(previous), findsNothing);
      if (['new', 'logout', 'account', 'dispose'].contains(transition)) {
        expect(_displayed(tester), 'Chat');
        expect(_tooltip, findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('a fresh record in a new session may display its own title',
      (tester) async {
    await _pump(tester, model);
    model.user = User(id: 'account-b', email: 'b@example.test');
    model.changed();
    await tester.pumpAndSettle();
    expect(_displayed(tester), 'Chat');
    model.show(Chat(id: conversation.id, title: 'B private conversation'));
    await tester.pumpAndSettle();
    expect(_displayed(tester), 'B private conversation');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('removing the header retires its overlay and all model listeners',
      (tester) async {
    final present = ValueNotifier(true);
    addTearDown(present.dispose);
    await _pump(tester, model, present: present);
    expect(model.observing, isTrue);
    await _showTitle(tester, conversation.title);
    present.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Replacement page'), findsOneWidget);
    expect(_tooltipText(conversation.title), findsNothing);
    expect(model.observing, isFalse);
    model.changed();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an already disposed model and absent app strings are safe',
      (tester) async {
    model.dispose();
    await _pump(tester, model, localized: false);
    expect(_displayed(tester), 'Chat');
    expect(_tooltip, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets(
        '$locale blank/long titles fit320px at2x without shrinking actions',
        (tester) async {
      conversation.title = '  \n ';
      await _pump(tester, model, locale: locale, scale: 2);
      final strings = S.of(tester.element(find.byKey(_title)));
      expect(_displayed(tester), strings.Chat_untitled_chat);
      conversation.title = '${'Carbon 纖維 laminate ' * 8}α';
      model.changed();
      await tester.pumpAndSettle();
      expect(_displayed(tester), conversation.title);
      for (final action in ['menu', 'search', 'export', 'account']) {
        final size = tester.getSize(find.byKey(ValueKey('header-$action')));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      await _showTitle(tester, conversation.title);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
