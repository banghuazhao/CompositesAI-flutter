import 'dart:async';
import 'dart:convert';

import 'package:data/auth/repositories/user_repository_impl.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_configuration.dart';
import 'package:domain/chat/entities/chat_folder.dart';
import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/chat_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/token_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/chat/model/chat_error.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';

class _Storage extends TokenProvider {
  String? token = 'test-session';
  int deletes = 0;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async {
    deletes++;
    token = null;
  }

  @override
  Future<bool> deleteTokenIfMatches(String expectedToken) async {
    if (token != expectedToken) return false;
    await deleteToken();
    return true;
  }
}

class _Environment extends APIEnvironment {
  @override
  Future<String> getBaseUrl() async => 'https://example.test/api';
}

class _Auth extends Fake implements AuthUseCase {
  _Auth(this.storage);
  final _Storage storage;

  @override
  Future<bool> isLoggedIn() async => storage.token != null;
}

class _Chats extends Fake implements ChatUseCase {
  int historyLoads = 0;
  int toolLoads = 0;
  int modelLoads = 0;

  @override
  Future<List<Chat>> fetchChats({int? page}) async {
    historyLoads++;
    return [Chat(id: 'history', title: 'Saved history')];
  }

  @override
  Future<List<Chat>> fetchPinnedChats() async => [];

  @override
  Future<List<ChatFolder>> fetchFolders() async => [];

  @override
  Future<List<ChatTool>> fetchTools() async {
    toolLoads++;
    return [const ChatTool(id: 'tool', name: 'Available tool')];
  }

  @override
  Future<List<ChatModel>> fetchModels() async {
    modelLoads++;
    return [const ChatModel(id: 'model', name: 'Available model', rawJson: {})];
  }

  @override
  Future<ChatConfiguration> fetchChatConfiguration() async =>
      const ChatConfiguration();
}

