import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/model/chat_export.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_message_timestamp.dart';
import 'package:swiftcomp/presentation/chat/views/message_list.dart';

final _instant = DateTime.utc(2026, 10, 20, 15, 7);

class _UseCase extends Fake implements ChatUseCase {}

class _Model extends ChatViewModel {
  _Model()
      : super(
          chatUseCase: _UseCase(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'first-account', email: 'first@example.test');
    selectedChat = Chat(id: 'first-chat', title: 'Timestamp fixture');
    messages = [
      Message(role: 'user', content: 'Original question α'),
      Message(role: 'assistant', content: 'Original answer β'),
    ];
    for (final message in messages) {
      message.timestamp = _instant.millisecondsSinceEpoch;
    }
  }

  bool sending = false;
  final copied = <String>[];

  @override
  bool get isSendingMessage => sending;

  @override
  bool get canRegenerate => false;

  @override
  void copyMessage(Message message) => copied.add(message.content);
}

class _UnformattableDate extends DefaultMaterialLocalizations {
  @override
  String formatFullDate(DateTime date) =>
      throw RangeError('Date formatter rejected this history value');
}

class _UnformattableDateDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _UnformattableDateDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(_UnformattableDate());

  @override
  bool shouldReload(_UnformattableDateDelegate old) => false;
}

