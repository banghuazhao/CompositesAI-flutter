import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';

const _composerKey = Key('chat-composer');

class _UseCase extends Fake implements ChatUseCase {}

class _LocalizedModel extends ChatViewModel {
  _LocalizedModel()
      : super(
          chatUseCase: _UseCase(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'localized-user', email: 'localized@example.test');
    chats = [conversation];
    selectedChat = conversation;
    messages = [
      question,
      Message(role: 'assistant', content: 'A short answer.')
    ];
  }

  final conversation =
      Chat(id: 'localized-chat', title: 'Saved α conversation');
  final question =
      Message(role: 'user', content: '  Carbon α\nOriginal question  ');
  final sent = <String>[];
  final renamed = <String>[];
  int deleted = 0;
  int shared = 0;

  @override
  bool get canRegenerate => false;
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
    notifyListeners();
  }

  @override
  Future<void> updateChatTitle(Chat chat, String newTitle) async {
    renamed.add(newTitle);
    chat.title = newTitle;
    notifyListeners();
  }

  @override
  Future<void> deleteChat(Chat chat) async {
    deleted++;
  }

  @override
  Future<bool> copyShareLink(Chat chat) async {
    shared++;
    return true;
  }
}

Future<void> _mount(
    WidgetTester tester, _LocalizedModel model, Locale locale) async {
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
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(2), disableAnimations: true),
        child: child!,
      ),
      home: const ChatScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

