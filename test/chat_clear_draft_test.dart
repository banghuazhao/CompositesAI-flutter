import 'dart:async';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/controllers/chat_composer_controller.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_clear_draft_button.dart';
import 'package:swiftcomp/presentation/chat/views/chat_composer_more_menu.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';

class _Backend extends Fake implements ChatUseCase {}

class _Model extends ChatViewModel {
  _Model()
      : super(
          chatUseCase: _Backend(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'account-a', email: 'a@example.test');
    show(_chatA);
  }

  final files = <ChatFile>[];
  final sent = <String>[];
  final accepted = <VoidCallback>[];
  bool sending = false;
  bool loading = false;

  @override
  bool get isSendingMessage => sending;
  @override
  bool get isLoadingMessages => loading;
  @override
  bool get canRegenerate => false;
  @override
  List<ChatFile> get pendingFiles => files;
  @override
  Future<void> fetchAuthSessionNew() async {}
  @override
  Future<void> fetchChats() async {}
  @override
  Future<void> fetchTools() async {}

  void show(Chat? chat) {
    selectedChat = chat;
    messages = [Message(role: 'user', content: 'Existing question')];
    notifyListeners();
  }

  void changed() => notifyListeners();

  @override
  Future<void> sendInputMessage(String text,
      {VoidCallback? onMessageAccepted}) async {
    sent.add(text);
    if (onMessageAccepted != null) accepted.add(onMessageAccepted);
  }
}

final _chatA = Chat(id: 'a', title: 'Laminate A');
final _chatB = Chat(id: 'b', title: 'Laminate B');
const _clear = Key('chat-clear-draft');
const _undo = Key('chat-undo-clear-draft');
const _inline = Key('chat-composer');
const _expanded = Key('chat-expanded-composer');
const _expandedDialog = Key('chat-expanded-composer-dialog');
const _draft = TextEditingValue(
  text: '  碳纖維 🌍\nOriginal question  ',
  selection: TextSelection(baseOffset: 10, extentOffset: 2),
  composing: TextRange(start: 2, end: 5),
);

class _ButtonHarness extends StatefulWidget {
  const _ButtonHarness({super.key, required this.model});
  final _Model model;

  @override
  State<_ButtonHarness> createState() => _ButtonHarnessState();
}

class _ButtonHarnessState extends State<_ButtonHarness> {
  late _Model model = widget.model;
  bool showButton = true;
  bool editDuringBuild = false;

  void removeButton() => setState(() => showButton = false);
  void replaceModel(_Model value) => setState(() => model = value);
  void editOnNextBuild() => setState(() => editDuringBuild = true);

  @override
  Widget build(BuildContext context) {
    if (editDuringBuild) {
      editDuringBuild = false;
      model.composerTextController.text = 'Draft edited during owner rebuild';
    }
    return Scaffold(
      body: Column(children: [
        if (showButton) ChatClearDraftButton(viewModel: model),
        TextField(
          key: const Key('harness-composer'),
          controller: model.composerTextController,
        ),
        const Text('Owner remains'),
      ]),
    );
  }
}

Future<GlobalKey<_ButtonHarnessState>> _pump(WidgetTester tester, _Model model,
    {bool screen = false,
    Locale locale = const Locale('en'),
    double scale = 1,
    bool accessibleNavigation = false,
    Size size = const Size(390, 800),
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<ScaffoldMessengerState>? messengerKey}) async {
  final host = GlobalKey<_ButtonHarnessState>();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<ChatViewModel>.value(
    value: model,
    child: MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
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
            disableAnimations: true,
            accessibleNavigation: accessibleNavigation),
        child: child!,
      ),
      home:
          screen ? const ChatScreen() : _ButtonHarness(key: host, model: model),
    ),
  ));
  await tester.pumpAndSettle();
  return host;
}