http.Response _profile(String id) => http.Response(
      jsonEncode({'id': id, 'email': '$id@example.test', 'name': 'Test User'}),
      200,
      headers: {'content-type': 'application/json'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Storage storage;
  late _Chats chats;
  ChatViewModel? model;

  UserRepositoryImpl repository(
    Future<http.Response> Function(http.Request) respond, {
    Duration timeout = const Duration(milliseconds: 15),
  }) =>
      UserRepositoryImpl(
        authClient: AuthenticatedHttpClient(MockClient(respond), storage),
        apiEnvironment: _Environment(),
        profileRequestTimeout: timeout,
      );

  ChatViewModel chatModel(UserRepositoryImpl users) {
    final value = ChatViewModel(
      chatUseCase: chats,
      authUseCase: _Auth(storage),
      userUserCase: UserUseCase(repository: users, tokenProvider: storage),
    );
    model = value;
    return value;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = _Storage();
    chats = _Chats();
    model = null;
  });

  tearDown(() => model?.dispose());

  test('stalled profile lookup times out without deleting the stored session',
      () async {
    final response = Completer<http.Response>();
    final users = repository((request) {
      expect(request.url.path, '/api/auths/');
      return response.future;
    });

    await expectLater(
      users.fetchMe(),
      throwsA(isA<TimeoutException>().having(
        (error) => error.message,
        'safe message',
        'Profile request timed out. Please try again.',
      )),
    );

    expect(storage.token, 'test-session');
    expect(storage.deletes, 0);
    response.complete(_profile('late-user'));
    await Future<void>.delayed(Duration.zero);
    expect(storage.token, 'test-session');
    expect(storage.deletes, 0);
  });

  test(
      'post-login profile Retry verifies session and hydrates history and tools',
      () async {
    final oldResponse = Completer<http.Response>();
    var requests = 0;
    final viewModel = chatModel(repository((_) async {
      requests++;
      return requests == 1
          ? await oldResponse.future
          : _profile('recovered-user');
    }));

    await viewModel.checkAuthStatus();

    final notice = viewModel.activeError!;
    expect(notice.failure.operation, ChatOperation.authenticate);
    expect(notice.failure.type, ChatErrorType.timeout);
    expect(notice.canRetry, isTrue);
    expect(viewModel.isLoggedIn, isFalse);
    expect(storage.token, 'test-session');
    expect(chats.historyLoads, 0);
    expect(chats.toolLoads, 0);

    await viewModel.retryError(notice.id);

    expect(viewModel.isLoggedIn, isTrue);
    expect(viewModel.user?.id, 'recovered-user');
    expect(viewModel.activeError, isNull);
    expect(viewModel.chats.single.id, 'history');
    expect(viewModel.tools.single.id, 'tool');
    expect(viewModel.models.single.id, 'model');
    expect(chats.historyLoads, 1);
    expect(chats.toolLoads, 1);
    expect(chats.modelLoads, 1);
    oldResponse.complete(_profile('stale-user'));
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.user?.id, 'recovered-user');
    expect(storage.deletes, 0);
  });

  test('ordinary successful session checks do not duplicate screen hydration',
      () async {
    final viewModel =
        chatModel(repository((_) async => _profile('current-user')));

    await viewModel.checkAuthStatus();
    await viewModel.fetchAuthSessionNew();

    expect(viewModel.isLoggedIn, isTrue);
    expect(viewModel.activeError, isNull);
    expect(chats.historyLoads, 0);
    expect(chats.toolLoads, 0);
    expect(chats.modelLoads, 0);
  });

  test('a second profile timeout preserves a user without hydrating on Retry',
      () async {
    final pending = [Completer<http.Response>(), Completer<http.Response>()];
    var requests = 0;
    final viewModel = chatModel(repository((_) async {
      requests++;
      return requests == 1
          ? _profile('current-user')
          : await pending[requests - 2].future;
    }));
    await viewModel.checkAuthStatus();
    final currentUser = viewModel.user;
    final privateChat = Chat(id: 'existing-history', title: 'Existing history');
    viewModel.chats = [privateChat];

    await viewModel.checkAuthStatus();
    await viewModel.retryError(viewModel.activeError!.id);

    expect(viewModel.isLoggedIn, isTrue);
    expect(viewModel.user, same(currentUser));
    expect(viewModel.chats.single, same(privateChat));
    expect(viewModel.activeError?.failure.type, ChatErrorType.timeout);
    expect(chats.historyLoads, 0);
    expect(chats.toolLoads, 0);
    expect(storage.deletes, 0);
    for (final response in pending) {
      response.complete(_profile('late-user'));
    }
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.user, same(currentUser));
  });

  test('superseded auth Retry cannot hydrate or replace a newer account',
      () async {
    final first = Completer<http.Response>();
    final oldRetry = Completer<http.Response>();
    final retryStarted = Completer<void>();
    var requests = 0;
    final viewModel = chatModel(repository((_) async {
      requests++;
      if (requests == 1) return first.future;
      if (requests == 2) {
        retryStarted.complete();
        return oldRetry.future;
      }
      return _profile('account-b');
    }, timeout: const Duration(milliseconds: 100)));
    await viewModel.checkAuthStatus();
    final retry = viewModel.retryError(viewModel.activeError!.id);
    await retryStarted.future;

    await storage.saveToken('new-test-session');
    await viewModel.checkAuthStatus();
    oldRetry.complete(_profile('account-a'));
    await retry;
    first.complete(_profile('account-a'));
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.isLoggedIn, isTrue);
    expect(viewModel.user?.id, 'account-b');
    expect(viewModel.activeError, isNull);
    expect(storage.token, 'new-test-session');
    expect(storage.deletes, 0);
    expect(chats.historyLoads, 0);
    expect(chats.toolLoads, 0);
  });

  test('profile success arriving after logout cannot restore the old user',
      () async {
    final response = Completer<http.Response>();
    final started = Completer<void>();
    final viewModel = chatModel(repository((_) {
      started.complete();
      return response.future;
    }, timeout: const Duration(seconds: 1)));
    final checking = viewModel.checkAuthStatus();
    await started.future;

    await storage.deleteToken();
    await viewModel.clearChatStateOnLogout();
    response.complete(_profile('old-account'));
    await checking;

    expect(viewModel.user, isNull);
    expect(viewModel.isLoggedIn, isFalse);
    expect(viewModel.activeError, isNull);
    expect(storage.token, isNull);
    expect(chats.historyLoads, 0);
  });
}
