import 'dart:async';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_expanded_composer.dart';

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
    show(_a);
  }

  final sends = <String>[];
  final files = <ChatFile>[];

  @override
  List<ChatFile> get pendingFiles => files;

  void show(Chat? chat) {
    selectedChat = chat;
    notifyListeners();
  }

  @override
  Future<void> sendInputMessage(String text,
      {VoidCallback? onMessageAccepted}) async {
    sends.add(text);
    onMessageAccepted?.call();
  }
}

final _a = Chat(id: 'a', title: 'Laminate A');
final _b = Chat(id: 'b', title: 'Laminate B');
const _open = Key('open-expanded');
const _field = Key('chat-expanded-composer');
const _dialog = Key('chat-expanded-composer-dialog');
const _done = Key('chat-expanded-composer-done');

class _Launcher extends StatelessWidget {
  const _Launcher(this.model);

  final ChatViewModel model;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            key: _open,
            onPressed: () => showExpandedChatComposer(context, model),
            child: const Text('Open editor'),
          ),
        ),
      );
}

Future<void> _mount(
  WidgetTester tester,
  _Model model, {
  Locale locale = const Locale('en'),
  double scale = 1,
  double keyboardHeight = 0,
  bool localized = true,
  GlobalKey<NavigatorState>? navigatorKey,
  ValueNotifier<bool>? hostPresent,
}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
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
                : const Scaffold(body: Text('Replacement owner')),
          ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.byKey(_open));
  await tester.pumpAndSettle();
  expect(find.byKey(_dialog), findsOneWidget);
  expect(find.byKey(_field), findsOneWidget);
}

