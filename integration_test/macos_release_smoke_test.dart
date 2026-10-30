import 'dart:convert';
import 'dart:io';

import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/main.dart' as app;
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/presentation/settings/views/result_precision_page.dart';
import 'package:swiftcomp/presentation/settings/views/settings_page.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/tool_page.dart';
import 'package:swiftcomp/presentation/tools/widget/unit_system_picker.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

// Run on a signed-out Mac test profile. This uses the real app entry point,
// native text input, preferences and clipboard, with no mocked platform channels.
// The optional QA flow reads only an explicitly supplied local JSON file at
// runtime. No credentials, tokens, server responses or message history are logged.
const _reviewerCredentialsPath =
    String.fromEnvironment('COMPOSITESAI_REVIEWER_CREDENTIALS_PATH');
const _reviewerRuntimeQA = bool.fromEnvironment('COMPOSITESAI_REVIEWER_QA');
const _composer = ValueKey('chat-composer');
const _email = ValueKey('login_email');
const _password = ValueKey('login_password');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Mac guest launch, resizing, keyboard and calculator smoke',
      (tester) async {
    UnitSettings? units;
    UnitSystem? originalUnits;
    NumberPrecisionHelper? precision;
    int? originalPrecision;
    try {
      final model = await _startApp(tester, binding);
      _requireGuest(model);
      final context = tester.element(find.byType(ChatScreen));
      final strings = S.of(context);
      units = context.read<UnitSettings>();
      originalUnits = units.system;
      precision = context.read<NumberPrecisionHelper>();
      originalPrecision = precision.precision;

      // Resize the rendered app viewport. Cocoa window manipulation is left to
      // the native runner; the production responsive layouts receive each size.
      for (final size in [
        const Size(1200, 800),
        const Size(720, 640),
        const Size(640, 560),
      ]) {
        await binding.setSurfaceSize(size);
        await tester.pumpAndSettle();
        expect(find.text(strings.Chat_sign_in_to_chat), findsOneWidget);
        expect(
            find.byTooltip(strings.Chat_composite_calculators), findsOneWidget);
        _noFrameworkError(tester);
      }

      await _tap(tester, find.text(strings.Chat_sign_in_to_chat));
      await _waitFor(tester, () => find.byKey(_email).evaluate().isNotEmpty,
          'The Mac sign-in form did not open.');
      await tester.tap(find.byKey(_email));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_email), 'mac-smoke@example.invalid');
      await tester.pumpAndSettle();
      expect(_editableFocus(tester, find.byKey(_email)).hasFocus, isTrue);
      await _macTab(tester);
      expect(_editableFocus(tester, find.byKey(_password)).hasFocus, isTrue);
      await _macTab(tester, backwards: true);
      expect(_editableFocus(tester, find.byKey(_email)).hasFocus, isTrue);
      // Never submit the demonstration address or make an auth request here.
      await _back(tester);
      _requireGuest(model);

      await binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip(strings.Chat_composite_calculators));
      expect(find.byType(ToolPage), findsOneWidget);

      for (final system in UnitSystem.values) {
        await _tap(tester, find.byType(UnitSystemButton));
        await _tap(
            tester,
            find.byWidgetPredicate((widget) =>
                widget is RadioListTile<UnitSystem> && widget.value == system));
        await _back(tester);
        final selectedUnits = Units.of(system);
        expect(units.system, system);
        await _tap(tester, find.text(strings.Laminate_plate_properties));
        expect(find.byType(LaminatePlatePropertiesPage), findsOneWidget);
        await _tap(tester, find.text(strings.Calculator_library));
        await _tap(tester, find.text('T300/5208 carbon/epoxy'));
        await _typePublic(
            tester,
            _field('${strings.Calculator_thickness} (${selectedUnits.length})'),
            selectedUnits.lengthFromMm(.125).toString());
        final layup = _field('[xx/xx/xx/xx]msn');
        if (system == UnitSystem.si) {
          await _typePublic(tester, layup, '[0/90]1000001');
          await _tap(tester, find.text(strings.Calculate));
          expect(find.byType(LaminatePlatePropertiesResultPage), findsNothing);
          await _show(tester, layup);
          expect(find.text(strings.Calculator_too_many_layers), findsOneWidget);
        }
        await _typePublic(tester, layup, '[0/90]s');
        await _show(tester, find.byKey(const ValueKey('layup-ply-count')));
        expect(find.text(strings.Calculator_ply_count(4)), findsOneWidget);
        await _tap(tester, find.text(strings.Calculate));
        expect(find.byType(LaminatePlatePropertiesResultPage), findsOneWidget);
        await binding.setSurfaceSize(const Size(720, 640));
        await tester.pumpAndSettle();
        _noFrameworkError(tester);
        await _tap(tester, find.byTooltip(strings.Calculator_export_results));
        await _tap(tester, find.text(strings.Calculator_copy_results));
        await _waitFor(
            tester,
            () => find
                .text(strings.Calculator_results_copied)
                .evaluate()
                .isNotEmpty,
            'The calculator did not confirm its native clipboard copy.');
        final copied = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
        expect(copied, isNotNull);
        expect(copied, startsWith('${strings.Laminate_plate_properties}\r\n'));
        expect(copied, contains('Units\t${selectedUnits.name}'));
        expect(copied, contains('Layup sequence\t[0/90]s'));
        expect(copied, contains('Result: A Matrix'));
        expect(copied, contains(selectedUnits.aMatrix));
        expect(copied, isNot(contains('NaN')));
        expect(copied, isNot(contains('Infinity')));
        _noFrameworkError(tester);
        await _back(tester);
        expect(_editableText(tester, layup), '[0/90]s');
        await _back(tester);
        await binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpAndSettle();
      }
      await _back(tester);
      _requireGuest(model);

      // Guests reach calculators directly. Open the existing settings route
      // explicitly to verify Mac package information and preference controls too.
      Navigator.of(tester.element(find.byType(ChatScreen)))
          .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Account & Settings'), findsOneWidget);
      final settings =
          tester.element(find.byType(SettingsPage)).read<SettingsViewModel>();
      await _waitFor(tester, () => settings.version.isNotEmpty,
          'The Mac package information was unavailable.');
      expect(settings.version, matches(RegExp(r'^\d+\.\d+(\.\d+)?$')));
      await _tap(tester, find.text('Result Precision'));
      expect(find.byType(ResultPrecisionPage), findsOneWidget);
      final changedPrecision = originalPrecision == 9
          ? originalPrecision - 1
          : originalPrecision + 1;
      await _tap(tester,
          find.byIcon(originalPrecision == 9 ? Icons.remove : Icons.add));
      expect(precision.precision, changedPrecision);
      _noFrameworkError(tester);
      await _back(tester);
      await _back(tester);
      _requireGuest(model);
    } finally {
      // Restore preferences while their production provider owners are mounted.
      if (units != null && originalUnits != null) {
        await units.setSystem(originalUnits);
      }
      if (precision != null && originalPrecision != null) {
        await precision.set(originalPrecision);
      }
      await _finishApp(tester, binding);
    }
  }, skip: _reviewerRuntimeQA, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('Mac optional QA sign-in and unsent expanded draft smoke',
      (tester) async {
    bool attemptedSignIn = false;
    ChatViewModel? model;
    try {
      model = await _startApp(tester, binding);
      _requireGuest(model);
      var storedSession = true;
      try {
        storedSession = await sl<AuthUseCase>().isLoggedIn();
      } catch (_) {
        // Never expose secure-storage diagnostics or change an existing token.
        throw StateError(
            'The QA smoke could not verify signed-out local storage.');
      }
      if (storedSession) {
        throw StateError('Use a signed-out Mac test profile for the QA smoke.');
      }
      final credentials = await _ReviewerCredentials.load();
      final strings = S.of(tester.element(find.byType(ChatScreen)));
      await _tap(tester, find.text(strings.Chat_sign_in_to_chat));
      await _waitFor(tester, () => find.byKey(_email).evaluate().isNotEmpty,
          'The QA sign-in form did not open.');
      await _typePrivate(tester, find.byKey(_email), credentials.email);
      await _typePrivate(tester, find.byKey(_password), credentials.password);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      final submit = find.byKey(const ValueKey('login_submit'));
      if (tester.widget<ElevatedButton>(submit).onPressed == null) {
        throw StateError('The QA sign-in form did not accept its input.');
      }
      attemptedSignIn = true;
      await tester.tap(submit);
      await tester.pump();
      await _waitFor(
          tester,
          () =>
              model!.isLoggedIn && find.byKey(_composer).evaluate().isNotEmpty,
          'The QA account did not reach the signed-in chat screen.',
          timeout: const Duration(seconds: 90));
      await tester.pumpAndSettle();
      if (model.selectedChat != null) {
        throw StateError('The QA smoke expects the new-chat draft slot.');
      }
      const draft = 'How does fiber orientation affect laminate stiffness?\n'
          'This Mac release check is an unsent draft.';
      await _typePublic(tester, find.byKey(_composer), draft);
      await _tap(tester, find.byKey(const Key('chat-composer-more')));
      await _tap(tester, find.byKey(const Key('chat-expand-composer')));
      expect(find.byKey(const Key('chat-expanded-composer-dialog')),
          findsOneWidget);
      expect(
          _editableText(
              tester, find.byKey(const Key('chat-expanded-composer'))),
          draft);
      await binding.setSurfaceSize(const Size(720, 640));
      await tester.pumpAndSettle();
      _noFrameworkError(tester);
      await _tap(tester, find.byKey(const Key('chat-expanded-composer-done')));
      expect(model.composerTextController.text, draft);
      expect(model.selectedChat, isNull);
      expect(model.isSendingMessage, isFalse);
      await _tap(tester, find.byTooltip(strings.Chat_account_settings));
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Result Precision'), findsOneWidget);
      _noFrameworkError(tester);
      // No AI send or server history mutation occurs in this target.
    } finally {
      if (attemptedSignIn && sl.isRegistered<AuthUseCase>()) {
        try {
          await sl<AuthUseCase>().logout();
          if (model != null && !model.isDisposed) {
            await model.clearChatStateOnLogout();
          }
        } catch (_) {
          // Never include server errors or account details in test output.
          throw StateError('The QA session could not be signed out cleanly.');
        } finally {
          await _finishApp(tester, binding);
        }
      } else {
        await _finishApp(tester, binding);
      }
    }
  },
      skip: _reviewerCredentialsPath.isEmpty && !_reviewerRuntimeQA,
      timeout: const Timeout(Duration(minutes: 3)));
}

