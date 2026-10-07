import 'dart:async';
import 'dart:convert';

import 'package:data/chat/chat_repository_imp.dart';
import 'package:data/chat/chat_socket_session.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/token_provider.dart';

class _Environment extends APIEnvironment {
  @override
  Future<String> getWebBaseUrl() async => 'https://example.test';
}

class _Token extends TokenProvider {
  @override
  Future<String?> getToken() async => 'test-session';
}

class _Socket extends Fake implements ChatSocketSession {
  final listening = Completer<void>();
  late final controller = StreamController<Map<String, dynamic>>.broadcast(
    onListen: () => listening.complete(),
  );
  bool closed = false;

  @override
  String get sessionId => 'socket-session';

  @override
  Stream<Map<String, dynamic>> get events => controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    if (!controller.isClosed) await controller.close();
  }

  void emit(Map<String, dynamic> data, {String chatId = 'chat-1'}) {
    controller.add({
      'chat_id': chatId,
      'message_id': 'message-1',
      'data': data,
    });
  }
}

class _Fixture {
  final socket = _Socket();
  final requests = <http.Request>[];
  final requestStarted = Completer<void>();
  final kickoff = Completer<http.Response>();
  late final ChatRepositoryImpl repository;

  _Fixture() {
    final token = _Token();
    repository = ChatRepositoryImpl(
      authClient: AuthenticatedHttpClient(MockClient((request) async {
        requests.add(request);
        return http.Response('{"status":true}', 200);
      }), token),
      apiEnvironment: _Environment(),
      tokenProvider: token,
      streamClientFactory: () => MockClient((request) async {
        requestStarted.complete();
        return kickoff.future;
      }),
      connectSocketSession: ({required webBaseUri, required token}) async =>
          socket,
    );
  }

  Stream<ChatStreamEvent> stream({bool toolChat = true}) =>
      repository.sendMessages(
        [Message(role: 'user', content: 'Question')],
        Chat(id: 'chat-1', title: 'Question'),
        'message-1',
        toolIds: toolChat ? ['tool-1'] : [],
      );

  void respond({String taskId = 'task-1'}) {
    kickoff.complete(http.Response(
      jsonEncode({'status': true, 'task_id': taskId}),
      200,
      headers: {'content-type': 'application/json'},
    ));
  }
}

class _StreamingClient extends http.BaseClient {
  final response = StreamController<List<int>>();
  final started = Completer<void>();
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    started.complete();
    return http.StreamedResponse(response.stream, 200,
        headers: {'content-type': 'text/event-stream'});
  }

  @override
  void close() {
    closed = true;
    unawaited(response.close());
  }
}

void main() {
  test('stopping a tool response cancels its authenticated backend task',
      () async {
    final fixture = _Fixture();
    final subscription = fixture.stream().listen((_) {});
    fixture.respond(taskId: 'task/one');
    await fixture.socket.listening.future;

    await subscription.cancel().timeout(const Duration(seconds: 2));

    expect(fixture.requests, hasLength(1));
    expect(fixture.requests.single.method, 'POST');
    expect(fixture.requests.single.url.pathSegments,
        ['api', 'tasks', 'stop', 'task/one']);
    expect(fixture.requests.single.headers['Authorization'],
        'Bearer test-session');
    expect(fixture.socket.closed, true);
  });

  test('Stop before kickoff still cancels the task returned later', () async {
    final fixture = _Fixture();
    final subscription = fixture.stream().listen((_) {});
    await fixture.requestStarted.future;
    final cancellation = subscription.cancel();
    fixture.respond();

    await cancellation.timeout(const Duration(seconds: 2));

    expect(fixture.requests, hasLength(1));
    expect(fixture.requests.single.url.path, '/api/tasks/stop/task-1');
    expect(fixture.socket.closed, true);
  });

  test('a paused response can still stop and close its transport', () async {
    final fixture = _Fixture();
    final subscription = fixture.stream().listen((_) {});
    fixture.respond();
    await fixture.socket.listening.future;
    subscription.pause();

    await subscription.cancel().timeout(const Duration(seconds: 2));

    expect(fixture.requests.single.url.path, '/api/tasks/stop/task-1');
    expect(fixture.socket.closed, true);
  });

  test('completed tool response does not cancel its backend task', () async {
    final fixture = _Fixture();
    final result = fixture.stream().toList();
    fixture.respond();
    await fixture.socket.listening.future;
    fixture.socket.emit({
      'type': 'chat:completion',
      'data': {'content': 'Finished answer', 'done': true},
    });

    expect((await result).single.content, 'Finished answer');
    expect(fixture.requests, isEmpty);
    expect(fixture.socket.closed, true);
  });

  test('matching task-cancelled event ends the response without another Stop',
      () async {
    final fixture = _Fixture();
    final result = fixture.stream().toList();
    fixture.respond();
    await fixture.socket.listening.future;
    fixture.socket.emit({'type': 'task-cancelled'}, chatId: 'another-chat');
    fixture.socket.emit({'type': 'task-cancelled'});

    expect((await result).single.cancelled, true);
    expect(fixture.requests, isEmpty);
    expect(fixture.socket.closed, true);
  });

  test('ordinary streaming completes without a backend Stop request', () async {
    final fixture = _Fixture();
    final result = fixture.stream(toolChat: false).toList();
    fixture.kickoff.complete(http.Response(
      'data: {"choices":[{"delta":{"content":"Answer"}}]}\n\n'
      'data: [DONE]\n\n',
      200,
      headers: {'content-type': 'text/event-stream'},
    ));

    expect((await result).single.content, 'Answer');
    expect(fixture.requests, isEmpty);
    expect(fixture.socket.closed, false);
  });

  test('ordinary streaming Stop closes its HTTP transport without a task',
      () async {
    final token = _Token();
    final requests = <http.Request>[];
    final client = _StreamingClient();
    final repository = ChatRepositoryImpl(
      authClient: AuthenticatedHttpClient(MockClient((request) async {
        requests.add(request);
        return http.Response('', 200);
      }), token),
      apiEnvironment: _Environment(),
      tokenProvider: token,
      streamClientFactory: () => client,
    );
    final subscription = repository.sendMessages(
      [Message(role: 'user', content: 'Question')],
      Chat(id: 'chat-1', title: 'Question'),
      'message-1',
    ).listen((_) {});
    await client.started.future;

    await subscription.cancel().timeout(const Duration(seconds: 2));

    expect(client.closed, true);
    expect(requests, isEmpty);
  });
}