Future<void> _cover(
    WidgetTester tester, GlobalKey<NavigatorState> navigator) async {
  unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('Cover page')),
  )));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Model model;
  setUp(() => model = _Model());
  tearDown(() => model.dispose());

  testWidgets('shares exact draft and caret without sending or changing files',
      (tester) async {
    const attachment = ChatFile(id: 'file', name: 'layup.pdf', url: '');
    model.files.add(attachment);
    final controller = model.composerTextController;
    const original = TextEditingValue(
      text: '  碳纖維 🌍\nOriginal question  ',
      selection: TextSelection(baseOffset: 3, extentOffset: 8),
    );
    controller.value = original;
    await _mount(tester, model);
    await _openEditor(tester);
    expect(tester.widget<TextField>(find.byKey(_field)).controller,
        same(controller));
    expect(controller.value, original);
    await tester.enterText(find.byKey(_field), '  Changed α\nSecond line  ');
    controller.selection = const TextSelection.collapsed(offset: 5);
    final changed = controller.value;
    await tester.tap(find.byKey(_done));
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    expect(controller.value, changed);
    expect(model.files, [attachment]);
    expect(model.sends, isEmpty);
    controller.text = 'Controller remains usable';
    expect(model.hasDraft(_a.id), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('multiline IME editing and Enter never submit the draft',
      (tester) async {
    await _mount(tester, model);
    await _openEditor(tester);
    final field = tester.widget<TextField>(find.byKey(_field));
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
    await tester.enterText(find.byKey(_field), 'First line');
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'First line\nSecond line',
      selection: TextSelection.collapsed(offset: 22),
    ));
    await tester.testTextInput.receiveAction(TextInputAction.newline);
    await tester.pump();
    expect(model.composerTextController.text, 'First line\nSecond line');
    expect(find.byKey(_field), findsOneWidget);
    expect(model.sends, isEmpty);
    await tester.tap(find.byKey(_done));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rapid calls share one editor through dismissal and can reopen',
      (tester) async {
    await _mount(tester, model);
    final context = tester.element(find.byKey(_open));
    final first = showExpandedChatComposer(context, model);
    final duplicate = showExpandedChatComposer(context, model);
    await tester.pumpAndSettle();
    expect(find.byKey(_field), findsOneWidget);
    Navigator.of(tester.element(find.byKey(_field))).pop();
    final duringReverse = showExpandedChatComposer(context, model);
    await tester.pumpAndSettle();
    await Future.wait([first, duplicate, duringReverse]);
    expect(find.byKey(_field), findsNothing);
    await _openEditor(tester);
    await tester.tap(find.byKey(_done));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('back preserves raw text and selection through reverse animation',
      (tester) async {
    final controller = model.composerTextController;
    controller.value = const TextEditingValue(
      text: '  Keep\nselection  ',
      selection: TextSelection.collapsed(offset: 4),
    );
    await _mount(tester, model);
    await _openEditor(tester);
    final value = controller.value;
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.value, value);
    await tester.pumpAndSettle();
    expect(find.byKey(_field), findsNothing);
    expect(controller.value, value);
    controller.text = 'Still live';
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('A to B to A cannot revive an editor before its removal frame',
      (tester) async {
    model.composerTextController.text = 'Private A draft';
    model.show(_b);
    model.composerTextController.text = 'Private B draft';
    model.show(_a);
    await _mount(tester, model);
    await _openEditor(tester);
    final oldField = tester.widget<TextField>(find.byKey(_field));
    // No intermediate VM notification: the selection revision is terminal.
    model.selectedChat = _b;
    final current = model.composerTextController.value;
    final rejected = oldField.inputFormatters!.single.formatEditUpdate(
      current,
      const TextEditingValue(text: 'Late input from A'),
    );
    expect(rejected, current);
    model.selectedChat = _a;
    model.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byKey(_field), findsNothing);
    expect(model.composerTextController.text, 'Private A draft');
    model.show(_b);
    expect(model.composerTextController.text, 'Private B draft');
    expect(model.sends, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final transition in ['new', 'account', 'logout', 'dispose']) {
    testWidgets('$transition removes only a covered editor and rejects Done',
        (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      model.composerTextController.text = 'Private account A draft';
      await _mount(tester, model, navigatorKey: navigator);
      await _openEditor(tester);
      final oldDone = tester.widget<TextButton>(find.byKey(_done)).onPressed!;
      await _cover(tester, navigator);
      oldDone();
      await tester.pumpAndSettle();
      expect(find.text('Cover page'), findsOneWidget);
      switch (transition) {
        case 'new':
          model.show(null);
        case 'account':
          model.user = User(id: 'account-b', email: 'b@example.test');
          model.notifyListeners();
        case 'logout':
          await model.clearChatStateOnLogout();
        case 'dispose':
          model.dispose();
      }
      oldDone();
      await tester.pumpAndSettle();
      expect(find.text('Cover page'), findsOneWidget);
      expect(find.byKey(_dialog, skipOffstage: false), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(_field), findsNothing);
      expect(model.sends, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('removing the owner closes only its covered modal route',
      (tester) async {
    final host = ValueNotifier(true);
    addTearDown(host.dispose);
    final navigator = GlobalKey<NavigatorState>();
    await _mount(tester, model, navigatorKey: navigator, hostPresent: host);
    await _openEditor(tester);
    await _cover(tester, navigator);
    host.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Cover page'), findsOneWidget);
    expect(find.byKey(_dialog, skipOffstage: false), findsNothing);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Replacement owner'), findsOneWidget);
    model.composerTextController.text = 'No shared controller disposal';
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stale, logged-out and already disposed owners cannot open',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await _mount(tester, model, navigatorKey: navigator);
    final context = tester.element(find.byKey(_open));
    await _cover(tester, navigator);
    await showExpandedChatComposer(context, model);
    expect(find.byKey(_field, skipOffstage: false), findsNothing);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    model.isLoggedIn = false;
    await showExpandedChatComposer(context, model);
    expect(find.byKey(_field), findsNothing);
    model.dispose();
    await showExpandedChatComposer(context, model);
    expect(find.byKey(_field), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('English fallback remains usable without app delegates',
      (tester) async {
    await _mount(tester, model, localized: false);
    await _openEditor(tester);
    expect(find.text('Edit question'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.byKey(_done));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets('$locale editor fits320px at2x with keyboard and long drafts',
        (tester) async {
      await _mount(tester, model,
          locale: locale, scale: 2, keyboardHeight: 240);
      await _openEditor(tester);
      final strings = S.of(tester.element(find.byKey(_field)));
      expect(find.text(strings.Chat_expanded_composer), findsOneWidget);
      expect(find.text(strings.Chat_composer_done), findsOneWidget);
      final field = tester.widget<TextField>(find.byKey(_field));
      expect(field.decoration!.hintText, strings.Chat_composer_hint);
      expect(tester.getSize(find.byKey(_field)).height, greaterThan(0));
      final done = find.byKey(_done);
      expect(done.hitTestable(), findsOneWidget);
      expect(tester.getSize(done).height, greaterThanOrEqualTo(48));
      final text = List.generate(100, (index) => '第 $index 層 α').join('\n');
      await tester.enterText(find.byKey(_field), text);
      await tester.pump();
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(model.composerTextController.text, text);
      expect(model.sends, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
