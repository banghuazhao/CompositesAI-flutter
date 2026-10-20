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
Finder get _composer => find.byWidgetPredicate((widget) =>
    widget is TextField &&
    widget.decoration?.hintText == 'Ask about composites engineering…');

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
}
