import 'dart:io';
import 'dart:ui' as ui;

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/chat_knowledge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';
import 'package:swiftcomp/util/app_theme.dart';

const _screenshotDirectory = String.fromEnvironment('CHAT_UI_SCREENSHOT_DIR');
const _fontDirectory = String.fromEnvironment('CHAT_UI_FONT_DIR');
const _screenshotKey = ValueKey('chat-ui-screenshot');

Future<void> _loadScreenshotFont(String family, String fileName) async {
  final loader = FontLoader(family)
    ..addFont(
      File('$_fontDirectory/$fileName')
          .readAsBytes()
          .then(ByteData.sublistView),
    );
  await loader.load();
}

class _ChatUseCase extends Fake implements ChatUseCase {}

class _ChatScreenViewModel extends ChatViewModel {
  _ChatScreenViewModel()
      : super(
          chatUseCase: _ChatUseCase(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(
      email: 'engineer@example.com',
      name: 'Composites Engineer',
      isCompositeExpert: true,
    );
  }

  final List<ChatFile> attachments = [];
  final List<String> removedFileIds = [];
  final List<String> sentMessages = [];
  final List<ChatKnowledge> knowledge = List.generate(
    12,
    (index) => ChatKnowledge(
      id: 'knowledge-$index',
      name: 'Knowledge source ${index + 1}',
      description: 'Engineering references for laminate design and analysis.',
      files: [
        ChatFile(
          id: 'document-$index',
          name: 'Laminate reference ${index + 1}.pdf',
          url: '',
          collectionName: 'knowledge-$index',
        ),
      ],
    ),
  );

  @override
  List<ChatFile> get pendingFiles => attachments;

  @override
  List<ChatKnowledge> get knowledgeBases => knowledge;

  @override
  Future<void> fetchAuthSessionNew() async {}

  @override
  Future<void> fetchChats() async {}

  @override
  Future<void> fetchTools() async {}

  @override
  Future<void> fetchKnowledgeBases() async {}

  @override
  void removePendingFile(ChatFile file) {
    removedFileIds.add(file.id);
    attachments.remove(file);
    notifyListeners();
  }

  @override
  Future<void> sendInputMessage(
    String text, {
    VoidCallback? onMessageAccepted,
  }) async {
    sentMessages.add(text);
    onMessageAccepted?.call();
    notifyListeners();
  }
}

Finder _iconButton(String tooltip) => find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == tooltip,
    );

