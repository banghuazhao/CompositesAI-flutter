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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';
import 'package:swiftcomp/util/app_interactions.dart';

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
    show(_chatA);
  }

  final sent = <String>[];
  bool loading = false;
  @override
  bool get isLoadingMessages => loading;
  @override
  Future<void> fetchAuthSessionNew() async {}
  @override
  Future<void> fetchChats() async {}
  @override
  Future<void> fetchTools() async {}
  @override
  Future<void> sendInputMessage(String text,
      {VoidCallback? onMessageAccepted}) async {
    sent.add(text);
    onMessageAccepted?.call();
  }

  void show(Chat? chat) {
    selectedChat = chat;
    messages = chat == null
        ? []
        : [Message(role: 'assistant', content: 'Carbon laminate response')];
    notifyListeners();
  }
}

final _chatA = Chat(id: 'a', title: 'Laminate A');
final _chatB = Chat(id: 'b', title: 'Laminate B');
Finder get _composer => find.byKey(const Key('chat-composer'));
Finder get _expanded => find.byKey(const Key('chat-expanded-composer'));
Finder get _search => find.byKey(const Key('chat-search-field'));
Finder get _expand => find.byKey(const Key('chat-expand-composer'));

Future<void> _pump(WidgetTester tester, _Model model,
    {Locale locale = const Locale('en'), double scale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 820);
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
      home: const ChatScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _find(WidgetTester tester,
    {LogicalKeyboardKey modifier = LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey? extra,
    bool settle = true}) async {
  await tester.sendKeyDownEvent(modifier);
  if (extra != null) await tester.sendKeyDownEvent(extra);
  try {
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
  } finally {
    if (extra != null) await tester.sendKeyUpEvent(extra);
    await tester.sendKeyUpEvent(modifier);
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 350));
  }
}

Future<void> _openComposerMore(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('chat-composer-more')).last);
  await tester.pumpAndSettle();
}