S _strings(WidgetTester tester) =>
    S.of(tester.element(find.byType(ChatScreen)));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty && find.byType(Drawer).evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(finder, 200,
        scrollable: find
            .descendant(
                of: find.byType(Drawer), matching: find.byType(Scrollable))
            .first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openOptions(WidgetTester tester, S strings) =>
    _tap(tester, find.byTooltip(strings.Chat_chat_options));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _LocalizedModel model;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    model = _LocalizedModel();
  });
  tearDown(() => model.dispose());

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets('$locale screen and draft controls fit320px at2x',
        (tester) async {
      try {
        await _mount(tester, model, locale);
        final strings = _strings(tester);
        expect(find.text(model.conversation.title), findsOneWidget);
        expect(find.byTooltip(strings.Chat_account_settings), findsOneWidget);
        expect(
            find.byTooltip(strings.Chat_export_conversation), findsOneWidget);
        expect(find.byTooltip(strings.Chat_add_attachment), findsOneWidget);
        expect(find.byTooltip(strings.Chat_start_voice_input), findsOneWidget);
        expect(
            tester
                .widget<TextField>(find.byKey(_composerKey))
                .decoration!
                .hintText,
            strings.Chat_composer_hint);
        expect(find.byTooltip(strings.Chat_copy_message), findsWidgets);
        expect(find.text(strings.Chat_good_response), findsNothing);
        await _tap(
            tester,
            find.byKey(
                ValueKey('chat-message-more-${model.messages.last.id}')));
        expect(find.text(strings.Chat_good_response), findsOneWidget);
        expect(find.text(strings.Chat_bad_response), findsOneWidget);
        await tester.tapAt(const Offset(2, 2));
        await tester.pumpAndSettle();

        await _tap(tester, find.byTooltip(strings.Chat_find_in_chat));
        expect(find.text(strings.Chat_find_in_chat), findsOneWidget);
        expect(
            tester
                .widget<TextField>(find.byKey(const Key('chat-search-field')))
                .decoration!
                .labelText,
            strings.Chat_search_loaded_messages);
        expect(find.text(strings.Chat_search_empty), findsOneWidget);
        await _tap(tester, find.byKey(const Key('chat-search-close')));

        await _tap(tester, find.byTooltip(strings.Chat_export_conversation));
        expect(find.text(strings.Chat_share_markdown), findsOneWidget);
        expect(find.text(strings.Chat_share_pdf), findsOneWidget);
        Navigator.of(tester.element(find.byType(ChatScreen))).pop();
        await tester.pumpAndSettle();

        await _tap(tester, find.byTooltip(strings.Chat_add_attachment));
        for (final label in [
          strings.Chat_photo_library,
          strings.Chat_camera,
          strings.Chat_files,
          strings.Chat_knowledge
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        Navigator.of(tester.element(find.byType(ChatScreen))).pop();
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(_composerKey), 'Keep my current draft');
        await tester.pumpAndSettle();
        expect(find.byTooltip(strings.Chat_send_message), findsOneWidget);
        final useAsDraft =
            find.byKey(ValueKey('chat-use-as-draft-${model.question.id}'));
        await _tap(tester,
            find.byKey(ValueKey('chat-message-more-${model.question.id}')));
        await _tap(tester, useAsDraft);
        expect(find.text(strings.Chat_replace_draft_title), findsOneWidget);
        expect(find.text(strings.Chat_replace_draft_message), findsOneWidget);
        expect(find.text(strings.Chat_replace_draft), findsOneWidget);
        expect(find.text(strings.Chat_cancel), findsOneWidget);
        await _tap(tester, find.byKey(const Key('chat-replace-draft-cancel')));
        expect(model.composerTextController.text, 'Keep my current draft');
        await _tap(tester, useAsDraft);
        await _tap(tester, find.byKey(const Key('chat-replace-draft-confirm')));
        expect(model.composerTextController.text, model.question.content);
        expect(model.composerTextController.selection,
            TextSelection.collapsed(offset: model.question.content.length));
        expect(model.sent, isEmpty);
        expect(model.pendingFiles, isEmpty);
        if (locale.languageCode != 'en') {
          expect(strings.Chat_account_settings, isNot('Account & settings'));
          expect(strings.Chat_replace_draft_title, isNot('Replace draft?'));
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('$locale drawer actions and dialogs fit320px at2x',
        (tester) async {
      try {
        await _mount(tester, model, locale);
        final strings = _strings(tester);
        final material =
            MaterialLocalizations.of(tester.element(find.byType(ChatScreen)));
        await _tap(tester, find.byTooltip(material.openAppDrawerTooltip));
        expect(find.text(strings.Chat_chats), findsWidgets);
        expect(
            find.byWidgetPredicate((widget) =>
                widget is TextField &&
                widget.decoration?.hintText == strings.Chat_search_chats),
            findsOneWidget);
        await _openOptions(tester, strings);
        for (final label in [
          strings.Chat_pin,
          strings.Chat_rename,
          strings.Chat_share,
          strings.Chat_move_to_folder,
          strings.Chat_archive,
          strings.Chat_delete
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        await _tap(tester, find.text(strings.Chat_rename));
        expect(find.text(strings.Chat_rename_chat), findsOneWidget);
        final title = find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.decoration?.labelText == strings.Chat_chat_title);
        expect(tester.widget<TextField>(title).controller!.text,
            model.conversation.title);
        await tester.enterText(title, 'Renamed α conversation');
        await _tap(
            tester, find.widgetWithText(FilledButton, strings.Chat_save));
        expect(model.renamed, ['Renamed α conversation']);

        await _openOptions(tester, strings);
        await _tap(tester, find.text(strings.Chat_share));
        expect(find.text(strings.Chat_share_chat), findsOneWidget);
        expect(find.text(strings.Chat_share_chat_description), findsOneWidget);
        expect(find.text(strings.Chat_copy_link), findsOneWidget);
        await _tap(tester, find.text(strings.Chat_cancel));
        expect(model.shared, 0);

        await _openOptions(tester, strings);
        await _tap(tester, find.text(strings.Chat_delete));
        expect(find.text(strings.Chat_delete_chat_title), findsOneWidget);
        expect(
            find.text(
                strings.Chat_delete_chat_message(model.conversation.title)),
            findsOneWidget);
        await _tap(tester, find.text(strings.Chat_cancel));
        expect(model.deleted, 0);
        expect(model.sent, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
}
