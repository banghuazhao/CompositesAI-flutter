import 'dart:convert';
import 'dart:typed_data';

import 'package:domain/chat/entities/chat_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/views/pending_image_attachment.dart';

const _file = ChatFile(id: 'image', name: 'laminate.png', url: '');
const _preview = ValueKey('pending-image-preview-content');
const _dialog = ValueKey('pending-image-preview-dialog');
const _close = ValueKey('pending-image-preview-close');
const _remove = ValueKey('pending-image-remove-image');
const _unavailable = ValueKey('pending-image-preview-unavailable');

// A small, valid16×12 PNG keeps these interaction tests independent of files,
// the network, platform plugins and large decoded image allocations.
Uint8List _png() => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAYAAABr5z2BAAAAF0lEQVR4nGOQy7vznxLMMGrAqAHDwwAAtT/NUHJVE2MAAAAASUVORK5CYII=');

class _Availability extends ChangeNotifier {
  bool available = true;
  bool get observing => hasListeners;

  void invalidate() {
    available = false;
    notifyListeners();
  }
}

Widget _app(Widget child,
        {GlobalKey<NavigatorState>? navigatorKey,
        Locale locale = const Locale('en'),
        double scale = 1}) =>
    MaterialApp(
      navigatorKey: navigatorKey,
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
          child: child!),
      home: Scaffold(
        appBar: AppBar(title: const Text('Composer host')),
        body: Center(child: child),
      ),
    );

Future<void> _pump(WidgetTester tester, Widget child,
    {GlobalKey<NavigatorState>? navigatorKey,
    Size size = const Size(600, 800),
    Locale locale = const Locale('en'),
    double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      _app(child, navigatorKey: navigatorKey, locale: locale, scale: scale));
  await tester.pumpAndSettle();
  await _settleImages(tester);
}

Future<void> _settleImages(WidgetTester tester) async {
  bool ready() => tester
      .widgetList<RawImage>(find.byType(RawImage))
      .every((image) => image.image != null);

  // Browser decoding needs real event-loop turns, followed by widget frames.
  // Do not await a completer that the widget's fake-async zone already owns.
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    if (ready()) {
      await tester.pumpAndSettle();
      return;
    }
  }
  await tester.pumpAndSettle();
  expect(ready(), isTrue,
      reason:
          'Images must decode or show their error fallback within 1 second.');
}

Finder _previewTarget() => find.byWidgetPredicate((widget) =>
    widget is InkWell &&
    widget.key == const ValueKey('pending-image-preview-image'));

Future<void> _open(WidgetTester tester) async {
  await tester.tap(_previewTarget());
  await tester.pumpAndSettle();
  await _settleImages(tester);
  expect(find.byKey(_dialog), findsOneWidget);
}

Future<void> _closePreview(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_close));
  await tester.tap(find.byKey(_close));
  await tester.pumpAndSettle();
  expect(find.byKey(_dialog), findsNothing);
}