Future<void> _mount(
  WidgetTester tester, {
  required Widget child,
  Locale locale = const Locale('en'),
  bool use24Hours = false,
  List<LocalizationsDelegate<dynamic>> extraDelegates = const [],
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: [
        ...extraDelegates,
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(2),
          alwaysUse24HourFormat: use24Hours,
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

String _time(
  WidgetTester tester,
  Finder timestamp, {
  bool use24Hours = false,
}) =>
    MaterialLocalizations.of(tester.element(timestamp)).formatTimeOfDay(
      TimeOfDay.fromDateTime(_instant.toLocal()),
      alwaysUse24HourFormat: use24Hours,
    );

String _detail(
  WidgetTester tester,
  Finder timestamp, {
  bool use24Hours = false,
}) {
  final context = tester.element(timestamp);
  final date = MaterialLocalizations.of(
    context,
  ).formatFullDate(_instant.toLocal());
  return S.of(context).Chat_message_time(
        '$date, ${_time(tester, timestamp, use24Hours: use24Hours)}',
      );
}

Future<void> _openTooltip(WidgetTester tester, Finder timestamp) async {
  await tester.ensureVisible(timestamp);
  await tester.tap(timestamp);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    for (final use24Hours in [false, true]) {
      testWidgets('$locale timestamp honors 24-hour=$use24Hours at320px2x', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        try {
          await _mount(
            tester,
            locale: locale,
            use24Hours: use24Hours,
            child: ChatMessageTimestamp(
              timestamp: _instant.millisecondsSinceEpoch,
            ),
          );
          final timestamp = find.byType(ChatMessageTimestamp);
          final time = _time(tester, timestamp, use24Hours: use24Hours);
          final detail = _detail(tester, timestamp, use24Hours: use24Hours);
          expect(find.text(time), findsOneWidget);
          expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, detail);
          expect(
            tester.getSemantics(timestamp).getSemanticsData().label,
            detail,
          );
          if (use24Hours) expect(time, matches(RegExp(r'^\d{2}:\d{2}$')));
          if (locale.languageCode != 'en') {
            expect(detail, isNot(startsWith('Message time:')));
          }
          await _openTooltip(tester, timestamp);
          expect(find.text(detail, findRichText: true), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          semantics.dispose();
        }
      });
    }
  }

  testWidgets('unknown and unsupported timestamps render no time or tooltip', (
    tester,
  ) async {
    for (final value in <int?>[
      null,
      0,
      -1,
      8640000000000000,
      8640000000000001,
      9007199254740991,
      DateTime.utc(10000, 1, 2).millisecondsSinceEpoch,
    ]) {
      await _mount(tester, child: ChatMessageTimestamp(timestamp: value));
      expect(find.byType(Tooltip), findsNothing, reason: 'timestamp=$value');
      expect(find.byType(Text), findsNothing, reason: 'timestamp=$value');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('small positive timestamp keeps millisecond meaning', (
    tester,
  ) async {
    const milliseconds = 1700000000;
    await _mount(
      tester,
      child: const ChatMessageTimestamp(timestamp: milliseconds),
    );
    final context = tester.element(find.byType(ChatMessageTimestamp));
    final local = DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
    final fullDate = MaterialLocalizations.of(context).formatFullDate(local);
    expect(local.year, 1970);
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip)).message,
      contains(fullDate),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unavailable localization and rejected date formats are recoverable',
    (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChatMessageTimestamp(
            timestamp: _instant.millisecondsSinceEpoch,
          ),
        ),
      );
      expect(find.byType(Tooltip), findsNothing);
      expect(tester.takeException(), isNull);
      await _mount(
        tester,
        extraDelegates: const [_UnformattableDateDelegate()],
        child: ChatMessageTimestamp(timestamp: _instant.millisecondsSinceEpoch),
      );
      expect(find.byType(Tooltip), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'message content, history, copy and Markdown export remain unchanged',
    (tester) async {
      final model = _Model();
      try {
        final history =
            model.messages.map((message) => message.toJson()).toList();
        final markdown = ChatExport.toMarkdown(
          title: 'Fixture',
          messages: model.messages,
          exportedAt: _instant,
        );
        await _mount(
          tester,
          child: ChangeNotifierProvider<ChatViewModel>.value(
            value: model,
            child: const MessageList(bottomContentPadding: 0),
          ),
        );
        expect(find.byType(ChatMessageTimestamp), findsNWidgets(2));
        expect(
          model.messages.map((message) => message.toJson()).toList(),
          history,
        );
        expect(
          ChatExport.toMarkdown(
            title: 'Fixture',
            messages: model.messages,
            exportedAt: _instant,
          ),
          markdown,
        );
        final copy = find.byTooltip('Copy message').first;
        await tester.ensureVisible(copy);
        await tester.tap(copy);
        await tester.pump();
        expect(model.copied, ['Original question α']);

        final assistant = model.messages.last;
        final timestamp = find.byKey(
          ValueKey('chat-message-time-${assistant.id}'),
        );
        final time = _time(tester, timestamp);
        model.sending = true;
        assistant.content = 'Streaming replacement content β';
        model.notifyListeners();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.widget<ChatMessageTimestamp>(timestamp).timestamp,
          _instant.millisecondsSinceEpoch,
        );
        expect(
          find.descendant(of: timestamp, matching: find.text(time)),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        model.dispose();
      }
    },
  );

  testWidgets('open details retire on chat, account and widget replacement', (
    tester,
  ) async {
    final model = _Model();
    try {
      await _mount(
        tester,
        child: ChangeNotifierProvider<ChatViewModel>.value(
          value: model,
          child: const MessageList(bottomContentPadding: 0),
        ),
      );
      final timestamp = find.byKey(
        ValueKey('chat-message-time-${model.messages.first.id}'),
      );
      final detail = _detail(tester, timestamp);
      await _openTooltip(tester, timestamp);
      expect(find.text(detail, findRichText: true), findsOneWidget);

      model.selectedChat = Chat(id: 'second-chat', title: 'Another chat');
      model.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text(detail, findRichText: true), findsNothing);
      await _openTooltip(tester, timestamp);
      expect(find.text(detail, findRichText: true), findsOneWidget);

      model.user = User(id: 'second-account', email: 'second@example.test');
      model.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text(detail, findRichText: true), findsNothing);
      await _openTooltip(tester, timestamp);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(find.text(detail, findRichText: true), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      model.dispose();
    }
  });
}
