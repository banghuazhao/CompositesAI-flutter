import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/ai_markdown_message.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';

// No auth, upload or response requests are made. This target exercises the real
// native text input, image decoder, scrolling and navigation with local data.
class _ChatUseCase extends Fake implements ChatUseCase {}

class _ChatModel extends ChatViewModel {
  _ChatModel()
      : super(
          chatUseCase: _ChatUseCase(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'native-account', email: 'native@example.test');
  }

  final files = <ChatFile>[];
  final previews = <String, Uint8List>{};
  final sent = <String>[];
  final acceptors = <VoidCallback>[];
  bool acceptImmediately = true;

  @override
  List<ChatFile> get pendingFiles => files;
  @override
  Map<String, Uint8List> get pendingImageBytes => previews;
  @override
  Future<void> fetchAuthSessionNew() async {}
  @override
  Future<void> fetchChats() async {}
  @override
  Future<void> fetchTools() async {}

  void show(Chat? chat, {List<Message> history = const []}) {
    selectedChat = chat;
    messages = List.of(history);
    notifyListeners();
  }

  @override
  void removePendingFile(ChatFile file) {
    files.removeWhere((item) => item.id == file.id);
    previews.remove(file.id);
    notifyListeners();
  }

  @override
  Future<void> sendInputMessage(String text,
      {VoidCallback? onMessageAccepted}) async {
    sent.add(text);
    if (onMessageAccepted != null) {
      if (acceptImmediately) {
        onMessageAccepted();
      } else {
        acceptors.add(onMessageAccepted);
      }
    }
    notifyListeners();
  }
}

final _a = Chat(id: 'native-a', title: 'Laminate A');
final _b = Chat(id: 'native-b', title: 'Laminate B');
const _file = ChatFile(id: 'native-image', name: 'layup.png', url: '');
Finder get _composer => find.byKey(const Key('chat-composer'));

Future<void> _mount(WidgetTester tester, _ChatModel model,
    {Locale locale = const Locale('en')}) async {
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
      home: const ChatScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String text) async {
  await tester.tap(_composer);
  await tester.pumpAndSettle();
  await tester.enterText(_composer, text);
  await tester.pump();
  await _hideKeyboard(tester);
  expect(tester.widget<TextField>(_composer).controller!.text, text);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _findShortcut(WidgetTester tester, {bool shift = false}) async {
  final modifier = defaultTargetPlatform == TargetPlatform.iOS
      ? LogicalKeyboardKey.metaLeft
      : LogicalKeyboardKey.controlLeft;
  final pressed = <LogicalKeyboardKey>[];
  try {
    await tester.sendKeyDownEvent(modifier);
    pressed.add(modifier);
    if (shift) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      pressed.add(LogicalKeyboardKey.shiftLeft);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
  } finally {
    for (final key in pressed.reversed) {
      await tester.sendKeyUpEvent(key);
    }
  }
  await tester.pumpAndSettle();
}

Future<void> _openDrawer(WidgetTester tester) async {
  final material =
      MaterialLocalizations.of(tester.element(find.byType(ChatScreen)));
  await tester.tap(find.byTooltip(material.openAppDrawerTooltip));
  await tester.pumpAndSettle();
}

Future<void> _closeDrawer(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold).first).closeDrawer();
  await tester.pumpAndSettle();
}

Finder _tooltipText(String text) => find.byWidgetPredicate(
    (widget) => widget is Text && widget.textSpan?.toPlainText() == text);

