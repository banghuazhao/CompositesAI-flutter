import 'dart:convert';
import 'dart:io' show Platform, ZLibEncoder;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/main.dart' as app;
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/tool_page.dart';

const _size = Size(1280, 800);
const _languages = <(String, Locale, Locale)>[
  ('en', Locale('en'), Locale('en')),
  (
    'zh-Hans',
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale('zh'),
  ),
  (
    'zh-Hant',
    Locale.fromSubtags(
        languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
    Locale('zh', 'HK'),
  ),
];

// This target uses real production routes and calculations. No credentials,
// account messages, fake replies, widget replicas or on-device files are used.
// Run it with macos_screenshot_driver.dart, which receives only rendered PNGs.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Capture production Mac store screenshots in three UI languages',
      (tester) async {
    if (kIsWeb ||
        !Platform.isMacOS ||
        defaultTargetPlatform != TargetPlatform.macOS) {
      throw StateError('Run the screenshot target on native macOS.');
    }
    final screenshots = <Map<String, Object>>[];
    binding.reportData = {'schemaVersion': 1, 'screenshots': screenshots};
    UnitSettings? unitSettings;
    UnitSystem? originalSystem;
    try {
      await sl.reset();
      // IntegrationTest's surface override changes render constraints, while
      // MediaQuery.fromView still reads the native view's metrics. Keep both
      // sources aligned so the production layouts use the capture viewport.
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = _size;
      await binding.setSurfaceSize(_size);
      binding.platformDispatcher.localesTestValue = [const Locale('en')];
      binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      app.main();
      await _waitFor(
          tester,
          () => find.byType(ChatScreen).evaluate().isNotEmpty,
          'The production Mac app did not launch.');
      final model =
          tester.element(find.byType(ChatScreen)).read<ChatViewModel>();
      // Settle the real initial auth check before any render data is captured.
      await model.fetchAuthSessionNew();
      await tester.pumpAndSettle();
      _requireGuest(model);
      final context = tester.element(find.byType(ChatScreen));
      unitSettings = context.read<UnitSettings>();
      originalSystem = unitSettings.system;
      await unitSettings.setSystem(UnitSystem.si);
      for (final asset in [
        'images/app_icon.png',
        'images/lamina.png',
        'images/laminate.png',
        'images/square_pack.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }

      for (final language in _languages) {
        _requireGuest(model);
        binding.platformDispatcher.localesTestValue = [language.$2];
        await tester.pumpAndSettle();
        final chatContext = tester.element(find.byType(ChatScreen));
        if (Localizations.localeOf(chatContext) != language.$3) {
          throw StateError('The requested production UI locale did not load.');
        }
        final strings = S.of(chatContext);
        expect(find.text(strings.Chat_sign_in_to_chat), findsOneWidget);
        screenshots.add(await _capture(
            tester, model, find.byType(ChatScreen), language.$1, '01-guest'));

        await _tap(tester, find.byTooltip(strings.Chat_composite_calculators));
        expect(find.byType(ToolPage), findsOneWidget);
        expect(find.text(strings.Laminate_plate_properties), findsOneWidget);
        screenshots.add(await _capture(
            tester, model, find.byType(ToolPage), language.$1, '02-tools'));

        await _tap(tester, find.text(strings.Laminate_plate_properties));
        expect(find.byType(LaminatePlatePropertiesPage), findsOneWidget);
        // Public engineering inputs, calculated by the existing production
        // calculator. Do not open or capture the user's custom-material library.
        for (final input in <(String, String)>[
          ('E1 (GPa)', '181'),
          ('E2 (GPa)', '10.3'),
          ('G12 (GPa)', '7.17'),
          ('ν12', '0.28'),
          ('${strings.Calculator_thickness} (mm)', '0.125'),
          ('[xx/xx/xx/xx]msn', '[0/45/-45/90]s'),
        ]) {
          await _type(tester, _field(input.$1), input.$2);
        }
        await _tap(tester, find.text(strings.Calculate));
        expect(find.byType(LaminatePlatePropertiesResultPage), findsOneWidget);
        screenshots.add(await _capture(
            tester,
            model,
            find.byType(LaminatePlatePropertiesResultPage),
            language.$1,
            '03-plate-results'));
        await _back(tester);
        await _back(tester);
        await _back(tester);
        expect(find.byType(ChatScreen), findsOneWidget);
      }
      expect(screenshots, hasLength(9));
    } finally {
      if (unitSettings != null && originalSystem != null) {
        await unitSettings.setSystem(originalSystem);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await sl.reset();
      binding.platformDispatcher.clearLocalesTestValue();
      binding.platformDispatcher.clearPlatformBrightnessTestValue();
      await binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

void _requireGuest(ChatViewModel model) {
  if (model.isDisposed ||
      model.isLoggedIn ||
      model.user != null ||
      model.selectedChat != null ||
      model.messages.isNotEmpty) {
    throw StateError('Screenshot capture requires a signed-out test profile.');
  }
}

Future<Map<String, Object>> _capture(WidgetTester tester, ChatViewModel model,
    Finder route, String language, String name) async {
  _requireGuest(model);
  FocusManager.instance.primaryFocus?.unfocus();
  Tooltip.dismissAllToolTips();
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 200));
  if (tester.takeException() != null) {
    throw StateError('A framework error prevents screenshot capture.');
  }
  final element = tester.element(route);
  final routeCurrent = ModalRoute.of(element)?.isCurrent;
  final viewport = MediaQuery.sizeOf(element);
  if (routeCurrent != true || viewport != _size) {
    throw StateError('The screenshot route is not current or correctly sized '
        '(current: $routeCurrent, viewport: $viewport, '
        'physical: ${tester.view.physicalSize}, '
        'pixel ratio: ${tester.view.devicePixelRatio}).');
  }

  // ModalRoute supplies a full-page repaint boundary. Capture its local layer,
  // excluding the RenderView's device-pixel transform and native window chrome.
  RenderObject? object = tester.renderObject(route);
  RenderRepaintBoundary? boundary;
  while (object != null && object is! RenderView) {
    if (object is RenderRepaintBoundary && object.size == _size) {
      boundary = object;
      break;
    }
    object = object.parent;
  }
  final layer = boundary?.debugLayer;
  if (layer is! OffsetLayer || boundary!.debugNeedsPaint) {
    throw StateError('A painted full-page capture layer was unavailable.');
  }
  final image = await layer.toImage(Offset.zero & _size, pixelRatio: 1);
  try {
    if (image.width != 1280 || image.height != 800) {
      throw StateError('The rendered screenshot dimensions were incorrect.');
    }
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rgba == null) throw StateError('The rendered image had no pixel data.');
    final png = _opaquePng(
        rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
        image.width,
        image.height);
    _requireGuest(model);
    return {
      'language': language,
      'name': name,
      'width': image.width,
      'height': image.height,
      'pngBase64': base64Encode(png),
    };
  } finally {
    image.dispose();
  }
}

// Serialize the original opaque render pixels as RGB PNG (color type 2).
// No resizing, alpha flattening, overlays or changes to RGB values take place.
Uint8List _opaquePng(Uint8List rgba, int width, int height) {
  if (rgba.length != width * height * 4) {
    throw StateError('The rendered pixel buffer had an unexpected size.');
  }
  final rows = Uint8List(height * (width * 3 + 1));
  var source = 0;
  var destination = 0;
  for (var y = 0; y < height; y++) {
    rows[destination++] = 0; // PNG filter: None.
    for (var x = 0; x < width; x++) {
      if (rgba[source + 3] != 255) {
        throw StateError('The production screenshot has transparent pixels.');
      }
      rows[destination++] = rgba[source++];
      rows[destination++] = rgba[source++];
      rows[destination++] = rgba[source++];
      source++;
    }
  }
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 2); // RGB, no alpha channel.
  return (BytesBuilder(copy: false)
        ..add(const [137, 80, 78, 71, 13, 10, 26, 10])
        ..add(_chunk('IHDR', header.buffer.asUint8List()))
        ..add(_chunk('IDAT', ZLibEncoder().convert(rows)))
        ..add(_chunk('IEND', const [])))
      .takeBytes();
}

Uint8List _chunk(String name, List<int> data) {
  final body = Uint8List.fromList([...ascii.encode(name), ...data]);
  var crc = 0xffffffff;
  for (final byte in body) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  final length = ByteData(4)..setUint32(0, data.length);
  final checksum = ByteData(4)..setUint32(0, crc ^ 0xffffffff);
  return (BytesBuilder(copy: false)
        ..add(length.buffer.asUint8List())
        ..add(body)
        ..add(checksum.buffer.asUint8List()))
      .takeBytes();
}

Finder _field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label);

Future<void> _waitFor(
    WidgetTester tester, bool Function() ready, String failure) async {
  final watch = Stopwatch()..start();
  while (!ready() && watch.elapsed < const Duration(seconds: 45)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (!ready()) throw StateError(failure);
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pump();
  if (finder.evaluate().length != 1) {
    throw StateError('The expected production screenshot control was missing.');
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _show(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, Finder finder, String text) async {
  await _show(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pump();
  final editable = tester.widget<EditableText>(
      find.descendant(of: finder, matching: find.byType(EditableText)));
  if (editable.controller.text != text) {
    throw StateError('The production calculator did not retain its input.');
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}
