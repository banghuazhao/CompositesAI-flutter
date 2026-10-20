import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/views/chat_latest_button.dart';

const _button = ValueKey('chat-jump-to-latest');

Future<_HarnessState> _mount(
  WidgetTester tester, {
  required ScrollController controller,
  bool connected = true,
  bool multiplePositions = false,
  Locale? locale,
  double scale = 1,
  bool reducedMotion = false,
  Size size = const Size(800, 700),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey<_HarnessState>();
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales:
        locale == null ? const [Locale('en')] : S.delegate.supportedLocales,
    localizationsDelegates: locale == null
        ? null
        : const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reducedMotion,
      ),
      child: child!,
    ),
    home: _Harness(
      key: key,
      controller: controller,
      connected: connected,
      multiplePositions: multiplePositions,
    ),
  ));
  await tester.pumpAndSettle();
  return key.currentState!;
}

VoidCallback _action(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(find.byKey(_button)).onPressed!;

void main() {
  late _InspectableScrollController controller;
  setUp(() => controller = _InspectableScrollController());
  tearDown(() => controller.dispose());

  testWidgets('threshold, semantics and tap return to the current bottom',
      (tester) async {
    await _mount(tester, controller: controller);
    controller.jumpTo(controller.position.maxScrollExtent - 179);
    await tester.pumpAndSettle();
    expect(find.byKey(_button), findsNothing);
    controller.jumpTo(controller.position.maxScrollExtent - 180);
    await tester.pumpAndSettle();
    expect(find.text('Jump to latest'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    try {
      final data = tester.getSemantics(find.byKey(_button)).getSemanticsData();
      expect(data.label, contains('Jump to latest'));
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      final rect = tester.getRect(find.byKey(_button));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, 0);
      expect(find.byKey(_button), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'streamed content updates the indicator without pulling the reader',
      (tester) async {
    final host = await _mount(tester, controller: controller);
    controller.jumpTo(controller.position.maxScrollExtent - 100);
    await tester.pumpAndSettle();
    expect(find.byKey(_button), findsNothing);
    final readingOffset = controller.offset;
    // Rebuild just the streamed list, without updating the overlay's widget.
    // This requires its metrics listener, rather than didUpdateWidget polling.
    host.rows += 10;
    await tester.pumpAndSettle();
    expect(controller.offset, readingOffset);
    expect(find.byKey(_button), findsOneWidget);
    for (var token = 0; token < 3; token++) {
      host.rows++;
      await tester.pumpAndSettle();
      expect(controller.offset, readingOffset);
    }
    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, controller.position.maxScrollExtent);
    expect(find.byKey(_button), findsNothing);
    final settledOffset = controller.offset;
    host.rows += 10;
    await tester.pumpAndSettle();
    expect(controller.offset, settledOffset,
        reason: 'A completed explicit jump must not follow later tokens.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a real drag cancels the pending lazy-extent correction',
      (tester) async {
    final host = await _mount(tester, controller: controller);
    host.rows += 13;
    await tester.pumpAndSettle();
    _action(tester)();
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    await gesture.moveBy(const Offset(0, 40));
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.position.extentAfter, greaterThan(80));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a chat switch cancels pending corrections before new content grows',
      (tester) async {
    final host = await _mount(tester, controller: controller);
    _action(tester)();
    final firstJumpOffset = controller.offset;
    host.update(() {
      host.conversationId = 'chat-b';
      host.loaded = false;
      host.rows += 20;
    });
    await tester.pumpAndSettle();
    expect(controller.offset, firstJumpOffset);
    expect(find.byKey(_button), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'viewport and composer resizing refresh metrics and button position',
      (tester) async {
    final host = await _mount(tester, controller: controller);
    controller.jumpTo(controller.position.maxScrollExtent - 100);
    await tester.pumpAndSettle();
    final offset = controller.offset;
    host.update(() {
      host.viewportHeight = 240;
      host.bottomOffset = 108;
    });
    await tester.pumpAndSettle();
    expect(controller.offset, offset);
    expect(find.byKey(_button), findsOneWidget);
    final viewport = tester.getRect(find.byKey(const Key('chat-viewport')));
    expect(tester.getRect(find.byKey(_button)).bottom,
        closeTo(viewport.bottom - 108, 0.01));
    host.update(() => host.bottomOffset = 148);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_button)).bottom,
        closeTo(viewport.bottom - 148, 0.01));
    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();
    expect(controller.position.extentAfter, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'conversation/session changes invalidate old actions and reset state',
      (tester) async {
    final host = await _mount(tester, controller: controller);
    final oldChatAction = _action(tester);
    host.update(() {
      host.conversationId = 'chat-b';
      host.loaded = false;
    });
    await tester.pumpAndSettle();
    expect(find.byKey(_button), findsNothing);
    oldChatAction();
    expect(controller.offset, 0);
    host.update(() {
      host.rows = 2;
      host.loaded = true;
    });
    await tester.pumpAndSettle();
    expect(find.byKey(_button), findsNothing);
    host.update(() => host.rows = 60);
    await tester.pumpAndSettle();
    final oldSessionAction = _action(tester);
    host.update(() => host.sessionToken++);
    await tester.pumpAndSettle();
    oldSessionAction();
    expect(controller.offset, 0);
    _action(tester)();
    await tester.pumpAndSettle();
    expect(controller.position.extentAfter, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new chat, logout and loading cannot expose an old indicator',
      (tester) async {
    final host = await _mount(tester, controller: controller);
    final oldAction = _action(tester);
    host.update(() => host.conversationId = null);
    await tester.pumpAndSettle();
    expect(find.byKey(_button), findsNothing);
    oldAction();
    expect(controller.offset, 0);
    host.update(() => host.conversationId = '');
    await tester.pumpAndSettle();
    expect(find.byKey(_button), findsNothing);
    host.update(() {
      host.conversationId = 'chat-a';
      host.loaded = false;
      host.sessionToken++;
    });
    await tester.pumpAndSettle();
    expect(find.byKey(_button), findsNothing);
    oldAction();
    expect(controller.offset, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no clients, detached lists and multiple positions are guarded',
      (tester) async {
    final host = await _mount(tester, controller: controller, connected: false);
    expect(controller.hasClients, isFalse);
    expect(find.byKey(_button), findsNothing);
    host.update(() => host.connected = true);
    await tester.pumpAndSettle();
    expect(find.byKey(_button), findsOneWidget);
    final oldAction = _action(tester);
    host.update(() => host.connected = false);
    await tester.pumpAndSettle();
    oldAction();
    await tester.pumpAndSettle();
    expect(controller.hasClients, isFalse);
    expect(find.byKey(_button), findsNothing);
    host.update(() {
      host.connected = true;
      host.multiplePositions = true;
    });
    await tester.pumpAndSettle();
    expect(controller.positions, hasLength(2));
    expect(find.byKey(_button), findsNothing);
    oldAction();
    await tester.pumpAndSettle();
    expect(
        controller.positions.every((position) => position.pixels == 0), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'controller replacement and disposal remove listeners and pending work',
      (tester) async {
    final replacement = _InspectableScrollController();
    addTearDown(replacement.dispose);
    final host = await _mount(tester, controller: controller);
    final oldAction = _action(tester);
    expect(controller.hasAttachedListeners, isTrue);
    host.update(() => host.controller = replacement);
    await tester.pumpAndSettle();
    expect(controller.hasAttachedListeners, isFalse);
    expect(replacement.hasAttachedListeners, isTrue);
    oldAction();
    expect(replacement.offset, 0);
    final disposedAction = _action(tester);
    replacement.jumpTo(40); // Leave a post-frame refresh queued.
    await tester.pumpWidget(const SizedBox.shrink());
    disposedAction();
    await tester.pumpAndSettle();
    expect(replacement.hasAttachedListeners, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('covered routes cannot use a retained button action',
      (tester) async {
    await _mount(tester, controller: controller);
    final oldAction = _action(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Another page'))));
    await tester.pumpAndSettle();
    oldAction();
    expect(controller.offset, 0);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_button), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets('$locale is accessible at narrow 2x with reduced motion',
        (tester) async {
      await _mount(tester,
          controller: controller,
          locale: locale,
          scale: 2,
          reducedMotion: true,
          size: const Size(320, 640));
      final strings = S.of(tester.element(find.byType(ChatLatestOverlay)));
      expect(find.text(strings.Chat_jump_to_latest), findsOneWidget);
      final rect = tester.getRect(find.byKey(_button));
      expect(rect.left, greaterThanOrEqualTo(16));
      expect(rect.right, lessThanOrEqualTo(304));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(find.byKey(_button).hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, 0);
      expect(find.byKey(_button), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

class _InspectableScrollController extends ScrollController {
  bool get hasAttachedListeners => hasListeners;
}

class _Harness extends StatefulWidget {
  const _Harness({
    super.key,
    required this.controller,
    required this.connected,
    required this.multiplePositions,
  });

  final ScrollController controller;
  final bool connected;
  final bool multiplePositions;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late ScrollController controller = widget.controller;
  late bool connected = widget.connected;
  late bool multiplePositions = widget.multiplePositions;
  String? conversationId = 'chat-a';
  int sessionToken = 0;
  bool loaded = true;
  final _rows = ValueNotifier<int>(60);
  int get rows => _rows.value;
  set rows(int value) => _rows.value = value;
  double viewportHeight = 400;
  double bottomOffset = 92;

  void update(VoidCallback change) => setState(change);

  Widget list(String key) => ValueListenableBuilder<int>(
        valueListenable: _rows,
        builder: (_, count, __) => ListView.builder(
          key: ValueKey(key),
          controller: controller,
          itemCount: count,
          itemExtent: 40,
          itemBuilder: (_, index) => Text('Message $index'),
        ),
      );

  @override
  void dispose() {
    _rows.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SizedBox(
          key: const Key('chat-viewport'),
          height: viewportHeight,
          child: ChatLatestOverlay(
            scrollController: controller,
            conversationId: conversationId,
            sessionToken: sessionToken,
            isConversationLoaded: loaded,
            bottomOffset: bottomOffset,
            child: !connected
                ? const SizedBox.shrink()
                : multiplePositions
                    ? Row(children: [
                        Expanded(child: list('first-list')),
                        Expanded(child: list('second-list')),
                      ])
                    : list('single-list'),
          ),
        ),
      );
}