Future<void> _openTools(WidgetTester tester) async {
  if (find.byKey(_clear).hitTestable().evaluate().isNotEmpty) return;
  await tester.tap(find.byKey(const Key('chat-composer-more')).hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _openExpanded(WidgetTester tester) async {
  await _openTools(tester);
  await tester.tap(find.byKey(const Key('chat-expand-composer')).hitTestable());
  await tester.pumpAndSettle();
}

VoidCallback _clearCallback(WidgetTester tester, Finder finder) {
  final widget = tester.widget(finder);
  return widget is MenuItemButton
      ? widget.onPressed!
      : (widget as IconButton).onPressed!;
}

Future<VoidCallback> _clearAndCaptureUndo(WidgetTester tester,
    {Finder? button}) async {
  await _openTools(tester);
  await tester.tap(button ?? find.byKey(_clear).hitTestable());
  await tester.pumpAndSettle();
  final action = find.byKey(_undo).hitTestable();
  expect(action, findsOneWidget);
  expect(find.byType(SnackBar), findsNothing);
  return tester.widget<TextButton>(action).onPressed!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Model model;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    model = _Model();
  });
  tearDown(() => model.dispose());

  test(
      'controller replacement restores raw text/selection and retires composing',
      () {
    final composer = ChatComposerController();
    addTearDown(composer.dispose);
    composer.textController.value = _draft;
    final original = composer.takeTicket();
    expect(composer.replaceIfCurrent(original, ''), isTrue);
    final cleared = composer.takeTicket();
    expect(composer.replaceValueIfCurrent(cleared, original.value), isTrue);
    expect(composer.textController.text, _draft.text);
    expect(composer.textController.selection, _draft.selection);
    expect(composer.textController.value.composing, TextRange.empty);
    composer.accept(original);
    expect(composer.textController.text, _draft.text);
    expect(composer.replaceValueIfCurrent(cleared, _draft), isFalse);
  });

  test(
      'clear/Undo preserves attachments/history and creates a new draft revision',
      () {
    const file = ChatFile(id: 'file', name: 'layup.pdf', url: '');
    model.files.add(file);
    final history = model.messages.single.toJson();
    model.composerTextController.value = _draft;
    final beforeRevision = model.composerReplacementRevision;
    final undo = model.clearComposerDraft()!;
    expect(model.composerTextController.text, isEmpty);
    expect(model.composerTextController.selection,
        const TextSelection.collapsed(offset: 0));
    expect(model.isDraftClearUndoCurrent(undo), isTrue);
    expect(model.composerReplacementRevision, greaterThan(beforeRevision));
    expect(model.undoClearComposerDraft(undo), isTrue);
    expect(model.composerTextController.text, _draft.text);
    expect(model.composerTextController.selection, _draft.selection);
    expect(model.composerTextController.value.composing, TextRange.empty);
    expect(model.undoClearComposerDraft(undo), isFalse);
    expect(model.pendingFiles, [file]);
    expect(model.messages.single.toJson(), history);
    expect(model.sent, isEmpty);
  });

  test('whitespace can be cleared while empty, sending and loading are gated',
      () {
    expect(model.canClearComposerDraft, isFalse);
    expect(model.clearComposerDraft(), isNull);
    model.composerTextController.text = ' \n ';
    model.sending = true;
    expect(model.clearComposerDraft(), isNull);
    expect(model.composerTextController.text, ' \n ');
    model.sending = false;
    model.loading = true;
    expect(model.clearComposerDraft(), isNull);
    model.loading = false;
    final undo = model.clearComposerDraft()!;
    expect(model.undoClearComposerDraft(undo), isTrue);
    expect(model.composerTextController.text, ' \n ');
  });

  test('new edits and edit-undo to empty retire the token permanently', () {
    model.composerTextController.text = 'First draft';
    final first = model.clearComposerDraft()!;
    model.composerTextController.text = 'A newer draft';
    expect(model.undoClearComposerDraft(first), isFalse);
    expect(model.composerTextController.text, 'A newer draft');
    final second = model.clearComposerDraft()!;
    model.composerTextController.text = 'Temporary edit';
    model.composerTextController.clear();
    expect(model.undoClearComposerDraft(second), isFalse);
    expect(model.composerTextController.text, isEmpty);
  });

  test(
      'successive clears keep only the latest token and discard is identity safe',
      () {
    model.composerTextController.text = 'First';
    final first = model.clearComposerDraft()!;
    model.composerTextController.text = 'Second';
    final second = model.clearComposerDraft()!;
    model.discardDraftClearUndo(first);
    expect(model.undoClearComposerDraft(first), isFalse);
    expect(model.undoClearComposerDraft(second), isTrue);
    expect(model.composerTextController.text, 'Second');
    final third = model.clearComposerDraft()!;
    model.discardDraftClearUndo(third);
    expect(model.undoClearComposerDraft(third), isFalse);
  });

  test('an older send acceptance cannot erase restored text', () async {
    model.composerTextController.value = _draft;
    await model.sendComposerMessage();
    final undo = model.clearComposerDraft()!;
    expect(model.undoClearComposerDraft(undo), isTrue);
    model.accepted.single();
    expect(model.composerTextController.text, _draft.text);
    expect(model.composerTextController.selection, _draft.selection);
    expect(model.sent, [_draft.text.trim()]);
  });

  for (final transition in [
    'ABA',
    'New',
    'account',
    'logout',
    'sending',
    'loading',
    'send',
    'dispose'
  ]) {
    test('$transition retires model Undo without replacing a newer draft',
        () async {
      model.composerTextController.text = 'Original A';
      final undo = model.clearComposerDraft()!;
      switch (transition) {
        case 'ABA':
          model.show(_chatB);
          model.show(_chatA);
        case 'New':
          model.show(null);
        case 'account':
          model.user = User(id: 'account-b', email: 'b@example.test');
          model.changed();
        case 'logout':
          await model.clearChatStateOnLogout();
          model.isLoggedIn = true;
          model.user = User(id: 'account-a', email: 'a@example.test');
          model.show(_chatA);
        case 'sending':
          model.sending = true;
          model.changed();
          model.sending = false;
          model.changed();
        case 'loading':
          model.loading = true;
          model.changed();
          model.loading = false;
          model.changed();
        case 'send':
          await model.sendComposerMessage();
        case 'dispose':
          model.dispose();
      }
      expect(model.isDraftClearUndoCurrent(undo), isFalse);
      if (!model.isDisposed) {
        model.composerTextController.text = 'New private draft';
        expect(model.undoClearComposerDraft(undo), isFalse);
        expect(model.composerTextController.text, 'New private draft');
      } else {
        expect(model.undoClearComposerDraft(undo), isFalse);
      }
    });
  }

  testWidgets(
      'inline Clear and actual Undo restore raw text/caret without send',
      (tester) async {
    const file = ChatFile(id: 'file', name: 'layup.pdf', url: '');
    model.files.add(file);
    model.composerTextController.value = _draft;
    await _pump(tester, model, screen: true);
    await _clearAndCaptureUndo(tester);
    expect(model.composerTextController.text, isEmpty);
    expect(model.pendingFiles, [file]);
    await tester.tap(find.byKey(_undo).hitTestable());
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, _draft.text);
    expect(model.composerTextController.selection, _draft.selection);
    expect(model.composerTextController.value.composing, TextRange.empty);
    expect(tester.widget<TextField>(find.byKey(_inline)).controller,
        same(model.composerTextController));
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'expanded editor Clear/Undo is local and keeps the shared controller',
      (tester) async {
    model.composerTextController.value = _draft;
    final controller = model.composerTextController;
    await _pump(tester, model, screen: true);
    await _openExpanded(tester);
    await _openTools(tester);
    final clear = find.byKey(_clear).hitTestable();
    expect(clear, findsOneWidget);
    await _clearAndCaptureUndo(tester, button: clear);
    expect(controller.text, isEmpty);
    expect(find.byKey(_undo).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(_undo).hitTestable());
    await tester.pumpAndSettle();
    expect(controller.text, _draft.text);
    expect(controller.selection, _draft.selection);
    expect(tester.widget<TextField>(find.byKey(_expanded)).controller,
        same(controller));
    await tester.tap(find.byKey(const Key('chat-expanded-composer-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(_expandedDialog), findsNothing);
    expect(model.composerTextController, same(controller));
    expect(controller.text, _draft.text);
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'new typing retires the visible notice and retained Undo callback',
      (tester) async {
    model.composerTextController.text = 'Old draft';
    await _pump(tester, model);
    final stale = await _clearAndCaptureUndo(tester);
    await tester.enterText(
        find.byKey(const Key('harness-composer')), 'New edit');
    stale();
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'New edit');
    expect(find.byKey(_undo), findsNothing);
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Undo timeout retires its retained action', (tester) async {
    model.composerTextController.text = 'Old draft';
    await _pump(tester, model);
    final stale = await _clearAndCaptureUndo(tester);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.byKey(_undo), findsNothing);
    stale();
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('accessible navigation keeps Undo available until acted on',
      (tester) async {
    model.composerTextController.text = 'Accessible draft';
    await _pump(tester, model, accessibleNavigation: true);
    await _clearAndCaptureUndo(tester);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.byKey(_undo), findsOneWidget);
    await tester.tap(find.byKey(_undo));
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'Accessible draft');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'a newer snackbar survives stale notice cleanup and owner removal',
      (tester) async {
    final messenger = GlobalKey<ScaffoldMessengerState>();
    model.composerTextController.text = 'Old draft';
    final host = await _pump(tester, model, messengerKey: messenger);
    final stale = await _clearAndCaptureUndo(tester);
    expect(find.byType(SnackBar), findsNothing);
    messenger.currentState!.showSnackBar(
        const SnackBar(content: Text('Unrelated newer notification')));
    host.currentState!.removeButton();
    await tester.pumpAndSettle();
    stale();
    await tester.pumpAndSettle();
    expect(find.text('Unrelated newer notification'), findsOneWidget);
    expect(find.byKey(_undo), findsNothing);
    expect(model.composerTextController.text, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('multi-root route changes retire Undo without popping the cover',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    model.composerTextController.text = 'Private old draft';
    await _pump(tester, model, navigatorKey: navigator);
    final stale = await _clearAndCaptureUndo(tester);
    unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Cover route')))));
    await tester.pumpAndSettle();
    stale();
    await tester.pumpAndSettle();
    expect(find.text('Cover route'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Owner remains'), findsOneWidget);
    expect(find.byKey(_undo), findsNothing);
    expect(model.composerTextController.text, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('notice retirement during owner build does not setState in build',
      (tester) async {
    model.composerTextController.text = 'Initial draft';
    final host = await _pump(tester, model);
    final stale = await _clearAndCaptureUndo(tester);
    host.currentState!.editOnNextBuild();
    await tester.pumpAndSettle();
    stale();
    await tester.pumpAndSettle();
    expect(
        model.composerTextController.text, 'Draft edited during owner rebuild');
    expect(find.byKey(_undo), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'rebound model rejects a retained clear callback before next build',
      (tester) async {
    final other = _Model();
    addTearDown(other.dispose);
    model.composerTextController.text = 'A draft';
    other.composerTextController.text = 'Other draft';
    final host = await _pump(tester, model);
    final stale = tester.widget<IconButton>(find.byKey(_clear)).onPressed!;
    host.currentState!.replaceModel(other);
    await tester.pumpAndSettle();
    stale();
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'A draft');
    expect(other.composerTextController.text, 'Other draft');
    expect(find.byKey(_undo), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final expanded in [false, true]) {
    for (final backToA in [false, true]) {
      testWidgets(
          '${expanded ? 'expanded' : 'inline'} retained clear rejects ${backToA ? 'A B A' : 'A B'} before a frame',
          (tester) async {
        model.composerTextController.text = 'A draft';
        await _pump(tester, model, screen: true);
        if (expanded) {
          await _openExpanded(tester);
        }
        await _openTools(tester);
        final button = find.byKey(_clear).hitTestable();
        final stale = _clearCallback(tester, button);
        model.show(_chatB);
        model.composerTextController.text = 'B private draft';
        if (backToA) model.show(_chatA);
        stale();
        await tester.pumpAndSettle();
        expect(model.composerTextController.text,
            backToA ? 'A draft' : 'B private draft');
        model.show(_chatB);
        expect(model.composerTextController.text, 'B private draft');
        expect(model.sent, isEmpty);
        expect(find.byKey(_undo), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('model disposal retires visible Undo and stale callbacks safely',
      (tester) async {
    model.composerTextController.text = 'Private draft';
    await _pump(tester, model);
    final clear = tester.widget<IconButton>(find.byKey(_clear)).onPressed!;
    final undo = await _clearAndCaptureUndo(tester);
    model.dispose();
    clear();
    undo();
    await tester.pumpAndSettle();
    expect(find.byKey(_undo), findsNothing);
    expect(find.byKey(_clear), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK')
  ]) {
    testWidgets('$locale inline Clear/Undo fits320px at2x text',
        (tester) async {
      model.composerTextController.text = '  Localized draft α\n';
      await _pump(tester, model,
          screen: true, locale: locale, scale: 2, size: const Size(320, 800));
      await _openTools(tester);
      final context = tester.element(find.byKey(_clear).hitTestable());
      final strings = S.of(context);
      expect(find.text(strings.Chat_clear_draft), findsOneWidget);
      final size = tester.getSize(find.byKey(_clear).hitTestable());
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await _clearAndCaptureUndo(tester);
      expect(find.text(strings.Chat_draft_cleared), findsOneWidget);
      expect(find.text(strings.Chat_undo), findsOneWidget);
      await tester.tap(find.byKey(_undo).hitTestable());
      await tester.pumpAndSettle();
      expect(model.composerTextController.text, '  Localized draft α\n');
      expect(model.sent, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('composer builder keeps inline Undo above editable content',
      (tester) async {
    model.composerTextController.value = _draft;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatClearDraftButton(
          viewModel: model,
          builder: (context, onClear, notice) => Column(
            children: [
              if (notice != null) notice,
              TextField(
                key: const Key('builder-composer'),
                controller: model.composerTextController,
              ),
              ChatComposerMoreMenu(onClear: onClear),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await _clearAndCaptureUndo(tester);
    final notice = find.byKey(const Key('chat-draft-clear-notice'));
    final field = find.byKey(const Key('builder-composer'));
    expect(tester.getRect(notice).bottom,
        lessThanOrEqualTo(tester.getRect(field).top));
    expect(tester.widget<Semantics>(notice).properties.liveRegion, isTrue);
    expect(find.byType(SnackBar), findsNothing);
    await tester.enterText(
        field, 'Continue typing without dismissing feedback');
    await tester.pumpAndSettle();
    expect(model.composerTextController.text,
        'Continue typing without dismissing feedback');
    expect(notice, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('VM disposal never rebuilds children with a disposed controller',
      (tester) async {
    model.composerTextController.text = 'Controller lifetime fixture';
    var buildsAfterDisposal = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatClearDraftButton(
          viewModel: model,
          builder: (context, onClear, notice) {
            if (model.isDisposed) buildsAfterDisposal++;
            return TextField(
              key: const Key('owned-composer'),
              controller: model.composerTextController,
            );
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('owned-composer')), findsOneWidget);
    model.dispose();
    await tester.pumpAndSettle();
    expect(buildsAfterDisposal, 0);
    expect(find.byKey(const Key('owned-composer')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
