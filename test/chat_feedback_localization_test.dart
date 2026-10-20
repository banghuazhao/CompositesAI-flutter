import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/response_feedback_sheet.dart';

const _openFeedbackKey = Key('open-feedback');

class _UseCase extends Fake implements ChatUseCase {}

class _FeedbackModel extends ChatViewModel {
  _FeedbackModel()
      : super(
          chatUseCase: _UseCase(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    selectedChat = Chat(id: 'feedback-chat', title: 'Feedback fixture');
  }

  final submissions = <({
    List<String> reasons,
    int rating,
    int score,
    int index,
    String? comment,
  })>[];

  @override
  Future<bool> submitMessageFeedback({
    required Message message,
    required int goodBadRating,
    required int detailsRating,
    required List<String> reasons,
    String? comment,
    required int messageIndex,
  }) async {
    submissions.add((
      reasons: List<String>.of(reasons),
      rating: goodBadRating,
      score: detailsRating,
      index: messageIndex,
      comment: comment,
    ));
    message.feedbackId = 'saved-feedback';
    message.feedbackRating = goodBadRating;
    message.feedbackDetailsRating = detailsRating;
    message.feedbackReasons = List<String>.of(reasons);
    message.feedbackComment = comment;
    return true;
  }
}

Future<S> _mount(
  WidgetTester tester,
  _FeedbackModel model,
  Message message,
  Locale locale, {
  bool isGood = true,
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(2), disableAnimations: true),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: _openFeedbackKey,
              onPressed: () {
                showResponseFeedbackSheet(
                  context: context,
                  viewModel: model,
                  message: message,
                  initialIsGood: isGood,
                  messageIndex: 3,
                );
              },
              child: const Text('Open feedback'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return S.of(tester.element(find.byKey(_openFeedbackKey)));
}

Finder _reason(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(FilterChip));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
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
    testWidgets(
      '$locale translated reason submits and reopens canonical saved feedback',
      (tester) async {
        final model = _FeedbackModel();
        final message = Message(role: 'assistant', content: 'Answer α');
        try {
          final strings = await _mount(tester, model, message, locale);
          expect(
            strings.Chat_feedback_accurate,
            locale.languageCode == 'en'
                ? 'Accurate'
                : locale.countryCode == 'HK'
                    ? '準確'
                    : '准确',
          );
          await _tap(tester, find.byKey(_openFeedbackKey));
          expect(find.text(strings.Chat_feedback_title), findsOneWidget);
          if (locale.languageCode != 'en') {
            expect(find.text('Accurate'), findsNothing);
          }
          final reason = _reason(strings.Chat_feedback_accurate);
          expect(tester.widget<FilterChip>(reason).selected, isFalse);
          await _tap(tester, reason);
          expect(tester.widget<FilterChip>(reason).selected, isTrue);

          await tester.ensureVisible(find.byType(TextField));
          await tester.enterText(find.byType(TextField), '  保留 α 细节  ');
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
          await _tap(tester, find.text(strings.Chat_feedback_submit));

          expect(model.submissions, hasLength(1));
          final submission = model.submissions.single;
          expect(submission.reasons, ['Accurate']);
          expect(submission.rating, 1);
          expect(submission.score, 10);
          expect(submission.index, 4);
          expect(submission.comment, '保留 α 细节');
          expect(message.feedbackReasons, ['Accurate']);
          expect(find.text(strings.Chat_feedback_saved), findsOneWidget);

          await _tap(tester, find.byKey(_openFeedbackKey));
          expect(find.text(strings.Chat_feedback_update), findsOneWidget);
          expect(
            tester
                .widget<FilterChip>(_reason(strings.Chat_feedback_accurate))
                .selected,
            isTrue,
          );
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            '保留 α 细节',
          );
          if (locale.languageCode != 'en') {
            expect(find.text('Accurate'), findsNothing);
          }
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          model.dispose();
        }
      },
    );

    testWidgets(
      '$locale narrow large-text validation and negative reason keep API values',
      (tester) async {
        final model = _FeedbackModel();
        final message = Message(role: 'assistant', content: 'Answer β');
        try {
          final strings = await _mount(
            tester,
            model,
            message,
            locale,
            isGood: false,
          );
          await _tap(tester, find.byKey(_openFeedbackKey));
          expect(find.text(strings.Chat_feedback_needs_work), findsOneWidget);
          await _tap(tester, find.text(strings.Chat_feedback_submit));
          expect(
            find.text(strings.Chat_feedback_reason_required),
            findsOneWidget,
          );
          expect(model.submissions, isEmpty);

          await _tap(tester, _reason(strings.Chat_feedback_did_not_follow));
          expect(
            find.text(strings.Chat_feedback_reason_required),
            findsNothing,
          );
          await _tap(tester, find.text(strings.Chat_feedback_submit));
          expect(model.submissions, hasLength(1));
          final submission = model.submissions.single;
          expect(submission.reasons, ["Didn't follow instructions"]);
          expect(submission.rating, -1);
          expect(submission.score, 1);
          expect(submission.comment, isNull);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          model.dispose();
        }
      },
    );
  }
}
