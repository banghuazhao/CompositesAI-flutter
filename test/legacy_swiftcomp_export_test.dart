import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/app/services/legacy_swiftcomp_data.dart';
import 'package:swiftcomp/presentation/settings/views/legacy_swiftcomp_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('compositesai/legacy-swiftcomp');
  final calls = <String>[];
  Future<Object?> Function(MethodCall)? handler;

  setUp(() {
    calls.clear();
    handler = (call) async => true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return handler!(call);
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(child: LegacySwiftCompExport()))));
    await tester.pumpAndSettle();
  }

  test('non-Mac platforms never invoke the native archive channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const data = LegacySwiftCompData();
    expect(await data.isAvailable(), isFalse);
    expect(await data.export(), isFalse);
    expect(calls, isEmpty);
  });

  testWidgets(
      'fresh installations and missing plugins do not show archive controls',
      (tester) async {
    handler = (_) async => false;
    await show(tester);
    expect(find.byKey(const Key('legacy-swiftcomp-export')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    handler = (_) async => throw MissingPluginException();
    await show(tester);
    expect(find.text('Legacy SwiftComp data'), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets('only one save dialog opens while an export is pending',
      (tester) async {
    final pending = Completer<bool>();
    handler =
        (call) async => call.method == 'hasLegacyData' ? true : pending.future;
    await show(tester);
    final button = find.byKey(const Key('legacy-swiftcomp-export'));
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<TextButton>(button).onPressed, isNull);
    expect(calls.where((method) => method == 'exportLegacyData'), hasLength(1));
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Legacy SwiftComp data exported.'), findsOneWidget);
    expect(tester.widget<TextButton>(button).onPressed, isNotNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets('cancelling a save never claims that data was exported',
      (tester) async {
    handler = (call) async => call.method == 'hasLegacyData';
    await show(tester);
    await tester.tap(find.byKey(const Key('legacy-swiftcomp-export')));
    await tester.pumpAndSettle();
    expect(find.text('Legacy SwiftComp data exported.'), findsNothing);
    expect(find.textContaining('Could not export'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets('a native failure is visible and permits another attempt',
      (tester) async {
    handler = (call) async {
      if (call.method == 'hasLegacyData') return true;
      throw PlatformException(code: 'export_failed');
    };
    await show(tester);
    final button = find.byKey(const Key('legacy-swiftcomp-export'));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('Your original data has not been changed.'),
        findsOneWidget);
    handler = (_) async => true;
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Legacy SwiftComp data exported.'), findsOneWidget);
    expect(find.textContaining('Could not export'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets('closing Settings while native work completes is safe',
      (tester) async {
    final pending = Completer<bool>();
    handler =
        (call) async => call.method == 'hasLegacyData' ? true : pending.future;
    await show(tester);
    await tester.tap(find.byKey(const Key('legacy-swiftcomp-export')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);
}
