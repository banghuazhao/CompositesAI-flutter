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
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';
import 'package:swiftcomp/presentation/chat/views/chat_welcome_view.dart';
import 'package:swiftcomp/util/app_theme.dart';

class _UseCase extends Fake implements ChatUseCase {}

class _Model extends ChatViewModel {
  _Model()
      : super(
          chatUseCase: _UseCase(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'a', email: 'engineer@example.test');
  }

  final sent = <String>[];
  final files = <ChatFile>[];
  @override
  List<ChatFile> get pendingFiles => files;
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
}

Finder get _composer => find.byKey(const Key('chat-composer'));
Finder get _starter => find.byKey(const Key('chat-starter-0'));
Finder get _confirm => find.byKey(const Key('chat-replace-draft-confirm'));

Future<void> _mount(WidgetTester tester, _Model model,
    {Size size = const Size(390, 844),
    bool dark = false,
    double scale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<ChatViewModel>.value(
    value: model,
    child: MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
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
        ),
        child: child!,
      ),
      home: const ChatScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _chooseStarter(WidgetTester tester) async {
  await tester.ensureVisible(_starter);
  await tester.pumpAndSettle();
  await tester.tap(_starter);
  await tester.pumpAndSettle();
}

void main() {
  late _Model model;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    model = _Model();
  });
  tearDown(() => model.dispose());

  testWidgets('a starting question is an editable draft until explicit Send',
      (tester) async {
    const prompt = '  Carbon α\nCheck [0/90] 🌍  ';
    model.defaultQuestions = [prompt];
    model.files.add(const ChatFile(id: 'file', name: 'layup.pdf', url: ''));
    await _mount(tester, model);
    await _chooseStarter(tester);
    expect(model.composerTextController.text, prompt);
    expect(model.composerTextController.selection,
        TextSelection.collapsed(offset: prompt.length));
    expect(model.files.single.name, 'layup.pdf');
    expect(model.selectedChat, isNull);
    expect(model.messages, isEmpty);
    expect(model.sent, isEmpty);
    expect(tester.widget<TextField>(_composer).focusNode!.hasFocus, isTrue);
    await tester.enterText(_composer, 'My edited question');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(model.sent, ['My edited question']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('starting questions confirm before replacing unsent text',
      (tester) async {
    await _mount(tester, model);
    model.composerTextController.value = const TextEditingValue(
        text: '  Keep my draft 🌍  ',
        selection: TextSelection(baseOffset: 2, extentOffset: 7));
    final original = model.composerTextController.value;
    await _chooseStarter(tester);
    expect(_confirm, findsOneWidget);
    expect(model.composerTextController.value, original);
    await tester.tap(find.byKey(const Key('chat-replace-draft-cancel')));
    await tester.pumpAndSettle();
    expect(model.composerTextController.value, original);
    await _chooseStarter(tester);
    await tester.tap(_confirm);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, model.defaultQuestions.first);
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final change in [
    'edit ABA',
    'chat ABA',
    'account',
    'source',
    'dispose'
  ]) {
    testWidgets('suggestion confirmation retires after $change',
        (tester) async {
      await _mount(tester, model);
      model.composerTextController.text = 'Private original draft';
      await _chooseStarter(tester);
      final staleConfirm = tester.widget<FilledButton>(_confirm).onPressed!;
      switch (change) {
        case 'edit ABA':
          model.composerTextController.text = 'Edited';
          model.composerTextController.text = 'Private original draft';
        case 'chat ABA':
          model.selectedChat = Chat(id: 'b', title: 'Other');
          model.selectedChat = null;
          model.notifyListeners();
        case 'account':
          model.user = User(id: 'b', email: 'other@example.test');
          model.notifyListeners();
        case 'source':
          model.defaultQuestions = ['A different workspace question'];
          model.notifyListeners();
        case 'dispose':
          model.dispose();
      }
      staleConfirm();
      await tester.pumpAndSettle();
      expect(_confirm, findsNothing);
      if (!model.isDisposed) {
        expect(model.composerTextController.text,
            change == 'account' ? isEmpty : 'Private original draft');
      }
      expect(model.sent, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('old welcome callbacks cannot replace another chat draft',
      (tester) async {
    await _mount(tester, model);
    final select = tester
        .widget<ChatWelcomeView>(find.byType(ChatWelcomeView))
        .onQuestionSelected;
    model.selectedChat = Chat(id: 'b', title: 'Other');
    model.composerTextController.text = 'Private B';
    select(0);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'Private B');
    expect(model.sent, isEmpty);
    expect(_confirm, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in [const Size(375, 812), const Size(1440, 900)]) {
    testWidgets('Undo leaves native composer actions reachable at $size',
        (tester) async {
      model.selectedChat = Chat(id: 'a', title: 'Laminate');
      model.files.add(const ChatFile(id: 'file', name: 'loads.pdf', url: ''));
      await _mount(tester, model, size: size, dark: true);
      await tester.enterText(_composer, 'Clear this draft');
      await tester.tap(find.byKey(const Key('chat-composer-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-clear-draft')));
      await tester.pumpAndSettle();
      final notice = find.byKey(const Key('chat-draft-clear-notice'));
      expect(notice, findsOneWidget);
      expect(tester.getRect(notice).bottom,
          lessThanOrEqualTo(tester.getRect(_composer).top));
      expect(find.byType(SnackBar), findsNothing);
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(model.sent, ['']);
      expect(notice, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  test('recognized task categories follow prompts, including reordered lists',
      () {
    final first = model.defaultQuestions.first;
    final last = model.defaultQuestions.last;
    model.defaultQuestions = [last, 'Custom workspace prompt', first];
    expect(model.suggestedQuestionTaskIndex(0), 4);
    expect(model.suggestedQuestionTaskIndex(1), isNull);
    expect(model.suggestedQuestionTaskIndex(2), 0);
    expect(model.prepareSuggestedDraft(-1), isNull);
    expect(model.prepareSuggestedDraft(10), isNull);
  });

  for (final size in [const Size(375, 812), const Size(812, 375)]) {
    testWidgets('long drafts retain reachable controls with 3x text at $size',
        (tester) async {
      model.selectedChat = Chat(id: 'a', title: 'Laminate');
      await _mount(tester, model, size: size, scale: 3);
      await tester.enterText(_composer,
          List.generate(20, (index) => 'Laminate $index [0/90]').join('\n'));
      await tester.pumpAndSettle();
      expect(
          tester.getRect(_composer).top, greaterThanOrEqualTo(kToolbarHeight));
      for (final control in [
        find.byTooltip('Send message'),
        find.byKey(const Key('chat-composer-more')),
      ]) {
        expect(tester.getRect(control).bottom, lessThanOrEqualTo(size.height));
        expect(tester.getRect(control).height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('wide chat aligns both roles and composer in a bounded column',
      (tester) async {
    model.selectedChat = Chat(id: 'a', title: 'Laminate');
    final question = Message(role: 'user', content: 'A short question');
    final answer = Message(role: 'assistant', content: 'A clear answer');
    model.messages = [question, answer];
    await _mount(tester, model, size: const Size(1920, 1000));
    final field = tester.getRect(_composer);
    final questionText = tester.getRect(find.text(question.content));
    final answerText = tester.getRect(find.text(answer.content));
    expect(field.width, lessThanOrEqualTo(800));
    expect(field.center.dx, closeTo(960, 4));
    expect(questionText.left, greaterThanOrEqualTo(560));
    expect(questionText.right, lessThanOrEqualTo(1360));
    expect(answerText.left, closeTo(560, 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
