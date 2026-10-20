import 'dart:async';
import 'dart:ui' as ui;

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_file.dart';
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
import 'package:swiftcomp/presentation/chat/views/pending_image_attachment.dart';

class _UseCase extends Fake implements ChatUseCase {}

class _FeatureModel extends ChatViewModel {
  _FeatureModel()
      : super(
          chatUseCase: _UseCase(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'account-a', email: 'a@example.test');
  }

  final attachments = <ChatFile>[];
  final previews = <String, Uint8List>{};
  final submitted = <String>[];
  final acceptors = <VoidCallback>[];
  bool acceptImmediately = true;

  @override
  List<ChatFile> get pendingFiles => attachments;
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
    attachments.removeWhere((pending) => pending.id == file.id);
    previews.remove(file.id);
    notifyListeners();
  }

  @override
  Future<void> sendInputMessage(String text,
      {VoidCallback? onMessageAccepted}) async {
    submitted.add(text);
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

final _chatA = Chat(id: 'a', title: 'Laminate A');
final _chatB = Chat(id: 'b', title: 'Laminate B');
const _image = ChatFile(id: 'image-a', name: 'layup.png', url: '');
Finder get _composer => find.byWidgetPredicate((widget) =>
    widget is TextField &&
    widget.decoration?.hintText == 'Ask about composites engineering…');

Future<void> _pump(WidgetTester tester, _FeatureModel model,
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
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale), disableAnimations: true),
        child: child!,
      ),
      home: const ChatScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FeatureModel model;
  late Uint8List imageBytes;

  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(4, 3);
    imageBytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    image.dispose();
    picture.dispose();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    model = _FeatureModel();
  });
  tearDown(() => model.dispose());

  testWidgets('A B and New chat restore raw drafts and exact selection',
      (tester) async {
    await _pump(tester, model);
    await tester.enterText(_composer, '  New chat\ndraft  ');
    model.composerTextController.selection =
        const TextSelection(baseOffset: 3, extentOffset: 6);
    model.show(_chatA);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, isEmpty);
    await tester.enterText(_composer, '  Carbon\nlamina A  ');
    const selection = TextSelection(baseOffset: 10, extentOffset: 2);
    model.composerTextController.selection = selection;
    model.show(_chatB);
    await tester.pumpAndSettle();
    await tester.enterText(_composer, 'Glass B');
    model.show(_chatA);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_composer).controller!.text,
        '  Carbon\nlamina A  ');
    expect(model.composerTextController.selection, selection);
    model.show(null);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, '  New chat\ndraft  ');
    expect(model.composerTextController.selection,
        const TextSelection(baseOffset: 3, extentOffset: 6));
    expect(model.submitted, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a delayed accepted send clears only its original chat draft',
      (tester) async {
    model.acceptImmediately = false;
    model.show(_chatA);
    await _pump(tester, model);
    await tester.enterText(_composer, '  Send A  ');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(model.submitted, ['Send A']);
    model.show(_chatB);
    await tester.pumpAndSettle();
    await tester.enterText(_composer, 'Private B draft');
    model.acceptors.single();
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'Private B draft');
    model.show(_chatA);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('new edits and rejected sends remain in the composer',
      (tester) async {
    model.acceptImmediately = false;
    model.show(_chatA);
    await _pump(tester, model);
    await tester.enterText(_composer, 'Original');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(_composer, 'New unsent question');
    model.acceptors.single();
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'New unsent question');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'New unsent question');
    expect(model.submitted, ['Original', 'New unsent question']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('same account screen remount keeps drafts and logout clears them',
      (tester) async {
    model.show(_chatA);
    await _pump(tester, model);
    await tester.enterText(_composer, 'Keep across screen remount');
    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester, model);
    expect(model.composerTextController.text, 'Keep across screen remount');
    await model.clearChatStateOnLogout();
    await tester.pumpAndSettle();
    expect(_composer, findsNothing);
    model.user = User(id: 'account-b', email: 'b@example.test');
    model.isLoggedIn = true;
    model.show(_chatA);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'latest stays above attachments and keyboard without forced scroll',
      (tester) async {
    final history = List.generate(
        30,
        (index) =>
            Message(role: 'user', content: 'Question $index\nLayup data'));
    model.show(_chatA, history: history);
    model.attachments.add(_image);
    model.previews[_image.id] = imageBytes;
    await _pump(tester, model);
    model.scrollController
        .jumpTo(model.scrollController.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final latest = find.byKey(const Key('chat-jump-to-latest'));
    expect(latest, findsNothing);
    model.scrollController.jumpTo(0);
    await tester.pumpAndSettle();
    expect(latest, findsOneWidget);
    expect(
        tester.getRect(latest).bottom,
        lessThanOrEqualTo(
            tester.getRect(find.byType(PendingImageAttachment)).top));
    final offset = model.scrollController.offset;
    model.messages = [
      ...model.messages,
      Message(role: 'user', content: 'New reply')
    ];
    model.notifyListeners();
    model.scrollToBottom();
    await tester.pumpAndSettle();
    expect(model.scrollController.offset, offset);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    expect(latest.hitTestable(), findsOneWidget);
    await tester.tap(latest);
    await tester.pumpAndSettle();
    expect(model.scrollController.position.extentAfter, lessThan(1));
    expect(latest, findsNothing);
    model.show(null);
    await tester.pumpAndSettle();
    expect(latest, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pending image preview leaves attachment and composer unchanged',
      (tester) async {
    model.attachments.add(_image);
    model.previews[_image.id] = imageBytes;
    await _pump(tester, model, locale: const Locale('zh', 'HK'), scale: 2);
    await tester.enterText(_composer, 'Inspect before sending');
    final preview = find.byKey(ValueKey('pending-image-preview-${_image.id}'));
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text(_image.name), findsOneWidget);
    final close = find.byKey(const Key('pending-image-preview-close'));
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(model.pendingFiles, [_image]);
    expect(model.composerTextController.text, 'Inspect before sending');
    expect(model.submitted, isEmpty);
    await tester.tap(find.byKey(ValueKey('pending-image-remove-${_image.id}')));
    await tester.pumpAndSettle();
    expect(model.pendingFiles, isEmpty);
    expect(model.submitted, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('logout removes its exact image dialog beneath a newer route',
      (tester) async {
    model.attachments.add(_image);
    model.previews[_image.id] = imageBytes;
    await _pump(tester, model);
    await tester
        .tap(find.byKey(ValueKey('pending-image-preview-${_image.id}')));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Newer route')))));
    await tester.pumpAndSettle();
    await model.clearChatStateOnLogout();
    await tester.pumpAndSettle();
    expect(find.text('Newer route'), findsOneWidget);
    expect(
        find.byKey(const Key('pending-image-preview-dialog'),
            skipOffstage: false),
        findsNothing);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(_composer, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('late voice initialization cannot overwrite another chat draft',
      (tester) async {
    const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final initialize = Completer<bool>();
    messenger.setMockMethodCallHandler(channel,
        (call) async => call.method == 'initialize' ? initialize.future : null);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    model.show(_chatA);
    await _pump(tester, model);
    await tester.tap(find.byTooltip('Start voice input'));
    await tester.pump();
    model.show(_chatB);
    await tester.pumpAndSettle();
    await tester.enterText(_composer, 'Keep B');
    initialize.complete(false);
    await tester.pumpAndSettle();
    expect(model.composerTextController.text, 'Keep B');
    expect(find.textContaining('Voice input is unavailable'), findsNothing);
    expect(find.byTooltip('Stop voice input'), findsNothing);
    expect(find.byTooltip('Send message'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
