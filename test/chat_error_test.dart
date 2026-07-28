import 'dart:async';

import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/chat/model/chat_error.dart';
import 'package:swiftcomp/presentation/chat/views/chat_error_snack_bar.dart';

void main() {
  group('ChatErrorMapper', () {
    test('classifies network and timeout failures as retryable', () {
      final network = ChatErrorMapper.from(
        Exception('SocketException: connection reset by peer'),
        operation: ChatOperation.loadConversation,
      );
      final timeout = ChatErrorMapper.from(
        TimeoutException('request timed out'),
        operation: ChatOperation.sendMessage,
      );

      expect(network.type, ChatErrorType.network);
      expect(network.title, 'Connection problem');
      expect(network.retryable, true);
      expect(timeout.type, ChatErrorType.timeout);
      expect(timeout.retryable, true);
    });

    test('maps authentication and rate-limit domain failures safely', () {
      final unauthorized = ChatErrorMapper.from(
        UnauthorizedException('sensitive backend detail'),
        operation: ChatOperation.authenticate,
      );
      final rateLimited = ChatErrorMapper.from(
        TooManyRequestsException(),
        operation: ChatOperation.sendMessage,
      );

      expect(unauthorized.type, ChatErrorType.unauthorized);
      expect(unauthorized.message, isNot(contains('sensitive')));
      expect(unauthorized.retryable, false);
      expect(rateLimited.type, ChatErrorType.rateLimited);
      expect(rateLimited.severity, ChatErrorSeverity.warning);
    });
  });

  testWidgets('error snackbar presents context and invokes retry',
      (tester) async {
    var retried = false;
    const notice = ChatErrorNotice(
      id: 1,
      failure: ChatFailure(
        type: ChatErrorType.network,
        operation: ChatOperation.loadChats,
        title: 'Connection problem',
        message: 'Check your internet connection and try again.',
        retryable: true,
        technicalCode: 'CHAT_NETWORK',
      ),
      hasRetry: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  buildChatErrorSnackBar(
                    context: context,
                    notice: notice,
                    onRetry: () => retried = true,
                  ),
                );
              },
              child: const Text('Trigger'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Connection problem'), findsOneWidget);
    expect(
      find.text('Check your internet connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.byType(SnackBarAction));
    await tester.pump();
    expect(retried, true);
  });
}