Future<void> _expectDecodedPreview(WidgetTester tester) async {
  final decoded = find.descendant(
    of: find.byKey(const ValueKey('pending-image-preview-content')),
    matching: find.byType(RawImage),
  );
  // Native codec completion may arrive after the dialog animation settles.
  for (var attempt = 0; attempt < 50; attempt++) {
    if (decoded.evaluate().length == 1 &&
        tester.widget<RawImage>(decoded).image != null) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(decoded, findsOneWidget,
      reason: 'The preview must display decoded pixels, not its fallback.');
  final image = tester.widget<RawImage>(decoded).image;
  expect(image, isNotNull);
  expect(image!.width, 8);
  expect(image.height, 6);
  expect(find.byKey(const ValueKey('pending-image-preview-unavailable')),
      findsNothing);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late _ChatModel model;
  late Uint8List png;

  setUpAll(() async {
    expect(kIsWeb, isFalse);
    expect(defaultTargetPlatform,
        anyOf(TargetPlatform.android, TargetPlatform.iOS));
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.teal, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 6);
    png = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    image.dispose();
    picture.dispose();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    model = _ChatModel();
  });
  tearDown(() => model.dispose());

  testWidgets(
      'native conversation drafts keep text and isolate late acceptance',
      (tester) async {
    await _mount(tester, model);
    await _enter(tester, '  Unsent New chat  ');
    model.show(_a);
    await tester.pumpAndSettle();
    await _enter(tester, '  Submit A  ');
    model.acceptImmediately = false;
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    await _hideKeyboard(tester);
    expect(model.sent, ['Submit A']);
    model.show(_b);
    await tester.pumpAndSettle();
    await _enter(tester, 'B draft\nwith layers');
    model.composerTextController.selection =
        const TextSelection.collapsed(offset: 3);
    model.acceptors.single();
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'B draft\nwith layers');
    model.show(_a);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, isEmpty);
    model.show(_b);
    await tester.pumpAndSettle();
    expect(model.composerTextController.selection,
        const TextSelection.collapsed(offset: 3));
    model.show(null);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, '  Unsent New chat  ');
    await model.clearChatStateOnLogout();
    await tester.pumpAndSettle();
    expect(_composer, findsNothing);
    expect(model.composerTextController.text, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('native latest button reaches newest messages after list growth',
      (tester) async {
    model.show(_a,
        history: List.generate(
            40,
            (index) => Message(
                role: 'user', content: 'Question $index\nLaminate load data')));
    await _mount(tester, model);
    final latest = find.byKey(const ValueKey('chat-jump-to-latest'));
    expect(latest, findsOneWidget);
    final readingOffset = model.scrollController.offset;
    model.messages = [
      ...model.messages,
      Message(role: 'user', content: 'Newest message\nNew layer data'),
    ];
    model.notifyListeners();
    model.scrollToBottom();
    await tester.pumpAndSettle();
    expect(model.scrollController.offset, readingOffset);
    await tester.tap(latest);
    await tester.pumpAndSettle();
    expect(model.scrollController.position.extentAfter, lessThan(1));
    expect(latest, findsNothing);
    model.show(null);
    await tester.pumpAndSettle();
    expect(latest, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
      'native draft badges follow originating accepted sends and logout',
      (tester) async {
    model.chats = [_a, _b];
    model.show(_a);
    model.acceptImmediately = false;
    await _mount(tester, model, locale: const Locale('zh', 'HK'));
    final strings = S.of(tester.element(find.byType(ChatScreen)));
    final badgeA = find.byKey(const ValueKey('chat-draft-badge-native-a'));
    final badgeB = find.byKey(const ValueKey('chat-draft-badge-native-b'));
    await _enter(tester, 'A awaiting acceptance');
    await tester.tap(find.byTooltip(strings.Chat_send_message));
    await tester.pumpAndSettle();
    model.show(_b);
    await tester.pumpAndSettle();
    await _enter(tester, '  B 私人草稿  ');
    model.acceptors.single();
    await tester.pumpAndSettle();
    expect(model.hasDraft(_a.id), isFalse);
    expect(model.hasDraft(_b.id), isTrue);
    expect(model.composerTextController.text, '  B 私人草稿  ');
    await _openDrawer(tester);
    expect(badgeA, findsNothing);
    expect(badgeB, findsOneWidget);
    expect(
        tester
            .widget<Text>(
                find.descendant(of: badgeB, matching: find.byType(Text)))
            .data,
        strings.Chat_draft);
    await _closeDrawer(tester);

    model.show(_a);
    await tester.pumpAndSettle();
    await _enter(tester, 'A second outgoing message');
    await tester.tap(find.byTooltip(strings.Chat_send_message));
    await tester.pumpAndSettle();
    await _enter(tester, 'A newer private draft');
    model.show(_b);
    await tester.pumpAndSettle();
    model.acceptors.last();
    await tester.pumpAndSettle();
    expect(model.hasDraft(_a.id), isTrue);
    expect(model.composerTextController.text, '  B 私人草稿  ');
    await _openDrawer(tester);
    expect(badgeA, findsOneWidget);
    expect(badgeB, findsOneWidget);
    expect(
        tester
            .widget<Text>(
                find.descendant(of: badgeA, matching: find.byType(Text)))
            .data,
        strings.Chat_draft);
    await _closeDrawer(tester);
    await _enter(tester, '  \n ');
    await _openDrawer(tester);
    expect(badgeA, findsOneWidget);
    expect(badgeB, findsNothing);
    await model.clearChatStateOnLogout();
    await tester.pumpAndSettle();
    expect(badgeA, findsNothing);
    expect(badgeB, findsNothing);
    expect(model.hasDraft(_a.id), isFalse);
    expect(model.hasDraft(_b.id), isFalse);
    expect(_composer, findsNothing);
    expect(model.sent, ['A awaiting acceptance', 'A second outgoing message']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('native selected header updates and retires private tooltips',
      (tester) async {
    final conversation =
        Chat(id: 'native-header', title: '${'碳纖維 laminate α 🌍 ' * 6}設計比較');
    model.show(conversation);
    await _mount(tester, model, locale: const Locale('zh', 'HK'));
    final strings = S.of(tester.element(find.byType(ChatScreen)));
    final header = find.byKey(const Key('chat-header-title'));
    final initialTitle = conversation.title;
    expect(tester.widget<Text>(header).data, initialTitle);
    expect(tester.widget<Text>(header).maxLines, 1);
    expect(tester.widget<Text>(header).overflow, TextOverflow.ellipsis);
    await tester.longPress(header);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_tooltipText(initialTitle), findsOneWidget);
    conversation.title = '重新命名：碳纖維 α [0/90]';
    model.notifyListeners();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(header).data, conversation.title);
    expect(_tooltipText(initialTitle), findsNothing);
    model.show(Chat(id: 'native-header-b', title: '玻璃纖維 β'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(header).data, '玻璃纖維 β');
    model.show(Chat(id: 'native-header-untitled', title: '  \n '));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(header).data, strings.Chat_untitled_chat);
    model.show(null);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(header).data, strings.Chat_title);
    model.show(conversation);
    await tester.pumpAndSettle();
    await tester.longPress(header);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_tooltipText(conversation.title), findsOneWidget);
    await model.clearChatStateOnLogout();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(header).data, strings.Chat_title);
    expect(_tooltipText(conversation.title), findsNothing);
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('native message timestamps use local time and scoped details',
      (tester) async {
    final question = Message(role: 'user', content: '時間戳記 α question')
      ..timestamp = DateTime.utc(2025, 3, 5, 13, 7).millisecondsSinceEpoch;
    final response = Message(role: 'assistant', content: '時間戳記 β answer')
      ..timestamp = DateTime.utc(2025, 3, 5, 13, 9).millisecondsSinceEpoch;
    model.show(_a, history: [question, response]);
    await _mount(tester, model, locale: const Locale('zh', 'HK'));
    final screenContext = tester.element(find.byType(ChatScreen));
    final strings = S.of(screenContext);
    final material = MaterialLocalizations.of(screenContext);
    final use24Hours = MediaQuery.of(screenContext).alwaysUse24HourFormat;
    String time(Message message) => material.formatTimeOfDay(
          TimeOfDay.fromDateTime(
              DateTime.fromMillisecondsSinceEpoch(message.timestamp).toLocal()),
          alwaysUse24HourFormat: use24Hours,
        );
    String detail(Message message) => strings.Chat_message_time(
        '${material.formatFullDate(DateTime.fromMillisecondsSinceEpoch(message.timestamp).toLocal())}, ${time(message)}');
    final questionTime =
        find.byKey(ValueKey('chat-message-time-${question.id}'));
    final responseTime =
        find.byKey(ValueKey('chat-message-time-${response.id}'));
    for (final entry in [(question, questionTime), (response, responseTime)]) {
      await tester.ensureVisible(entry.$2);
      await tester.pumpAndSettle();
      expect(find.descendant(of: entry.$2, matching: find.text(time(entry.$1))),
          findsOneWidget);
    }
    await tester.tap(responseTime);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_tooltipText(detail(response)), findsOneWidget);
    // Reusing the same message IDs in another chat must retire the old overlay.
    model.show(_b, history: [question, response]);
    await tester.pumpAndSettle();
    expect(_tooltipText(detail(response)), findsNothing);
    await tester.ensureVisible(questionTime);
    await tester.pumpAndSettle();
    await tester.tap(questionTime);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_tooltipText(detail(question)), findsOneWidget);
    await model.clearChatStateOnLogout();
    await tester.pumpAndSettle();
    expect(questionTime, findsNothing);
    expect(responseTime, findsNothing);
    expect(_tooltipText(detail(question)), findsNothing);
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('native question reuse replaces only explicitly approved text',
      (tester) async {
    const historyFile =
        ChatFile(id: 'native-source', name: 'original-layup.pdf', url: '');
    final question = Message(
      role: 'user',
      content: '  碳纖維 [0/90] 🌍\n重新計算？  ',
      files: [historyFile],
    );
    model.show(_a, history: [question]);
    model.files.add(_file);
    model.previews[_file.id] = png;
    final originalQuestion = question.toJson();
    await _mount(tester, model, locale: const Locale('zh', 'HK'));
    await _enter(tester, '  保留這份草稿\n直到確認  ');
    model.composerTextController.selection =
        const TextSelection.collapsed(offset: 4);
    final originalDraft = model.composerTextController.value;
    final useAsDraft = find.byKey(ValueKey('chat-use-as-draft-${question.id}'));
    await tester.ensureVisible(useAsDraft);
    await tester.pumpAndSettle();
    await tester.tap(useAsDraft);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-replace-draft-dialog')),
        findsOneWidget);
    expect(model.composerTextController.value, originalDraft);
    await tester.tap(find.byKey(const ValueKey('chat-replace-draft-cancel')));
    await tester.pumpAndSettle();
    expect(model.composerTextController.value, originalDraft);
    expect(question.toJson(), originalQuestion);
    expect(model.files, [_file]);
    expect(model.previews, {_file.id: png});
    expect(model.sent, isEmpty);

    await tester.tap(useAsDraft);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chat-replace-draft-confirm')));
    await tester.pumpAndSettle();
    await _hideKeyboard(tester);
    expect(
        find.byKey(const ValueKey('chat-replace-draft-dialog')), findsNothing);
    expect(model.composerTextController.text, question.content);
    expect(model.composerTextController.selection,
        TextSelection.collapsed(offset: question.content.length));
    expect(model.composerTextController.value.composing, TextRange.empty);
    expect(model.messages, [question]);
    expect(question.toJson(), originalQuestion);
    expect(model.files, [_file]);
    expect(model.previews, {_file.id: png});
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('native loaded chat search refreshes and retires on logout',
      (tester) async {
    const query = '碳纖 α[0].* 🌍';
    final question =
        Message(role: 'user', content: 'Question: $query / SI units?');
    final response = Message(role: 'assistant', content: 'Preparing answer…');
    final nearMatch =
        Message(role: 'user', content: 'Not literal: 碳纖 α0anything 🌍');
    model.show(_a, history: [question, response, nearMatch]);
    await _mount(tester, model, locale: const Locale('zh', 'HK'));
    await _enter(tester, '  搜尋不應改動這份草稿  ');
    final originalDraft = model.composerTextController.value;
    final strings = S.of(tester.element(find.byType(ChatScreen)));
    final findButton = find.byKey(const ValueKey('chat-find-in-chat'));
    final searchField = find.byKey(const ValueKey('chat-search-field'));
    final results = find.byKey(const ValueKey('chat-search-results'));
    await tester.tap(findButton);
    await tester.pumpAndSettle();
    expect(find.text(strings.Chat_search_empty), findsOneWidget);
    await tester.enterText(searchField, query);
    await _hideKeyboard(tester);
    expect(find.text(strings.Chat_search_match_count(1)), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-search-result-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-search-result-2')), findsNothing);
    expect(find.descendant(of: results, matching: find.text(question.content)),
        findsOneWidget);

    // The response keeps its identity as streamed tokens extend its content.
    response.content = 'Answer: $query / current streamed value';
    model.threadResponseController.add(response);
    model.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text(strings.Chat_search_match_count(2)), findsOneWidget);
    final streamedResult = find.byKey(const ValueKey('chat-search-result-1'));
    if (streamedResult.evaluate().isEmpty) {
      await tester.scrollUntilVisible(streamedResult, 160,
          scrollable: find
              .descendant(of: results, matching: find.byType(Scrollable))
              .first);
    }
    await tester.ensureVisible(streamedResult);
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: streamedResult, matching: find.text(response.content)),
        findsOneWidget);
    expect(model.composerTextController.value, originalDraft);
    expect(model.sent, isEmpty);
    final close = find.byKey(const ValueKey('chat-search-close'));
    if (close.evaluate().isEmpty) {
      await tester.scrollUntilVisible(close, -160,
          scrollable: find
              .descendant(of: results, matching: find.byType(Scrollable))
              .first);
    }
    await tester.ensureVisible(close);
    await tester.pumpAndSettle();
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(searchField, findsNothing);
    expect(model.composerTextController.value, originalDraft);

    await tester.tap(findButton);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(searchField).controller!.text, isEmpty);
    await tester.enterText(searchField, query);
    await _hideKeyboard(tester);
    expect(find.text(strings.Chat_search_match_count(2)), findsOneWidget);
    await model.clearChatStateOnLogout();
    await tester.pumpAndSettle();
    expect(searchField, findsNothing);
    expect(results, findsNothing);
    expect(find.byKey(const ValueKey('chat-search-result-0')), findsNothing);
    expect(find.byKey(const ValueKey('chat-search-result-1')), findsNothing);
    expect(_composer, findsNothing);
    expect(model.composerTextController.text, isEmpty);
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
      'native pending image preview preserves input and closes on logout',
      (tester) async {
    model.files.add(_file);
    model.previews[_file.id] = png;
    await _mount(tester, model, locale: const Locale('zh', 'HK'));
    await _enter(tester, 'Inspect this attachment');
    final preview =
        find.byKey(const ValueKey('pending-image-preview-native-image'));
    await tester.tap(preview);
    await tester.pumpAndSettle();
    await _expectDecodedPreview(tester);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.drag(find.byType(InteractiveViewer), const Offset(20, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pending-image-preview-close')));
    await tester.pumpAndSettle();
    expect(model.files, [_file]);
    expect(model.composerTextController.text, 'Inspect this attachment');
    expect(model.sent, isEmpty);
    await tester.tap(preview);
    await tester.pumpAndSettle();
    await _expectDecodedPreview(tester);
    await model.clearChatStateOnLogout();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pending-image-preview-dialog')),
        findsNothing);
    expect(_composer, findsNothing);
    expect(model.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
    'native expanded editor preserves raw drafts and retires on chat change',
    (tester) async {
      const bDraft = '  B 草稿 α\n保持原樣  ';
      const original = '  A question α [0/90]\nSecond line 🌍  ';
      const edited = '  A revised question β\n[45/-45] 🌍\nTrailing spaces  ';
      const laterEdit = '  A latest unsent value γ\nAfter reopening  ';
      final expand = find.byKey(const Key('chat-expand-composer'));
      final dialog = find.byKey(const Key('chat-expanded-composer-dialog'));
      final editor = find.byKey(const Key('chat-expanded-composer'));
      final done = find.byKey(const Key('chat-expanded-composer-done'));
      try {
        model.show(_b);
        await _mount(tester, model, locale: const Locale('zh', 'HK'));
        await _enter(tester, bDraft);
        final bValue = model.composerTextController.value;
        model.show(_a);
        await tester.pumpAndSettle();
        await _enter(tester, original);
        model.composerTextController.selection = const TextSelection(
          baseOffset: 2,
          extentOffset: 12,
        );
        final originalValue = model.composerTextController.value;

        // Two taps before the next frame must still create just one editor.
        await tester.tap(expand);
        await tester.tap(expand, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(dialog, findsOneWidget);
        expect(editor, findsOneWidget);
        expect(
          tester.widget<TextField>(editor).controller!.value,
          originalValue,
        );
        await tester.tap(editor);
        await tester.pumpAndSettle();
        await tester.enterText(editor, edited);
        await tester.pump();
        await _hideKeyboard(tester);
        final editedValue = tester.widget<TextField>(editor).controller!.value;
        expect(editedValue.text, edited);
        expect(
          editedValue.selection,
          TextSelection.collapsed(offset: edited.length),
        );
        await _tapVisible(tester, done);
        await _hideKeyboard(tester);
        expect(dialog, findsNothing);
        expect(model.composerTextController.value, editedValue);
        expect(
          tester.widget<TextField>(_composer).controller!.value,
          editedValue,
        );
        expect(model.sent, isEmpty);

        await _tapVisible(tester, expand);
        expect(tester.widget<TextField>(editor).controller!.value, editedValue);
        await tester.tap(editor);
        await tester.pumpAndSettle();
        await tester.enterText(editor, laterEdit);
        await tester.pump();
        await _hideKeyboard(tester);
        final latestValue = tester.widget<TextField>(editor).controller!.value;
        model.show(_b);
        await tester.pumpAndSettle();
        expect(dialog, findsNothing);
        expect(editor, findsNothing);
        expect(model.composerTextController.value, bValue);
        model.show(_a);
        await tester.pumpAndSettle();
        expect(model.composerTextController.value, latestValue);
        expect(model.composerTextController.text, laterEdit);
        expect(model.files, isEmpty);
        expect(model.sent, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await _hideKeyboard(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'native find shortcut respects focus, modifiers and one search route',
    (tester) async {
      const draft = '  Keep this draft α\nShortcut must not send  ';
      final question = Message(
        role: 'user',
        content: 'Searchable laminate α data',
      );
      final search = find.byKey(const ValueKey('chat-search-field'));
      final close = find.byKey(const ValueKey('chat-search-close'));
      try {
        model.show(_a, history: [question]);
        await _mount(tester, model, locale: const Locale('zh', 'HK'));
        await _enter(tester, draft);
        await tester.tap(_composer);
        await tester.pumpAndSettle();
        final draftValue = model.composerTextController.value;
        await _findShortcut(tester, shift: true);
        expect(search, findsNothing);
        expect(model.composerTextController.value, draftValue);
        await _findShortcut(tester);
        expect(search, findsOneWidget);
        expect(close, findsOneWidget);
        await _findShortcut(tester);
        expect(search, findsOneWidget);
        expect(close, findsOneWidget);
        await tester.tap(search);
        await tester.pumpAndSettle();
        await tester.enterText(search, 'laminate α');
        await _hideKeyboard(tester);
        expect(
          find.byKey(const ValueKey('chat-search-result-0')),
          findsOneWidget,
        );
        await _tapVisible(tester, close);
        expect(search, findsNothing);
        expect(model.composerTextController.value, draftValue);

        // A new unsaved conversation has no loaded history to search.
        model.show(null);
        await tester.pumpAndSettle();
        await tester.tap(_composer);
        await tester.pumpAndSettle();
        await _findShortcut(tester);
        expect(search, findsNothing);
        await _hideKeyboard(tester);
        model.show(_a, history: [question]);
        await tester.pumpAndSettle();
        expect(model.composerTextController.value, draftValue);
        expect(model.sent, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await _hideKeyboard(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets('native editor closes safely when its chat model is disposed',
      (tester) async {
    model.show(_a);
    await _mount(tester, model);
    await _enter(tester, 'Draft before disposing the model');
    await tester.tap(find.byKey(const Key('chat-expand-composer')));
    await tester.pumpAndSettle();
    final editor = find.byKey(const Key('chat-expanded-composer'));
    await tester.enterText(editor, 'Expanded draft before disposal');
    model.dispose();
    await tester.pumpAndSettle();
    expect(editor, findsNothing);
    expect(_composer, findsNothing);
    await _hideKeyboard(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('native answer folding keeps full clipboard and Markdown file', (
    tester,
  ) async {
    final content = '  # Native laminate answer α\n\n'
        '```text\n[0/90/45/-45]\n```\n\n'
        '${List.generate(24, (index) => 'Layer $index: retain the complete carbon-fibre explanation β and all calculation detail.').join('\n')}\n'
        'NATIVE_FULL_ANSWER_END 🌍  ';
    final answer = Message(role: 'assistant', content: content)..isDone = true;
    final original = answer.toJson();
    final toggle = find.byKey(ValueKey('chat-answer-toggle-${answer.id}'));
    final preview = find.byKey(ValueKey('chat-answer-preview-${answer.id}'));
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    File? exportedFile;
    // Leave SharePlus and XFile serialization intact; intercept only the final
    // system share sheet so the smoke run can inspect the actual device file.
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      calls.add(call);
      return '';
    });
    try {
      model.show(_a, history: [answer]);
      await _mount(tester, model, locale: const Locale('zh', 'HK'));
      final strings = S.of(tester.element(find.byType(ChatScreen)));
      expect(toggle, findsOneWidget);
      expect(preview, findsNothing);
      expect(
        tester
            .widget<AiMarkdownMessage>(find.byType(AiMarkdownMessage))
            .markdown,
        content,
      );
      expect(find.text(strings.Chat_collapse_answer), findsOneWidget);
      await _tapVisible(tester, toggle);
      expect(preview, findsOneWidget);
      expect(find.byType(AiMarkdownMessage), findsNothing);
      expect(find.text(strings.Chat_expand_answer), findsOneWidget);
      expect(answer.toJson(), original);

      await _tapVisible(tester, find.byTooltip(strings.Chat_copy_message));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, content);
      await _tapVisible(
        tester,
        find.byTooltip(strings.Chat_export_conversation),
      );
      await _tapVisible(tester, find.text(strings.Chat_share_markdown));
      for (var attempt = 0; attempt < 100 && calls.isEmpty; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(calls, hasLength(1));
      final request = calls.single.arguments as Map;
      exportedFile = File((request['paths'] as List).single as String);
      expect(calls.single.method, 'share');
      expect(request['mimeTypes'], ['text/markdown']);
      expect(request['originWidth'], greaterThan(0));
      expect(request['originHeight'], greaterThan(0));
      expect(exportedFile.uri.pathSegments.last, 'Laminate_A.md');
      final exported = utf8.decode(await exportedFile.readAsBytes());
      expect(exported, contains(content.trim()));
      expect(exported, contains('Layer 23:'));
      expect(exported, contains('NATIVE_FULL_ANSWER_END 🌍'));
      expect(answer.toJson(), original);
      expect(preview, findsOneWidget);

      await _tapVisible(tester, toggle);
      expect(preview, findsNothing);
      expect(
        tester
            .widget<AiMarkdownMessage>(find.byType(AiMarkdownMessage))
            .markdown,
        content,
      );
      expect(model.sent, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      messenger.setMockMethodCallHandler(shareChannel, null);
      if (exportedFile != null && await exportedFile.exists()) {
        await exportedFile.delete();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
