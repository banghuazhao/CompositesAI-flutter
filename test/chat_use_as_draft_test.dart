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
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_use_as_draft_button.dart';

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
    show(_a);
  }

  final files = <ChatFile>[];
  final sends = <String>[];
  final accepted = <VoidCallback>[];

  @override
  List<ChatFile> get pendingFiles => files;

  void show(Chat chat, {List<Message> history = const []}) {
    selectedChat = chat;
    messages = List.of(history);
    notifyListeners();
  }

  @override
  Future<void> sendInputMessage(String text,
      {VoidCallback? onMessageAccepted}) async {
    sends.add(text);
    if (onMessageAccepted != null) accepted.add(onMessageAccepted);
  }
}

final _a = Chat(id: 'a', title: 'A');
final _b = Chat(id: 'b', title: 'B');
const _cancel = ValueKey('chat-replace-draft-cancel');
const _confirm = ValueKey('chat-replace-draft-confirm');
const _dialog = ValueKey('chat-replace-draft-dialog');
Finder get _button => find.byTooltip('Use as draft');

Future<void> _mount(WidgetTester tester, _Model model, Message message,
    {GlobalKey<NavigatorState>? navigatorKey,
    Locale locale = const Locale('en'),
    double scale = 1,
    VoidCallback? before,
    VoidCallback? applied}) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
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
          textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) => model.isDisposed
            ? const SizedBox.shrink()
            : Column(children: [
                ChatUseAsDraftButton(
                  viewModel: model,
                  message: message,
                  onBeforeUse: before,
                  onApplied: applied,
                ),
                TextField(
                  key: const ValueKey('test-composer'),
                  controller: model.composerTextController,
                ),
              ]),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Model model;
  late Message question;
  setUp(() {
    model = _Model();
    question = Message(role: 'user', content: '  碳纖維 🌍\nQuestion?  ');
    model.show(_a, history: [question]);
  });
  tearDown(() => model.dispose());

  test('reuses exact text with end caret and preserves history and attachments',
      () {
    const file = ChatFile(id: 'file', name: 'layup.pdf', url: '');
    question.files.add(file);
    model.files.add(file);
    final history = question.toJson();
    final request = model.prepareMessageAsDraft(question)!;
    expect(request.replacesDraft, isFalse);
    expect(model.applyMessageAsDraft(request), isTrue);
    expect(model.composerTextController.text, question.content);
    expect(model.composerTextController.selection,
        TextSelection.collapsed(offset: question.content.length));
    expect(model.composerTextController.value.composing, TextRange.empty);
    expect(question.toJson(), history);
    expect(model.pendingFiles, [file]);
    expect(model.sends, isEmpty);
    expect(model.applyMessageAsDraft(request), isFalse);
  });

  test('assistant, empty, unloaded and logged-out messages are rejected', () {
    for (final invalid in [
      Message(role: 'assistant', content: 'Answer'),
      Message(role: 'user', content: ' \n '),
    ]) {
      model.messages.add(invalid);
      expect(model.prepareMessageAsDraft(invalid), isNull);
    }
    expect(
        model
            .prepareMessageAsDraft(Message(role: 'user', content: 'Elsewhere')),
        isNull);
    model.isLoggedIn = false;
    expect(model.prepareMessageAsDraft(question), isNull);
  });

  test('caret moves permit reuse but edits and edit-undo invalidate approval',
      () {
    model.composerTextController.text = 'Original';
    final request = model.prepareMessageAsDraft(question)!;
    model.composerTextController.selection =
        const TextSelection.collapsed(offset: 2);
    expect(model.isDraftReuseCurrent(request), isTrue);
    model.composerTextController.text = 'Changed';
    model.composerTextController.text = 'Original';
    expect(model.applyMessageAsDraft(request), isFalse);
    expect(model.composerTextController.text, 'Original');
  });

  test('A to B to A cannot revive retained approval', () {
    model.composerTextController.text = 'Keep A';
    final request = model.prepareMessageAsDraft(question)!;
    model.show(_b);
    model.composerTextController.text = 'Keep B';
    model.show(_a, history: [question]);
    expect(model.applyMessageAsDraft(request), isFalse);
    expect(model.composerTextController.text, 'Keep A');
    model.show(_b);
    expect(model.composerTextController.text, 'Keep B');
  });

  test('logout and re-login reject approval from the previous session',
      () async {
    final request = model.prepareMessageAsDraft(question)!;
    await model.clearChatStateOnLogout();
    model.isLoggedIn = true;
    model.user = User(id: 'a', email: 'a@example.test');
    model.show(_a, history: [question]);
    expect(model.applyMessageAsDraft(request), isFalse);
    expect(model.composerTextController.text, isEmpty);
  });

  test('removed or changed source questions invalidate approval', () {
    final request = model.prepareMessageAsDraft(question)!;
    question.content = 'Changed on refresh';
    expect(model.applyMessageAsDraft(request), isFalse);
    question.content = '  碳纖維 🌍\nQuestion?  ';
    model.messages.clear();
    expect(model.applyMessageAsDraft(request), isFalse);
  });

  test(
      'an older accepted send cannot clear an identical deliberate replacement',
      () async {
    model.composerTextController.text = question.content;
    await model.sendComposerMessage();
    final request = model.prepareMessageAsDraft(question)!;
    expect(request.replacesDraft, isTrue);
    expect(model.applyMessageAsDraft(request), isTrue);
    model.accepted.single();
    expect(model.composerTextController.text, question.content);
  });

  testWidgets('empty draft applies directly without sending', (tester) async {
    var before = 0;
    var applied = 0;
    await _mount(tester, model, question,
        before: () => before++, applied: () => applied++);
    await tester.tap(_button);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, question.content);
    expect(find.byKey(_dialog), findsNothing);
    expect(before, 1);
    expect(applied, 1);
    expect(model.sends, isEmpty);
  });

  testWidgets('Cancel and back preserve whitespace draft and caret',
      (tester) async {
    model.composerTextController.value = const TextEditingValue(
        text: '  \n ',
        selection: TextSelection(baseOffset: 3, extentOffset: 1));
    final before = model.composerTextController.value;
    await _mount(tester, model, question);
    await tester.tap(_button);
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsOneWidget);
    await tester.tap(find.byKey(_cancel));
    await tester.pumpAndSettle();
    expect(model.composerTextController.value, before);
    await tester.tap(_button);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(model.composerTextController.value, before);
    expect(model.sends, isEmpty);
  });

  testWidgets('confirmation replaces only after explicit approval',
      (tester) async {
    model.composerTextController.text = 'Keep until approved';
    var applied = 0;
    await _mount(tester, model, question, applied: () => applied++);
    await tester.tap(_button);
    await tester.tap(_button, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsOneWidget);
    expect(model.composerTextController.text, 'Keep until approved');
    await tester.tap(find.byKey(_confirm));
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, question.content);
    expect(applied, 1);
    expect(find.byKey(_dialog), findsNothing);
  });

  testWidgets('edits made while the dialog is open retire its confirmation',
      (tester) async {
    model.composerTextController.text = 'Initial draft';
    await _mount(tester, model, question);
    await tester.tap(_button);
    await tester.pumpAndSettle();
    final confirm =
        tester.widget<FilledButton>(find.byKey(_confirm)).onPressed!;
    model.composerTextController.text = 'A newer edit';
    model.composerTextController.text = 'Initial draft';
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    confirm();
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'Initial draft');
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat changes remove only their dialog beneath a newer route',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    model.composerTextController.text = 'Initial draft';
    await _mount(tester, model, question, navigatorKey: navigator);
    await tester.tap(_button);
    await tester.pumpAndSettle();
    final confirm =
        tester.widget<FilledButton>(find.byKey(_confirm)).onPressed!;
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Newer route'))));
    await tester.pumpAndSettle();
    confirm();
    expect(find.text('Newer route'), findsOneWidget);
    model.show(_b);
    await tester.pumpAndSettle();
    expect(find.text('Newer route'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    expect(model.composerTextController.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a dismissed approval cannot revive before its route is removed',
      (tester) async {
    model.composerTextController.text = 'Keep this draft';
    await _mount(tester, model, question);
    await tester.tap(_button);
    await tester.pumpAndSettle();
    final confirm =
        tester.widget<FilledButton>(find.byKey(_confirm)).onPressed!;
    model.messages = [];
    model.notifyListeners();
    model.messages = [question];
    model.notifyListeners();
    confirm();
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'Keep this draft');
    expect(find.byKey(_dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'disposing the model removes a covered private confirmation safely',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    model.composerTextController.text = 'Private draft';
    await _mount(tester, model, question, navigatorKey: navigator);
    await tester.tap(_button);
    await tester.pumpAndSettle();
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Cover'))));
    await tester.pumpAndSettle();
    model.dispose();
    await tester.pumpAndSettle();
    expect(find.text('Cover'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK')
  ]) {
    testWidgets('$locale confirmation fits a narrow screen at 2x text',
        (tester) async {
      model.composerTextController.text = 'Existing draft';
      await _mount(tester, model, question, locale: locale, scale: 2);
      final context = tester.element(find.byType(ChatUseAsDraftButton));
      await tester.tap(find.byTooltip(S.of(context).Chat_use_as_draft));
      await tester.pumpAndSettle();
      expect(find.text(S.of(context).Chat_replace_draft_title), findsOneWidget);
      await tester.ensureVisible(find.byKey(_confirm));
      await tester.tap(find.byKey(_confirm));
      await tester.pumpAndSettle();
      expect(model.composerTextController.text, question.content);
      expect(tester.takeException(), isNull);
    });
  }
}