void main() {
  late _Model model;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    model = _Model();
  });
  tearDown(() => model.dispose());

  for (final modifier in [
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.metaLeft,
  ]) {
    testWidgets('$modifier opens focused chat search and keeps draft selection',
        (tester) async {
      await _pump(tester, model);
      await tester.enterText(_composer, '  Draft\n👩🏽‍🔬 carbon  ');
      const selection = TextSelection(baseOffset: 3, extentOffset: 6);
      model.composerTextController.selection = selection;
      await _find(tester, modifier: modifier);
      expect(_search, findsOneWidget);
      expect(
          tester.widget<TextField>(_search).focusNode?.hasFocus ??
              tester
                  .widget<EditableText>(find.descendant(
                      of: _search, matching: find.byType(EditableText)))
                  .focusNode
                  .hasFocus,
          isTrue);
      expect(model.composerTextController.text, '  Draft\n👩🏽‍🔬 carbon  ');
      expect(model.composerTextController.selection, selection);
      await _find(tester, modifier: modifier);
      expect(_search, findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-search-close')));
      await tester.pumpAndSettle();
      expect(_search, findsNothing);
      await _find(tester, modifier: modifier);
      expect(_search, findsOneWidget);
      expect(model.sent, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('find works when the chat has keyboard focus outside composer',
      (tester) async {
    await _pump(tester, model);
    expect(tester.widget<TextField>(_composer).focusNode!.hasFocus, isFalse);
    await _find(tester);
    expect(_search, findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final extra in [
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.metaLeft,
  ]) {
    testWidgets('find ignores additional modifier $extra', (tester) async {
      await _pump(tester, model);
      await tester.tap(_composer);
      await _find(tester, extra: extra);
      expect(_search, findsNothing);
      expect(model.sent, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('find leaves active IME composition alone', (tester) async {
    await _pump(tester, model);
    await tester.tap(_composer);
    const value = TextEditingValue(
      text: '复合材料',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 0, end: 4),
    );
    tester.testTextInput.updateEditingValue(value);
    await tester.pump();
    await _find(tester);
    expect(_search, findsNothing);
    expect(model.composerTextController.value, value);
    expect(model.sent, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('search retires after a synchronous switch away and back',
      (tester) async {
    await _pump(tester, model);
    await _find(tester);
    expect(_search, findsOneWidget);
    model.selectedChat = _chatB;
    model.selectedChat = _chatA;
    model.notifyListeners();
    await tester.pumpAndSettle();
    expect(_search, findsNothing);
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final unavailable in ['new', 'loading', 'empty', 'logout', 'covered']) {
    testWidgets('find ignores $unavailable chat context', (tester) async {
      await _pump(tester, model);
      final context = tester.element(_composer);
      switch (unavailable) {
        case 'new':
          model.show(null);
        case 'loading':
          model.loading = true;
          model.notifyListeners();
        case 'empty':
          model.messages = [];
          model.notifyListeners();
        case 'logout':
          model.isLoggedIn = false;
          model.notifyListeners();
        case 'covered':
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: TextField(autofocus: true)),
          ));
      }
      if (unavailable == 'loading') {
        await tester.pump();
      } else {
        await tester.pumpAndSettle();
      }
      await _find(tester, settle: unavailable != 'loading');
      expect(_search, findsNothing);
      expect(model.sent, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('expanded editor preserves exact draft and selected range',
      (tester) async {
    await _pump(tester, model);
    await tester.enterText(_composer, '  Carbon\n👩🏽‍🔬 question  ');
    const selection = TextSelection(baseOffset: 8, extentOffset: 3);
    model.composerTextController.selection = selection;
    final controller = model.composerTextController;
    await _openComposerMore(tester);
    await tester.tap(_expand);
    await tester.pumpAndSettle();
    expect(_expanded, findsOneWidget);
    expect(tester.widget<TextField>(_expanded).controller, same(controller));
    expect(controller.text, '  Carbon\n👩🏽‍🔬 question  ');
    expect(controller.selection, selection);
    final inline = tester.widget<TextField>(_composer);
    expect(inline.readOnly, isTrue);
    expect(inline.canRequestFocus, isFalse);
    await tester.enterText(_expanded, '  Edited\nquestion\n  ');
    const editedSelection = TextSelection.collapsed(offset: 5);
    controller.selection = editedSelection;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(model.sent, isEmpty);
    await tester.tap(find.byKey(const Key('chat-expanded-composer-done')));
    await tester.pumpAndSettle();
    expect(_expanded, findsNothing);
    expect(controller.text, '  Edited\nquestion\n  ');
    expect(controller.selection, editedSelection);
    expect(tester.widget<TextField>(_composer).readOnly, isFalse);
    expect(tester.widget<TextField>(_composer).focusNode!.hasFocus, isTrue);
    expect(model.sent, isEmpty);
    // The shared controller is still live and regular sending remains intact.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(model.sent, ['Edited\nquestion']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('switching chats retires editor without focusing the new draft',
      (tester) async {
    await _pump(tester, model);
    await tester.enterText(_composer, 'Private A');
    await _openComposerMore(tester);
    await tester.tap(_expand);
    await tester.pumpAndSettle();
    await tester.enterText(_expanded, 'Expanded A draft');
    model.show(_chatB);
    model.composerTextController.text = 'Private B';
    await tester.pumpAndSettle();
    expect(_expanded, findsNothing);
    expect(model.composerTextController.text, 'Private B');
    expect(tester.widget<TextField>(_composer).focusNode!.hasFocus, isFalse);
    model.show(_chatA);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'Expanded A draft');
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('old inline Send cannot submit while the editor is closing',
      (tester) async {
    await _pump(tester, model);
    await tester.enterText(_composer, 'Keep this question as a draft');
    await tester.pump();
    final staleSend = tester
        .widget<Pressable>(find.descendant(
            of: find.byTooltip('Send message'),
            matching: find.byType(Pressable)))
        .onTap!;
    await _openComposerMore(tester);
    await tester.tap(_expand);
    await tester.pumpAndSettle();
    await tester.enterText(_expanded, 'Expanded draft to keep');
    staleSend();
    await tester.tap(find.byKey(const Key('chat-expanded-composer-done')));
    // The owner route is current again while the editor is still unmounting.
    staleSend();
    await tester.pumpAndSettle();
    expect(model.sent, isEmpty);
    expect(model.composerTextController.text, 'Expanded draft to keep');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disposing the model while editing closes the shared editor',
      (tester) async {
    await _pump(tester, model);
    await tester.enterText(_composer, 'Draft before disposal');
    await _openComposerMore(tester);
    await tester.tap(_expand);
    await tester.pumpAndSettle();
    model.dispose();
    await tester.pumpAndSettle();
    expect(_expanded, findsNothing);
    expect(_composer, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK')
  ]) {
    testWidgets('expanded controls are accessible at 2x text in $locale',
        (tester) async {
      await _pump(tester, model, locale: locale, scale: 2);
      await _openComposerMore(tester);
      final strings = S.of(tester.element(_expand));
      expect(find.text(strings.Chat_expand_composer), findsOneWidget);
      expect(tester.getSize(_expand).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(_expand).height, greaterThanOrEqualTo(48));
      await tester.tap(_expand);
      await tester.pumpAndSettle();
      expect(find.text(strings.Chat_expanded_composer), findsOneWidget);
      expect(find.text(strings.Chat_composer_done), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