Future<ChatViewModel> _startApp(
    WidgetTester tester, IntegrationTestWidgetsFlutterBinding binding) async {
  if (kIsWeb ||
      !Platform.isMacOS ||
      defaultTargetPlatform != TargetPlatform.macOS) {
    throw StateError('Run this smoke target on native macOS.');
  }
  await sl.reset();
  await binding.setSurfaceSize(const Size(1200, 800));
  app.main();
  await _waitFor(tester, () => find.byType(ChatScreen).evaluate().isNotEmpty,
      'The Mac app did not launch.',
      timeout: const Duration(seconds: 45));
  final model = tester.element(find.byType(ChatScreen)).read<ChatViewModel>();
  await model.fetchAuthSessionNew();
  await tester.pumpAndSettle();
  return model;
}

void _requireGuest(ChatViewModel model) {
  if (model.isLoggedIn) {
    throw StateError(
        'Use a signed-out Mac test profile for this smoke target.');
  }
}

Future<void> _finishApp(
    WidgetTester tester, IntegrationTestWidgetsFlutterBinding binding) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await sl.reset();
  await binding.setSurfaceSize(null);
}

Future<void> _waitFor(
    WidgetTester tester, bool Function() ready, String failureMessage,
    {Duration timeout = const Duration(seconds: 15)}) async {
  final watch = Stopwatch()..start();
  while (!ready() && watch.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (!ready()) throw StateError(failureMessage);
}

void _noFrameworkError(WidgetTester tester) {
  if (tester.takeException() != null) {
    throw StateError('The Mac smoke encountered a framework or layout error.');
  }
}

Finder _field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label);

