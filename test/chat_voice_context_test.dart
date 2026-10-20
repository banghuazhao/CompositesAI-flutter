import 'dart:async';
import 'dart:convert';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
// Native-style events exercise the real cached SpeechToText singleton.
// ignore: depend_on_referenced_packages
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart'
    show SpeechToTextPlatform;
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';

final _chatA = Chat(id: 'voice-a', title: 'Voice A');
final _chatB = Chat(id: 'voice-b', title: 'Voice B');

Finder get _composer => find.byKey(const Key('chat-composer'));

Future<void> _mount(WidgetTester tester, _VoiceModel model) async {
  tester.view.physicalSize = const Size(390, 820);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<ChatViewModel>.value(
    value: model,
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: const ChatScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _start(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Start voice input'));
  await tester.pumpAndSettle();
  expect(find.byTooltip('Stop voice input'), findsOneWidget);
}

Future<void> _cleanup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // ChatScreen stops speech during disposal. Cancel afterwards so the plugin's
  // pause/final-result timers cannot outlive the widget test's fake clock.
  await SpeechToText().cancel();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final speech = _SpeechPlatform();
  late SpeechToTextPlatform previousPlatform;
  late _VoiceModel model;

  setUpAll(() {
    previousPlatform = SpeechToTextPlatform.instance;
    SpeechToTextPlatform.instance = speech;
  });
  tearDownAll(() => SpeechToTextPlatform.instance = previousPlatform);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    speech.pendingStop = null;
    model = _VoiceModel()..show(_chatA);
  });
  tearDown(() => model.dispose());

  testWidgets(
      'cached successful initialization refreshes done and error callbacks',
      (tester) async {
    try {
      await _mount(tester, model);
      await _start(tester);
      speech.result('First session partial');
      await tester.pumpAndSettle();
      expect(model.composerTextController.text, 'First session partial');
      await tester.tap(find.byTooltip('Stop voice input'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Stop voice input'), findsNothing);
      expect(find.byTooltip('Send message'), findsOneWidget);

      await tester.enterText(_composer, '');
      final initializationsBeforeRestart = speech.initializations;
      final listensBeforeRestart = speech.listens;
      await _start(tester);
      expect(speech.initializations, initializationsBeforeRestart,
          reason: 'SpeechToText caches a successful initialize call.');
      expect(speech.listens, listensBeforeRestart + 1);
      speech.result('Second session final', finalResult: true);
      speech.status(SpeechToText.doneStatus);
      await tester.pumpAndSettle();
      expect(model.composerTextController.text, 'Second session final');
      expect(find.byTooltip('Stop voice input'), findsNothing);
      expect(find.byTooltip('Send message'), findsOneWidget);

      await tester.enterText(_composer, '');
      await _start(tester);
      speech.error('error_network');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Stop voice input'), findsNothing);
      expect(find.byTooltip('Start voice input'), findsOneWidget);
      expect(find.textContaining('Voice input is unavailable'), findsOneWidget);
      expect(model.composerTextController.text, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      await _cleanup(tester);
    }
  });

  testWidgets(
      'notListening A to B to A rejects an old final recognition result',
      (tester) async {
    try {
      await _mount(tester, model);
      await _start(tester);
      speech.result('Original A partial');
      speech.status(SpeechToText.notListeningStatus);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Stop voice input'), findsNothing);

      model.show(_chatB);
      await tester.pumpAndSettle();
      await tester.enterText(_composer, 'Keep B draft');
      model.show(_chatA);
      await tester.pumpAndSettle();
      await tester.enterText(_composer, 'Edited A after returning');
      model.composerTextController.selection =
          const TextSelection(baseOffset: 3, extentOffset: 14);
      final before = model.composerTextController.value;

      speech.result('Late original A final', finalResult: true);
      await tester.pumpAndSettle();
      expect(model.composerTextController.value, before);
      expect(find.byTooltip('Stop voice input'), findsNothing);
      expect(find.textContaining('Voice input is unavailable'), findsNothing);
      model.show(_chatB);
      await tester.pumpAndSettle();
      expect(model.composerTextController.text, 'Keep B draft');
      expect(tester.takeException(), isNull);
    } finally {
      await _cleanup(tester);
    }
  });

  testWidgets('same-context final results remain valid after notListening',
      (tester) async {
    try {
      await _mount(tester, model);
      await _start(tester);
      speech.result('A partial');
      speech.status(SpeechToText.notListeningStatus);
      await tester.pumpAndSettle();
      expect(model.composerTextController.text, 'A partial');
      expect(find.byTooltip('Stop voice input'), findsNothing);

      speech.result('A completed recognition', finalResult: true);
      await tester.pumpAndSettle();
      expect(model.composerTextController.text, 'A completed recognition');
      expect(find.byTooltip('Send message'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await _cleanup(tester);
    }
  });

  testWidgets('account transitions retire a visually stopped recognition scope',
      (tester) async {
    try {
      await _mount(tester, model);
      await _start(tester);
      speech.result('Private account A speech');
      speech.status(SpeechToText.notListeningStatus);
      await tester.pumpAndSettle();
      model.user = User(id: 'voice-account-b', email: 'voice-b@example.test');
      model.notifyListeners();
      await tester.pumpAndSettle();
      await tester.enterText(_composer, 'Private account B draft');
      final before = model.composerTextController.value;

      speech.result('Late private account A result', finalResult: true);
      await tester.pumpAndSettle();
      expect(model.composerTextController.value, before);
      expect(find.textContaining('Voice input is unavailable'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await _cleanup(tester);
    }
  });

  testWidgets('sending retires late final results after notListening or Stop',
      (tester) async {
    try {
      await _mount(tester, model);
      for (final explicitStop in [false, true]) {
        await tester.enterText(_composer, '');
        await _start(tester);
        final partial = 'Voice partial, explicit Stop: $explicitStop';
        speech.result(partial);
        await tester.pumpAndSettle();
        if (explicitStop) {
          await tester.tap(find.byTooltip('Stop voice input'));
        } else {
          speech.status(SpeechToText.notListeningStatus);
        }
        await tester.pumpAndSettle();
        expect(find.byTooltip('Stop voice input'), findsNothing);
        await tester.tap(find.byTooltip('Send message'));
        await tester.pumpAndSettle();
        expect(model.sent.last, partial);
        expect(model.composerTextController.text, isEmpty);

        await tester.enterText(_composer, 'New follow-up after sending');
        model.composerTextController.selection =
            const TextSelection(baseOffset: 2, extentOffset: 11);
        final followUp = model.composerTextController.value;
        speech.result('Late final that was already sent', finalResult: true);
        await tester.pumpAndSettle();
        expect(model.composerTextController.value, followUp);
        expect(find.byTooltip('Stop voice input'), findsNothing);
      }
      expect(model.sent, hasLength(2));
      expect(tester.takeException(), isNull);
    } finally {
      await _cleanup(tester);
    }
  });

  testWidgets('a new chat attempt waits for an earlier pending platform Stop',
      (tester) async {
    final stopGate = Completer<void>();
    try {
      await _mount(tester, model);
      await _start(tester);
      speech.result('A speech before stopping');
      await tester.pumpAndSettle();
      speech.pendingStop = stopGate;
      await tester.tap(find.byTooltip('Stop voice input'));
      await tester.pumpAndSettle();
      expect(stopGate.isCompleted, isFalse);

      model.show(_chatB);
      await tester.pumpAndSettle();
      expect(model.composerTextController.text, isEmpty);
      final listensBeforeB = speech.listens;
      await tester.tap(find.byTooltip('Start voice input'));
      await tester.pumpAndSettle();
      expect(speech.listens, listensBeforeB,
          reason: 'The old stop must finish before B installs a new listen.');
      expect(find.byTooltip('Stop voice input'), findsNothing);

      stopGate.complete();
      await tester.pumpAndSettle();
      expect(speech.listens, listensBeforeB + 1);
      expect(find.byTooltip('Stop voice input'), findsOneWidget);
      speech.result('Current B recognition');
      await tester.pumpAndSettle();
      expect(model.composerTextController.text, 'Current B recognition');
      expect(find.byTooltip('Stop voice input'), findsOneWidget,
          reason: 'Completion of A Stop must not reset B listening UI.');
      expect(tester.takeException(), isNull);
    } finally {
      if (!stopGate.isCompleted) stopGate.complete();
      await tester.pumpAndSettle();
      await _cleanup(tester);
    }
  });

  testWidgets(
      'reusing a question retires active and visually stopped voice results',
      (tester) async {
    try {
      final question =
          Message(role: 'user', content: 'Reuse this earlier question');
      model.messages = [question];
      await _mount(tester, model);
      for (final visuallyStopped in [false, true]) {
        await tester.enterText(_composer, '');
        await _start(tester);
        speech.result('A voice draft before reuse');
        if (visuallyStopped) speech.status(SpeechToText.notListeningStatus);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Use as draft'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Stop voice input'), findsNothing);
        await tester
            .tap(find.byKey(const ValueKey('chat-replace-draft-confirm')));
        await tester.pumpAndSettle();
        expect(model.composerTextController.text, question.content);
        speech.result('Old final must not replace the reused question',
            finalResult: true);
        await tester.pumpAndSettle();
        expect(model.composerTextController.text, question.content);
        expect(model.sent, isEmpty);
      }
      expect(tester.takeException(), isNull);
    } finally {
      await _cleanup(tester);
    }
  });
}

class _UseCase extends Fake implements ChatUseCase {}

class _VoiceModel extends ChatViewModel {
  _VoiceModel()
      : super(
          chatUseCase: _UseCase(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'voice-account-a', email: 'voice-a@example.test');
  }

  final sent = <String>[];

  void show(Chat chat) {
    selectedChat = chat;
    messages = [];
    notifyListeners();
  }

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
}

class _SpeechPlatform extends SpeechToTextPlatform {
  int initializations = 0;
  int listens = 0;
  Completer<void>? pendingStop;

  void status(String value) => onStatus?.call(value);

  void result(String words, {bool finalResult = false}) =>
      onTextRecognition?.call(jsonEncode({
        'alternates': [
          {'recognizedWords': words, 'confidence': 0.95},
        ],
        'resultType': finalResult ? 2 : 0,
      }));

  void error(String message) => onError?.call(jsonEncode({
        'errorMsg': message,
        'permanent': false,
      }));

  @override
  Future<bool> initialize(
      {debugLogging = false, List<SpeechConfigOption>? options}) async {
    initializations++;
    return true;
  }

  @override
  Future<bool> listen({
    String? localeId,
    partialResults = true,
    onDevice = false,
    int listenMode = 0,
    sampleRate = 0,
    SpeechListenOptions? options,
  }) async {
    listens++;
    status(SpeechToText.listeningStatus);
    return true;
  }

  @override
  Future<void> stop() async {
    final pending = pendingStop;
    pendingStop = null;
    status(SpeechToText.notListeningStatus);
    if (pending != null) await pending.future;
  }

  @override
  Future<void> cancel() async => status(SpeechToText.notListeningStatus);
}
