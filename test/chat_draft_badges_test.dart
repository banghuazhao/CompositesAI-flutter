import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_folder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/controllers/chat_composer_controller.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_draft_badge.dart';
import 'package:swiftcomp/presentation/chat/views/chat_list.dart';

final _a = Chat(id: 'a', title: 'Carbon A');
final _b = Chat(id: 'b', title: 'Glass B');
const _badgeA = ValueKey('chat-draft-badge-a');
const _badgeB = ValueKey('chat-draft-badge-b');

class _Chats extends Fake implements ChatUseCase {
  bool failDelete = false;
  @override
  Future<void> deleteChat(Chat chat) async {
    if (failDelete) throw StateError('Delete failed');
  }
}

class _Model extends ChatViewModel {
  _Model(this.source)
      : super(
          chatUseCase: source,
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'owner-a', email: 'a@example.test');
    chats = [_a, _b];
    show(_a);
  }

  final _Chats source;
  final accepted = <VoidCallback>[];

  void show(Chat chat) {
    selectedChat = chat;
    notifyListeners();
  }

  @override
  Future<void> sendInputMessage(String text,
      {VoidCallback? onMessageAccepted}) async {
    if (onMessageAccepted != null) accepted.add(onMessageAccepted);
  }
}

Future<void> _mount(WidgetTester tester, _Model model,
    {Locale locale = const Locale('en'),
    double scale = 1,
    Widget? child}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
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
      home: Scaffold(body: child ?? const ChatList()),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('presence events ignore caret and nonempty edits, and coalesce changes',
      () async {
    final composer = ChatComposerController();
    addTearDown(composer.dispose);
    var changes = 0;
    composer.draftChanges.addListener(() => changes++);
    composer.textController.text = ' \n ';
    await Future<void>.delayed(Duration.zero);
    expect(composer.hasDraft(null), isFalse);
    expect(changes, 0);
    composer.textController.text = 'Original';
    composer.textController.text = 'Revised';
    await Future<void>.delayed(Duration.zero);
    expect(changes, 1);
    composer.textController.value = composer.textController.value.copyWith(
      selection: const TextSelection.collapsed(offset: 3),
      composing: const TextRange(start: 0, end: 2),
    );
    await Future<void>.delayed(Duration.zero);
    expect(changes, 1);
    composer.textController.clear();
    await Future<void>.delayed(Duration.zero);
    expect(changes, 2);
    expect(composer.hasDraft(null), isFalse);
  });

  test('presence reads never change which least-recent draft is evicted', () {
    final composer = ChatComposerController(maximumDrafts: 3);
    addTearDown(composer.dispose);
    for (final id in ['a', 'b', 'c']) {
      composer.selectChat(id);
      composer.textController.text = '$id text';
    }
    for (var index = 0; index < 100; index++) {
      expect(composer.hasDraft('a'), isTrue);
      expect(composer.hasDraft('unknown'), isFalse);
    }
    expect(composer.cachedDraftCount, 3);
    composer.selectChat('d');
    composer.textController.text = 'd text';
    expect(composer.hasDraft('a'), isFalse);
    expect(composer.hasDraft('b'), isTrue);
    expect(composer.hasDraft('c'), isTrue);
    expect(composer.hasDraft('d'), isTrue);
  });

  test(
      'New-chat promotion, deletion and queued disposal update presence safely',
      () async {
    final composer = ChatComposerController();
    composer.textController.text = 'Follow-up typed during creation';
    composer.adoptNewChat('created');
    expect(composer.hasDraft(null), isFalse);
    expect(composer.hasDraft('created'), isTrue);
    composer.selectChat('other');
    composer.removeChat('created');
    expect(composer.hasDraft('created'), isFalse);
    var changes = 0;
    composer.draftChanges.addListener(() => changes++);
    composer.textController.text = 'Private pending text';
    composer.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(changes, 0);
    expect(composer.hasDraft('other'), isFalse);
  });

  late _Model model;
  setUp(() {
    _a.title = 'Carbon A';
    _b.title = 'Glass B';
    model = _Model(_Chats());
  });
  tearDown(() => model.dispose());

  test('typing publishes presence without general view-model notifications',
      () async {
    var modelChanges = 0;
    var draftChanges = 0;
    model.addListener(() => modelChanges++);
    model.draftChanges.addListener(() => draftChanges++);
    model.composerTextController.text = 'An unsent question';
    await Future<void>.delayed(Duration.zero);
    expect(model.hasDraft('a'), isTrue);
    expect(modelChanges, 0);
    expect(draftChanges, 1);
    model.composerTextController.text = 'A revised question';
    await Future<void>.delayed(Duration.zero);
    expect(modelChanges, 0);
    expect(draftChanges, 1);
  });

  test('late send acceptance clears only its unchanged originating badge',
      () async {
    model.composerTextController.text = 'Sent A';
    await model.sendComposerMessage();
    model.show(_b);
    model.composerTextController.text = 'Keep B';
    model.accepted.removeAt(0)();
    expect(model.hasDraft('a'), isFalse);
    expect(model.hasDraft('b'), isTrue);
    model.show(_a);
    model.composerTextController.text = 'Second sent A';
    await model.sendComposerMessage();
    model.composerTextController.text = 'A newer edit';
    model.accepted.single();
    expect(model.hasDraft('a'), isTrue);
    expect(model.hasDraft('b'), isTrue);
  });

  test('an identity mismatch hides badges before a later composer sync', () {
    model.composerTextController.text = 'Owner A private draft';
    expect(model.hasDraft('a'), isTrue);
    model.user = User(id: 'owner-b', email: 'b@example.test');
    expect(model.hasDraft('a'), isFalse);
    model.notifyListeners();
    expect(model.composerTextController.text, isEmpty);
    model.user = User(id: 'owner-a', email: 'a@example.test');
    model.notifyListeners();
    expect(model.hasDraft('a'), isFalse);
  });

  test(
      'failed deletion retains a badge; successful deletion and logout clear it',
      () async {
    model.composerTextController.text = 'Keep until deletion succeeds';
    model.source.failDelete = true;
    await model.deleteChat(_a);
    expect(model.hasDraft('a'), isTrue);
    model.source.failDelete = false;
    await model.deleteChat(_a);
    expect(model.hasDraft('a'), isFalse);
    model.show(_b);
    model.composerTextController.text = 'Owner A B draft';
    await model.clearChatStateOnLogout();
    expect(model.hasDraft('b'), isFalse);
  });

  testWidgets('drawer badges update from typing and send acceptance alone',
      (tester) async {
    await _mount(tester, model);
    expect(find.byKey(_badgeA), findsNothing);
    model.composerTextController.text = 'Private A text';
    await tester.pumpAndSettle();
    expect(find.byKey(_badgeA), findsOneWidget);
    expect(find.text('Private A text'), findsNothing);
    await model.sendComposerMessage();
    model.show(_b);
    model.composerTextController.text = 'Private B text';
    await tester.pumpAndSettle();
    expect(find.byKey(_badgeA), findsOneWidget);
    expect(find.byKey(_badgeB), findsOneWidget);
    model.accepted.single();
    await tester.pumpAndSettle();
    expect(find.byKey(_badgeA), findsNothing);
    expect(find.byKey(_badgeB), findsOneWidget);
    await model.clearChatStateOnLogout();
    await tester.pumpAndSettle();
    expect(find.byType(ChatDraftBadge), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pinned, folder and filtered rows use the same draft state',
      (tester) async {
    model.composerTextController.text = 'A';
    model.show(_b);
    model.composerTextController.text = 'B';
    model.pinnedChats = [_a];
    model.chatFolders = [
      ChatFolder(id: 'folder', name: 'Materials', isExpanded: true, chats: [_b])
    ];
    await _mount(tester, model);
    expect(find.byKey(_badgeA), findsOneWidget);
    expect(find.byKey(_badgeB), findsOneWidget);
    model.chatSearchQuery = 'Carbon';
    model.filteredChats = [_a];
    model.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byKey(_badgeA), findsOneWidget);
    expect(find.byKey(_badgeB), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('queued badge updates survive removal and model disposal',
      (tester) async {
    await _mount(tester, model,
        child: ChatDraftBadge(viewModel: model, chatId: 'a'));
    model.composerTextController.text = 'Pending';
    await tester.pumpWidget(const SizedBox.shrink());
    model.dispose();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'account sync during a sibling build safely retires draft presence',
      (tester) async {
    final switchOwner = ValueNotifier(false);
    model.composerTextController.text = 'Private owner A text';
    await _mount(tester, model,
        child: Column(children: [
          ChatDraftBadge(viewModel: model, chatId: 'a'),
          ValueListenableBuilder<bool>(
            valueListenable: switchOwner,
            builder: (context, switching, _) {
              if (switching) {
                model.user = User(id: 'owner-b', email: 'b@example.test');
                // Mirrors a composer getter synchronizing authentication in build.
                return Text(model.composerTextController.text);
              }
              return const SizedBox.shrink();
            },
          ),
        ]));
    expect(find.byKey(_badgeA), findsOneWidget);
    switchOwner.value = true;
    await tester.pumpAndSettle();
    expect(find.byKey(_badgeA), findsNothing);
    expect(model.hasDraft('a'), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    switchOwner.dispose();
  });

  testWidgets(
      'a mounted badge observes model disposal without disposed listeners',
      (tester) async {
    model.composerTextController.text = 'Private draft';
    await _mount(tester, model,
        child: ChatDraftBadge(viewModel: model, chatId: 'a'));
    expect(find.byKey(_badgeA), findsOneWidget);
    model.dispose();
    await tester.pumpAndSettle();
    expect(find.byKey(_badgeA), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a standalone badge follows account changes and logout',
      (tester) async {
    model.composerTextController.text = 'Private owner A draft';
    await _mount(tester, model,
        child: ChatDraftBadge(viewModel: model, chatId: 'a'));
    expect(find.byKey(_badgeA), findsOneWidget);
    model.user = User(id: 'owner-b', email: 'b@example.test');
    model.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byKey(_badgeA), findsNothing);
    model.composerTextController.text = 'Owner B draft';
    await tester.pumpAndSettle();
    expect(find.byKey(_badgeA), findsOneWidget);
    await model.clearChatStateOnLogout();
    await tester.pumpAndSettle();
    expect(find.byKey(_badgeA), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK')
  ]) {
    testWidgets('$locale draft badge fits320px at2x text', (tester) async {
      _a.title = 'A long carbon laminate conversation title 原稿';
      model.composerTextController.text = 'Unsent';
      await _mount(tester, model, locale: locale, scale: 2);
      final strings = S.of(tester.element(find.byType(ChatList)));
      expect(find.text(strings.Chat_draft), findsOneWidget);
      expect(find.byKey(_badgeA), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