void main() {
  testWidgets('preview and removal have separate labeled48px touch targets',
      (tester) async {
    var removed = 0;
    await _pump(
        tester,
        PendingImageAttachment(
            file: _file, bytes: _png(), onRemove: () => removed++));
    final preview = _previewTarget();
    final remove = find.byKey(_remove);
    expect(tester.getSize(preview), const Size(80, 80));
    expect(tester.getSize(remove), const Size(48, 48));
    expect(tester.widget<IconButton>(remove).tooltip, 'Remove laminate.png');
    expect(find.byTooltip('Preview laminate.png'), findsOneWidget);
    await _open(tester); // A centered preview tap must not hit Remove.
    expect(removed, 0);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text(_file.name), findsOneWidget);
    await _closePreview(tester);
    expect(find.text('Composer host'), findsOneWidget);
    expect(removed, 0);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(removed, 1);
    expect(find.byKey(_dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview bounds decode size and owns a separate byte snapshot',
      (tester) async {
    final bytes = _png();
    await _pump(tester, PendingImageAttachment(file: _file, bytes: bytes));
    await _open(tester);
    final image = tester.widget<Image>(find.byKey(_preview));
    final resize = image.image as ResizeImage;
    expect(resize.width, 2048);
    expect(resize.height, 2048);
    expect(resize.policy, ResizeImagePolicy.fit);
    expect(resize.allowUpscaling, isFalse);
    final decoded = tester
        .widget<RawImage>(find.descendant(
            of: find.byKey(_preview), matching: find.byType(RawImage)))
        .image!;
    expect(decoded.width, 16);
    expect(decoded.height, 12);
    final snapshot = (resize.imageProvider as MemoryImage).bytes;
    expect(snapshot, orderedEquals(bytes));
    expect(identical(snapshot, bytes), isFalse);
    final first = snapshot.first;
    bytes[0] = 0;
    expect(snapshot.first, first);
    await _closePreview(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview and remove actions expose their accessible labels',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pump(tester,
          PendingImageAttachment(file: _file, bytes: _png(), onRemove: () {}));
      expect(tester.getSemantics(_previewTarget()).label,
          contains('Preview laminate.png'));
      final removal =
          tester.getSemantics(find.byKey(_remove)).getSemanticsData();
      expect('${removal.label} ${removal.tooltip}',
          contains('Remove laminate.png'));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('preview supports pinch zoom without sending or removing',
      (tester) async {
    var removed = 0;
    await _pump(
        tester,
        PendingImageAttachment(
            file: _file, bytes: _png(), onRemove: () => removed++));
    await _open(tester);
    final viewer = find.byType(InteractiveViewer);
    final center = tester.getCenter(viewer);
    final left = await tester.createGesture(pointer: 1);
    final right = await tester.createGesture(pointer: 2);
    await left.down(center - const Offset(20, 0));
    await right.down(center + const Offset(20, 0));
    await tester.pump();
    await left.moveTo(center - const Offset(60, 0));
    await right.moveTo(center + const Offset(60, 0));
    await tester.pump();
    await left.up();
    await right.up();
    await tester.pumpAndSettle();
    final transform = tester.widget<Transform>(
        find.descendant(of: viewer, matching: find.byType(Transform)).first);
    expect(transform.transform.getMaxScaleOnAxis(), greaterThan(1));
    expect(removed, 0);
    await _closePreview(tester);
    expect(tester.takeException(), isNull);
  });

  for (final bytes in [
    null,
    Uint8List.fromList([1, 2, 3, 4])
  ]) {
    testWidgets(
        '${bytes == null ? 'missing' : 'corrupt'} bytes show safe fallback',
        (tester) async {
      await _pump(tester, PendingImageAttachment(file: _file, bytes: bytes));
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      await _open(tester);
      final strings = S.of(tester.element(find.byKey(_dialog)));
      expect(find.text(strings.Chat_image_preview_unavailable), findsOneWidget);
      expect(find.byKey(_unavailable), findsOneWidget);
      await _closePreview(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('null removal callback keeps preview available while sending',
      (tester) async {
    await _pump(tester, PendingImageAttachment(file: _file, bytes: _png()));
    expect(find.byKey(_remove), findsNothing);
    await _open(tester);
    await _closePreview(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid taps open once and stale Close cannot pop a newer preview',
      (tester) async {
    await _pump(tester, PendingImageAttachment(file: _file, bytes: _png()));
    final open = tester.widget<InkWell>(_previewTarget()).onTap!;
    open();
    open();
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsOneWidget);
    final staleClose = tester.widget<TextButton>(find.byKey(_close)).onPressed!;
    await _closePreview(tester);
    await _open(tester);
    staleClose();
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsOneWidget);
    await _closePreview(tester);
    expect(find.text('Composer host'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('session invalidation closes only its covered preview route',
      (tester) async {
    final availability = _Availability();
    addTearDown(availability.dispose);
    final navigator = GlobalKey<NavigatorState>();
    await _pump(
        tester,
        PendingImageAttachment(
          file: _file,
          bytes: _png(),
          sessionListenable: availability,
          isAvailable: () => availability.available,
        ),
        navigatorKey: navigator);
    expect(availability.observing, isFalse);
    await _open(tester);
    expect(availability.observing, isTrue);
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('New route'))));
    await tester.pumpAndSettle();
    availability.invalidate();
    await tester.pumpAndSettle();
    expect(find.text('New route'), findsOneWidget);
    expect(availability.observing, isFalse);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    expect(find.text('Composer host'), findsOneWidget);
    await tester.tap(_previewTarget());
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a covered preview Close cannot pop the newer route',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await _pump(tester, PendingImageAttachment(file: _file, bytes: _png()),
        navigatorKey: navigator);
    await _open(tester);
    final close = tester.widget<TextButton>(find.byKey(_close)).onPressed!;
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('New route'))));
    await tester.pumpAndSettle();
    close();
    await tester.pumpAndSettle();
    expect(find.text('New route'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    expect(find.text('Composer host'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a replacement predicate cannot transfer an old session preview',
      (tester) async {
    final availability = _Availability();
    addTearDown(availability.dispose);
    final bytes = _png();
    var originalSession = true;
    final rebuild = ValueNotifier(false);
    addTearDown(rebuild.dispose);
    await _pump(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: rebuild,
          builder: (_, newSession, __) => PendingImageAttachment(
            file: _file,
            bytes: bytes,
            sessionListenable: availability,
            isAvailable: newSession ? () => true : () => originalSession,
          ),
        ));
    await _open(tester);
    originalSession = false;
    rebuild.value = true;
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    expect(availability.observing, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attachment removal during a build closes and detaches safely',
      (tester) async {
    final availability = _Availability();
    addTearDown(availability.dispose);
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    await _pump(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, show, __) => show
              ? PendingImageAttachment(
                  file: _file,
                  bytes: _png(),
                  sessionListenable: availability,
                  isAvailable: () => availability.available,
                )
              : const Text('Attachment removed'),
        ));
    await _open(tester);
    visible.value = false;
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    expect(find.text('Attachment removed'), findsOneWidget);
    expect(availability.observing, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final (size, locale) in [
    (const Size(320, 700), const Locale('zh', 'HK')),
    (const Size(700, 320), const Locale('en')),
  ]) {
    testWidgets('$locale preview fits$size at2x text', (tester) async {
      final file = ChatFile(
          id: _file.id,
          name: '${List.filled(12, 'laminate-surface-').join()}.png',
          url: '');
      await _pump(tester,
          PendingImageAttachment(file: file, bytes: null, onRemove: () {}),
          size: size, locale: locale, scale: 2);
      final strings = S.of(tester.element(_previewTarget()));
      expect(tester.widget<IconButton>(find.byKey(_remove)).tooltip,
          strings.Chat_remove_attachment(file.name));
      await _open(tester);
      expect(find.text(strings.Chat_image_preview), findsOneWidget);
      expect(find.text(strings.Chat_image_preview_unavailable), findsOneWidget);
      await _closePreview(tester);
      expect(find.text('Composer host'), findsOneWidget);
      // Do not consume framework errors, so any layout failure shows its source.
    });
  }
}