String _editableText(WidgetTester tester, Finder finder) => tester
    .widget<EditableText>(
        find.descendant(of: finder, matching: find.byType(EditableText)))
    .controller
    .text;

FocusNode _editableFocus(WidgetTester tester, Finder finder) => tester
    .widget<EditableText>(
        find.descendant(of: finder, matching: find.byType(EditableText)))
    .focusNode;

Future<void> _show(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pump();
  if (finder.evaluate().length != 1) {
    throw StateError('An expected Mac smoke control was unavailable.');
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _show(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _typePublic(
    WidgetTester tester, Finder finder, String text) async {
  await _show(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pump();
  expect(_editableText(tester, finder), text);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _typePrivate(
    WidgetTester tester, Finder finder, String text) async {
  try {
    await _show(tester, finder);
    await tester.tap(finder);
    await tester.pump();
    await tester.enterText(finder, text);
    await tester.pump();
  } catch (_) {
    throw StateError('The QA sign-in form could not be filled.');
  }
}

Future<void> _back(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> _macTab(WidgetTester tester, {bool backwards = false}) async {
  // macOS defers text-field Tab handling to AppKit. Synthetic key events do not
  // pass through NSTextInputContext, and the integration binding deliberately
  // leaves Flutter's mock IME unregistered. Deliver the same selector callback
  // AppKit returns instead of assigning focus or changing production shortcuts.
  if (backwards) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  try {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    final reply =
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall('TextInputClient.performSelectors', <Object>[
          // Flutter's debug test client ID, also used by TestTextInput.enterText.
          -1,
          [backwards ? 'insertBacktab:' : 'insertTab:'],
        ]),
      ),
      null,
    );
    if (reply == null) {
      throw StateError('The Mac text-input selector was not handled.');
    }
    SystemChannels.textInput.codec.decodeEnvelope(reply);
  } finally {
    if (backwards) {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    }
  }
  await tester.pumpAndSettle();
}

class _ReviewerCredentials {
  const _ReviewerCredentials(this.email, this.password);

  final String email;
  final String password;

  static Future<_ReviewerCredentials> load() async {
    try {
      if (_reviewerRuntimeQA) {
        // Supply these only when launching an already-built test application.
        // They must never be present in build inputs, defines or app assets.
        final email = Platform.environment['COMPOSITESAI_QA_EMAIL'];
        final password = Platform.environment['COMPOSITESAI_QA_PASSWORD'];
        if (email == null ||
            email.trim().isEmpty ||
            password == null ||
            password.isEmpty) {
          throw const FormatException();
        }
        return _ReviewerCredentials(email, password);
      }
      String source;
      try {
        source = await File(_reviewerCredentialsPath).readAsString();
      } on FileSystemException {
        // A sandboxed Mac cannot read an arbitrary host path. Use its normal
        // user-selected file permission instead of weakening the sandbox or
        // embedding review credentials into the app bundle/build arguments.
        final selection = await FilePicker.pickFiles(
          dialogTitle: 'Select the approved local QA configuration',
          initialDirectory: File(_reviewerCredentialsPath).parent.path,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        final selected = selection?.files.single.path;
        if (selected != _reviewerCredentialsPath) {
          throw const FormatException();
        }
        source = await File(selected!).readAsString();
      }
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic>) throw const FormatException();
      final email = value['email'];
      final password = value['password'];
      if (email is! String ||
          email.trim().isEmpty ||
          password is! String ||
          password.isEmpty) {
        throw const FormatException();
      }
      return _ReviewerCredentials(email, password);
    } catch (_) {
      // FormatException may contain source text; never propagate it or print it.
      throw StateError('The local QA credentials file could not be loaded.');
    }
  }
}