Future<void> _pumpTransitions(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

Future<void> _captureScreenshot(WidgetTester tester, String name) async {
  if (_screenshotDirectory.isEmpty) return;
  await _pumpTransitions(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_screenshotKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory(_screenshotDirectory);
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> _pumpChatScreen(
  WidgetTester tester,
  _ChatScreenViewModel viewModel, {
  Size size = const Size(375, 667),
  bool dark = false,
  double textScale = 2,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(viewModel.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider<ChatViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        builder: (context, child) => RepaintBoundary(
          key: _screenshotKey,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
        ),
        home: const ChatScreen(),
      ),
    ),
  );
  await _pumpTransitions(tester);
}

void main() {
  setUpAll(() async {
    if (_fontDirectory.isEmpty) return;
    await Future.wait([
      _loadScreenshotFont('Roboto', 'Roboto-Regular.ttf'),
      _loadScreenshotFont('MaterialIcons', 'MaterialIcons-Regular.otf'),
    ]);
  });

  const sizes = [Size(375, 667), Size(667, 375), Size(1200, 800)];

  for (final size in sizes) {
    for (final dark in [false, true]) {
      testWidgets(
        'account action stays accessible at $size, dark=$dark, 2x text',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await _pumpChatScreen(
              tester,
              _ChatScreenViewModel(),
              size: size,
              dark: dark,
            );

            final button = _iconButton('Account & settings');
            expect(button, findsOneWidget);
            final bounds = tester.getRect(button);
            expect(bounds.width, greaterThanOrEqualTo(48));
            expect(bounds.height, greaterThanOrEqualTo(48));
            expect(size.width - bounds.right, greaterThanOrEqualTo(12));

            final data = tester.getSemantics(button).getSemanticsData();
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
            expect('${data.label} ${data.tooltip}',
                contains('Account & settings'));
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
            await tester.pumpWidget(const SizedBox.shrink());
          }
        },
      );
    }
  }

  if (_screenshotDirectory.isNotEmpty) {
    for (final dark in [false, true]) {
      testWidgets('capture standard phone layout, dark=$dark', (tester) async {
        await _pumpChatScreen(
          tester,
          _ChatScreenViewModel(),
          dark: dark,
          textScale: 1,
        );
        expect(tester.takeException(), isNull);
        await _captureScreenshot(tester, dark ? 'chat-dark' : 'chat-light');
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('knowledge picker scrolls above the keyboard on a small phone',
      (tester) async {
    await _pumpChatScreen(tester, _ChatScreenViewModel());
    await tester.tap(find.byTooltip('Add attachment'));
    await _pumpTransitions(tester);
    final knowledgeOption = find.widgetWithText(ListTile, 'Knowledge');
    await tester.ensureVisible(knowledgeOption);
    await _pumpTransitions(tester);
    await tester.tap(knowledgeOption);
    await _pumpTransitions(tester);

    final search = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Search knowledge',
    );
    await tester.tap(search);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await _pumpTransitions(tester);
    expect(tester.takeException(), isNull);
    await _captureScreenshot(tester, 'knowledge-keyboard-2x');

    final scrollable = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(scrollable, findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Knowledge source 12'),
      200,
      scrollable: scrollable,
      maxScrolls: 30,
    );
    await _pumpTransitions(tester);
    expect(find.text('Knowledge source 12'), findsOneWidget);
    final lastSource = tester.getRect(find.text('Knowledge source 12'));
    expect(lastSource.bottom, lessThanOrEqualTo(667 - 300));
    expect(tester.takeException(), isNull);
    await _captureScreenshot(tester, 'knowledge-keyboard-scrolled-2x');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pending image can be removed through its labeled touch target',
      (tester) async {
    final viewModel = _ChatScreenViewModel()
      ..attachments.add(
        const ChatFile(id: 'image', name: 'laminate.png', url: ''),
      );
    await _pumpChatScreen(tester, viewModel, textScale: 1);

    final remove = _iconButton('Remove laminate.png');
    expect(remove, findsOneWidget);
    expect(tester.getSize(remove).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(remove).height, greaterThanOrEqualTo(48));
    await tester.tap(remove);
    await _pumpTransitions(tester);

    expect(viewModel.removedFileIds, ['image']);
    expect(viewModel.pendingFiles, isEmpty);
    expect(remove, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Shift+Enter preserves the caret for one editor newline',
      (tester) async {
    final viewModel = _ChatScreenViewModel();
    await _pumpChatScreen(tester, viewModel, textScale: 1);
    final composer = find.byType(TextField);
    await tester.enterText(composer, 'abcd');
    final controller = tester.widget<TextField>(composer).controller!;
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(controller.text, 'abcd');
    expect(controller.selection, const TextSelection.collapsed(offset: 2));

    // Widget tests stub the native IME, so deliver its newline edit after
    // verifying the shortcut left both the text and caret for the editor.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'ab\ncd',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await _pumpTransitions(tester);
    expect(controller.text, 'ab\ncd');
    expect(controller.selection, const TextSelection.collapsed(offset: 3));
    expect(viewModel.sentMessages, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Enter sends once and leaves no newline in the cleared draft',
      (tester) async {
    final viewModel = _ChatScreenViewModel();
    await _pumpChatScreen(tester, viewModel, textScale: 1);
    final composer = find.byType(TextField);
    await tester.enterText(composer, '  Analyze this laminate  ');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _pumpTransitions(tester);

    expect(viewModel.sentMessages, ['Analyze this laminate']);
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
    expect(tester.widget<TextField>(composer).focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  // Neither case succeeds, so SpeechToText's singleton does not cache an
  // available recognizer and the tests remain independent of their order.
  for (final throwsOnInitialize in [false, true]) {
    testWidgets(
      'voice input reports ${throwsOnInitialize ? 'initialization errors' : 'unavailability'} and stays idle',
      (tester) async {
        const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        var initializeCalls = 0;
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'initialize') {
            initializeCalls++;
            if (throwsOnInitialize) {
              throw PlatformException(code: 'microphone_permission_denied');
            }
            return false;
          }
          return null;
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

        await _pumpChatScreen(tester, _ChatScreenViewModel(), textScale: 1);
        await tester.tap(find.byTooltip('Start voice input'));
        await _pumpTransitions(tester);

        expect(initializeCalls, 1);
        expect(
          find.text(
            'Voice input is unavailable. Please check microphone permissions.',
          ),
          findsOneWidget,
        );
        expect(find.byTooltip('Start voice input'), findsOneWidget);
        expect(find.byTooltip('Stop voice input'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
