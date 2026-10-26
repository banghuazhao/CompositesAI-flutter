import 'package:domain/auth/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/views/chat_layout.dart';
import 'package:swiftcomp/presentation/chat/views/chat_welcome_view.dart';
import 'package:swiftcomp/util/app_theme.dart';

class _WelcomeData {
  const _WelcomeData(this.questions,
      {this.tasks = const [], this.user, this.bottomPadding = 0});

  final List<String> questions;
  final List<int?> tasks;
  final User? user;
  final double bottomPadding;
}

Future<ValueNotifier<_WelcomeData>> _mount(
  WidgetTester tester, {
  required _WelcomeData data,
  required List<int> selected,
  Size size = const Size(800, 900),
  double textScale = 1,
  Locale locale = const Locale('en'),
  bool reducedMotion = false,
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final input = ValueNotifier(data);
  addTearDown(input.dispose);
  await tester.pumpWidget(MaterialApp(
    theme: dark ? AppTheme.dark() : AppTheme.light(),
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
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion),
      child: child!,
    ),
    home: Scaffold(
      body: ValueListenableBuilder<_WelcomeData>(
        valueListenable: input,
        builder: (context, value, child) => ChatWelcomeView(
          user: value.user,
          questions: value.questions,
          taskIndices: value.tasks,
          bottomPadding: value.bottomPadding,
          onQuestionSelected: selected.add,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return input;
}

S _strings(WidgetTester tester) =>
    S.of(tester.element(find.byType(ChatWelcomeView)));
Finder _starter(int index) => find.byKey(ValueKey('chat-starter-$index'));
Finder _preview(int index) =>
    find.byKey(ValueKey('chat-starter-preview-$index'));
Finder _fullQuestion(int index) =>
    find.byKey(ValueKey('chat-starter-full-question-$index'));
final _more = find.byKey(const ValueKey('chat-welcome-more'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  final scrollable = find
      .descendant(
          of: find.byKey(const ValueKey('chat-welcome-view')),
          matching: find.byType(Scrollable))
      .first;
  if (finder.evaluate().isEmpty) {
    // The expanded prompt has its own scroll view. Drag the welcome gutter so
    // that a long preview cannot consume the outer-list gesture.
    for (var attempt = 0;
        attempt < 60 && finder.evaluate().isEmpty;
        attempt++) {
      final bounds = tester.getRect(scrollable);
      await tester.dragFrom(
        Offset(bounds.left + 8, bounds.center.dy),
        Offset(0, -bounds.height * .6),
      );
      await tester.pumpAndSettle();
    }
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty welcome invites an editable question without actions',
      (tester) async {
    final selected = <int>[];
    await _mount(tester, data: const _WelcomeData([]), selected: selected);
    expect(find.text(_strings(tester).Chat_starter_empty), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
    expect(_more, findsNothing);
    expect(selected, isEmpty);
  });

  for (final count in [1, 2, 3]) {
    testWidgets(
        '$count starters preserve original indices without more control',
        (tester) async {
      final selected = <int>[];
      final questions = List.generate(count, (i) => 'Exact question $i α?');
      await _mount(tester, data: _WelcomeData(questions), selected: selected);
      expect(_more, findsNothing);
      for (var i = 0; i < count; i++) {
        await _tap(tester, _starter(i));
      }
      expect(selected, List.generate(count, (i) => i));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('task labels use supplied identities despite reordered questions',
      (tester) async {
    final selected = <int>[];
    await _mount(tester,
        data: const _WelcomeData(
          [
            'Reordered lamina question',
            'Custom calculator failure material',
            'Reordered material question'
          ],
          tasks: [3, null, 0],
        ),
        selected: selected);
    final strings = _strings(tester);
    expect(find.text(strings.Chat_task_laminate), findsOneWidget);
    expect(find.text(strings.Chat_task_materials), findsOneWidget);
    expect(find.text(strings.Chat_task_generic), findsOneWidget);
    expect(find.text(strings.Chat_task_calculators), findsNothing);
    expect(find.text(strings.Chat_task_failure), findsNothing);
    await _tap(tester, _starter(0));
    expect(selected, [0]);
  });

  testWidgets('missing or invalid task mappings remain generic',
      (tester) async {
    await _mount(tester,
        data: const _WelcomeData(
          ['Estimate modulus', 'Plan laminate', 'Failure analysis'],
          tasks: [-1, 100],
        ),
        selected: []);
    expect(find.text(_strings(tester).Chat_task_generic), findsNWidgets(3));
    expect(find.byIcon(Icons.chat_bubble_outline), findsNWidgets(3));
  });

  testWidgets(
      'preview exposes exact Unicode and multiline source without selecting',
      (tester) async {
    final selected = <int>[];
    const question = '  请检查 α/β 🙂\n**Unparsed source**\n'
        'A long question with the original trailing spaces.  ';
    await _mount(tester,
        data: const _WelcomeData([question]), selected: selected);
    await _tap(tester, _preview(0));
    expect(tester.widget<SelectableText>(_fullQuestion(0)).data, question);
    expect(selected, isEmpty);
    expect(find.byTooltip(_strings(tester).Chat_starter_hide_preview),
        findsOneWidget);
    await _tap(tester, _preview(0));
    expect(_fullQuestion(0), findsNothing);
    expect(selected, isEmpty);
    await _tap(tester, _starter(0));
    expect(selected, [0]);
  });

  testWidgets(
      'more retains all custom suggestions and selects original last index',
      (tester) async {
    final selected = <int>[];
    final questions = List.generate(18, (i) => 'Custom prompt $i');
    await _mount(tester, data: _WelcomeData(questions), selected: selected);
    expect(_starter(3), findsNothing);
    await _tap(tester, _more);
    expect(selected, isEmpty);
    await _tap(tester, _starter(17));
    expect(selected, [17]);
    await _tap(tester, _more);
    expect(_starter(3), findsNothing);
    expect(selected, [17]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'preview survives lazy eviction but resets with changed suggestions',
      (tester) async {
    final questions = List.generate(30, (i) => 'Question $i');
    final input =
        await _mount(tester, data: _WelcomeData(questions), selected: []);
    await _tap(tester, _preview(0));
    await _tap(tester, _more);
    await _tap(tester, _starter(29));
    await tester.scrollUntilVisible(_preview(0), -250,
        scrollable: find
            .descendant(
                of: find.byKey(const ValueKey('chat-welcome-view')),
                matching: find.byType(Scrollable))
            .first,
        maxScrolls: 100);
    expect(tester.widget<SelectableText>(_fullQuestion(0)).data, 'Question 0');
    input.value = const _WelcomeData(['A replacement question']);
    await tester.pumpAndSettle();
    expect(_fullQuestion(0), findsNothing);
    expect(_more, findsNothing);
    expect(find.text('A replacement question'), findsOneWidget);
  });

  testWidgets(
      'stale selection and preview callbacks cannot act after replacement',
      (tester) async {
    final selected = <int>[];
    final input = await _mount(tester,
        data: const _WelcomeData(['Original'], tasks: [0]), selected: selected);
    final oldSelect = tester.widget<InkWell>(_starter(0)).onTap!;
    final oldPreview = tester.widget<IconButton>(_preview(0)).onPressed!;
    input.value = const _WelcomeData(['Replacement'], tasks: [3]);
    await tester.pumpAndSettle();
    oldSelect();
    oldPreview();
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(_fullQuestion(0), findsNothing);
    await _tap(tester, _starter(0));
    expect(selected, [0]);
  });

  testWidgets('in-place question and mapping edits retire retained callbacks',
      (tester) async {
    final selected = <int>[];
    final questions = ['Original'];
    final tasks = <int?>[0];
    final input = await _mount(tester,
        data: _WelcomeData(questions, tasks: tasks), selected: selected);
    final oldSelect = tester.widget<InkWell>(_starter(0)).onTap!;
    final oldPreview = tester.widget<IconButton>(_preview(0)).onPressed!;
    questions[0] = 'Changed before next frame';
    tasks[0] = 2;
    oldSelect();
    oldPreview();
    expect(selected, isEmpty);
    input.value = _WelcomeData(questions, tasks: tasks);
    await tester.pumpAndSettle();
    expect(find.text(_strings(tester).Chat_task_failure), findsOneWidget);
    oldSelect();
    expect(selected, isEmpty);
    await _tap(tester, _starter(0));
    expect(selected, [0]);
  });

  testWidgets('owner replacement retires previews and stale callbacks',
      (tester) async {
    final selected = <int>[];
    final input = await _mount(tester,
        data: _WelcomeData(['Private original'],
            user: User(id: 'a', email: 'a@example.test', name: 'A')),
        selected: selected);
    await _tap(tester, _preview(0));
    final oldSelect = tester.widget<InkWell>(_starter(0)).onTap!;
    input.value = _WelcomeData(['Private original'],
        user: User(id: 'b', email: 'b@example.test', name: 'B'));
    await tester.pumpAndSettle();
    oldSelect();
    expect(selected, isEmpty);
    expect(_fullQuestion(0), findsNothing);
    expect(find.text(_strings(tester).Chat_welcome_name('B')), findsOneWidget);
    input.value = const _WelcomeData([]);
    await tester.pumpAndSettle();
    expect(find.text('Private original'), findsNothing);
  });

  testWidgets('covered route and disposal make retained controls harmless',
      (tester) async {
    final selected = <int>[];
    await _mount(tester,
        data: const _WelcomeData(['Original']), selected: selected);
    final oldSelect = tester.widget<InkWell>(_starter(0)).onTap!;
    final oldPreview = tester.widget<IconButton>(_preview(0)).onPressed!;
    final navigator =
        Navigator.of(tester.element(find.byType(ChatWelcomeView)));
    navigator.push(MaterialPageRoute<void>(
        builder: (context) => const Scaffold(body: Text('Another route'))));
    await tester.pumpAndSettle();
    oldSelect();
    oldPreview();
    expect(selected, isEmpty);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(_fullQuestion(0), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    oldSelect();
    oldPreview();
    await tester.pump();
    expect(selected, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank entries are not applied and preserve subsequent indices',
      (tester) async {
    final selected = <int>[];
    await _mount(tester,
        data: const _WelcomeData(['  \n ', 'Actual question']),
        selected: selected);
    expect(tester.widget<InkWell>(_starter(0)).onTap, isNull);
    await _tap(tester, _starter(1));
    expect(selected, [1]);
  });

  final layouts = <(String, Size, double, Locale, bool)>[
    ('small phone', const Size(320, 640), 1, const Locale('en'), false),
    ('tablet', const Size(1200, 1000), 1, const Locale('en'), false),
    ('landscape', const Size(740, 320), 2, const Locale('en'), false),
    ('large English', const Size(320, 720), 3, const Locale('en'), true),
    ('large Chinese', const Size(320, 720), 3, const Locale('zh'), true),
    (
      'large Hong Kong',
      const Size(320, 720),
      3,
      const Locale('zh', 'HK'),
      true
    ),
  ];
  for (final layout in layouts) {
    testWidgets('${layout.$1} keeps full preview and every starter reachable',
        (tester) async {
      final selected = <int>[];
      final question = '层合板 α/β 🙂\n${'Full engineering question. ' * 40}';
      await _mount(tester,
          data: _WelcomeData(
              [question, 'Second question', 'Third question', 'Last question'],
              tasks: [3, 0, 1, null], bottomPadding: 140),
          selected: selected,
          size: layout.$2,
          textScale: layout.$3,
          locale: layout.$4,
          reducedMotion: layout.$5,
          dark: layout.$5);
      await _tap(tester, _preview(0));
      expect(tester.widget<SelectableText>(_fullQuestion(0)).data, question);
      expect(tester.getSize(_preview(0)).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(_preview(0)).width, greaterThanOrEqualTo(48));
      expect(selected, isEmpty);
      await _tap(tester, _more);
      await _tap(tester, _starter(3));
      expect(selected, [3]);
      expect(tester.takeException(), isNull);
      final card = find.byType(Card).last;
      expect(tester.getSize(card).width,
          lessThanOrEqualTo(ChatLayout.maximumContentWidth));
      if (layout.$5) {
        await tester.pump(const Duration(seconds: 1));
        expect(tester.binding.hasScheduledFrame, isFalse);
      }
    });
  }

  testWidgets('uses scheme surfaces and exposes the full prompt to semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final selected = <int>[];
      const question = 'Full accessible question α';
      await _mount(tester,
          data: const _WelcomeData([question], tasks: [0]),
          selected: selected,
          dark: true);
      final context = tester.element(find.byType(ChatWelcomeView));
      final scheme = Theme.of(context).colorScheme;
      expect(tester.widget<Card>(find.byType(Card)).color,
          scheme.surfaceContainerLow);
      final label = '${_strings(tester).Chat_starter_use_question}: '
          '${_strings(tester).Chat_task_materials}. $question';
      expect(find.bySemanticsLabel(label), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(
          node,
          matchesSemantics(
            label: label,
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ));
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      expect(selected, [0]);
    } finally {
      semantics.dispose();
    }
  });
}
