import 'dart:async';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/chat_folder.dart';
import 'package:domain/chat/entities/chat_knowledge.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:file_picker/src/platform/file_picker_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/chat/model/chat_error.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';

class _SessionChatUseCase extends Fake implements ChatUseCase {
  Future<List<Chat>> Function()? loadChats;
  Future<List<Message>> Function()? loadMessages;
  Future<List<ChatKnowledge>> Function()? loadKnowledge;
  Future<ChatFile> Function()? uploadFile;

  @override
  Future<List<Chat>> fetchChats({int? page}) async =>
      loadChats == null ? <Chat>[] : await loadChats!();

  @override
  Future<List<Chat>> fetchPinnedChats() async => <Chat>[];

  @override
  Future<List<ChatFolder>> fetchFolders() async => <ChatFolder>[];

  @override
  Future<List<Message>> fetchMessages(Chat chat) async =>
      loadMessages == null ? <Message>[] : await loadMessages!();

  @override
  Future<List<ChatKnowledge>> fetchKnowledgeBases() async =>
      loadKnowledge == null ? <ChatKnowledge>[] : await loadKnowledge!();

  @override
  Future<ChatFile> uploadChatFile({
    required String name,
    required int size,
    String? path,
    List<int>? bytes,
  }) =>
      uploadFile!();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockAuthUseCase auth;
  late MockUserUseCase users;
  late _SessionChatUseCase chats;
  late ChatViewModel model;
  final accountA = User(id: 'account-a', email: 'a@example.test');
  final accountB = User(id: 'account-b', email: 'b@example.test');
  final privateChat = Chat(id: 'private-a', title: 'Private account A chat');
  const privateKnowledge =
      ChatKnowledge(id: 'knowledge-a', name: 'Private account A document');

  Future<void> signInAs(User user) async {
    when(auth.isLoggedIn()).thenAnswer((_) async => true);
    when(users.fetchMe()).thenAnswer((_) async => user);
    await model.checkAuthStatus();
  }

  void addPrivateState() {
    model.chats = [privateChat];
    model.pinnedChats = [privateChat];
    model.filteredChats = [privateChat];
    model.archivedChats = [privateChat];
    model.chatFolders = [
      ChatFolder(id: 'folder-a', name: 'Private folder', chats: [privateChat]),
    ];
    model.selectedChat = privateChat;
    model.messages = [Message(role: 'user', content: 'Private account A text')];
    model.chatSearchQuery = 'Private';
    model.toggleKnowledgeCollection(privateKnowledge);
  }

  void expectPrivateStateCleared() {
    expect(model.selectedChat, isNull);
    expect(model.messages, isEmpty);
    expect(model.chats, isEmpty);
    expect(model.pinnedChats, isEmpty);
    expect(model.filteredChats, isEmpty);
    expect(model.archivedChats, isEmpty);
    expect(model.chatFolders, isEmpty);
    expect(model.pendingFiles, isEmpty);
    expect(model.pendingImageBytes, isEmpty);
    expect(model.knowledgeBases, isEmpty);
    expect(model.chatSearchQuery, isEmpty);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'themeMode': 'dark',
      'chat_count': 7,
      'languageCode': 'fr',
    });
    auth = MockAuthUseCase();
    users = MockUserUseCase();
    chats = _SessionChatUseCase();
    model = ChatViewModel(
      chatUseCase: chats,
      authUseCase: auth,
      userUserCase: users,
    );
    await signInAs(accountA);
  });

  tearDown(() => model.dispose());

  test('expired A session clears private state before B signs in', () async {
    addPrivateState();
    when(users.fetchMe())
        .thenAnswer((_) async => throw UnauthorizedException());

    await model.checkAuthStatus();

    expect(model.isLoggedIn, isFalse);
    expect(model.user, isNull);
    expect(model.activeError?.failure.type, ChatErrorType.unauthorized);
    expectPrivateStateCleared();

    await signInAs(accountB);

    expect(model.isLoggedIn, isTrue);
    expect(model.user, same(accountB));
    expectPrivateStateCleared();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('themeMode'), 'dark');
    expect(preferences.getString('languageCode'), 'fr');
    expect(preferences.getInt('chat_count'), 7);
  });

  test('a missing session clears private state without a server request',
      () async {
    addPrivateState();
    clearInteractions(users);
    when(auth.isLoggedIn()).thenAnswer((_) async => false);

    await model.fetchAuthSessionNew();

    expect(model.isLoggedIn, isFalse);
    expect(model.user, isNull);
    expectPrivateStateCleared();
    verifyNever(users.fetchMe());
  });

  test('account identity change clears cached state even without a prior 401',
      () async {
    addPrivateState();

    await signInAs(accountB);

    expect(model.isLoggedIn, isTrue);
    expect(model.user, same(accountB));
    expectPrivateStateCleared();
  });

  test('temporary verification failure preserves current session and contents',
      () async {
    addPrivateState();
    when(users.fetchMe()).thenAnswer(
        (_) async => throw TimeoutException('Session request timed out'));

    await model.checkAuthStatus();

    expect(model.isLoggedIn, isTrue);
    expect(model.user, same(accountA));
    expect(model.selectedChat, same(privateChat));
    expect(model.messages.single.content, 'Private account A text');
    expect(model.pendingFiles.single.id, privateKnowledge.id);
    expect(model.activeError?.failure.type, ChatErrorType.timeout);
  });

  test('late private history, messages and knowledge cannot populate B session',
      () async {
    final history = Completer<List<Chat>>();
    final messages = Completer<List<Message>>();
    final knowledge = Completer<List<ChatKnowledge>>();
    chats.loadChats = () => history.future;
    chats.loadMessages = () => messages.future;
    chats.loadKnowledge = () => knowledge.future;
    final loadingHistory = model.fetchChats();
    final loadingMessages = model.selectChat(privateChat);
    final loadingKnowledge = model.fetchKnowledgeBases();

    await model.clearChatStateOnLogout();
    await signInAs(accountB);
    history.complete([privateChat]);
    messages.complete([Message(role: 'user', content: 'Late private text')]);
    knowledge.complete([privateKnowledge]);
    await Future.wait([loadingHistory, loadingMessages, loadingKnowledge]);

    expect(model.user, same(accountB));
    expectPrivateStateCleared();
  });

  test('late unauthorized history response from A does not expire B session',
      () async {
    final history = Completer<List<Chat>>();
    chats.loadChats = () => history.future;
    final loadingHistory = model.fetchChats();
    await signInAs(accountB);

    history.completeError(UnauthorizedException());
    await loadingHistory;

    expect(model.isLoggedIn, isTrue);
    expect(model.user, same(accountB));
    expect(model.activeError, isNull);
  });

  test('late authentication failure from A cannot overwrite newer B sign-in',
      () async {
    final oldVerification = Completer<User>();
    when(users.fetchMe()).thenAnswer((_) => oldVerification.future);
    final verifyingA = model.fetchUser();
    await signInAs(accountB);

    oldVerification.completeError(UnauthorizedException());
    await verifyingA;

    expect(model.isLoggedIn, isTrue);
    expect(model.user, same(accountB));
    expect(model.activeError, isNull);
  });

  test('an upload finishing after account change cannot attach A file to B',
      () async {
    MethodChannelFilePicker.registerWith();
    const picker = MethodChannel('miguelruivo.flutter.plugins.filepicker');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        picker,
        (_) async => [
              {'path': '/private-a.txt', 'name': 'private-a.txt', 'size': 12},
            ]);
    addTearDown(() => messenger.setMockMethodCallHandler(picker, null));
    final started = Completer<void>();
    final upload = Completer<ChatFile>();
    chats.uploadFile = () {
      started.complete();
      return upload.future;
    };
    final uploading = model.pickAndUploadFiles();
    await started.future;
    expect(model.isUploadingFile, isTrue);

    await signInAs(accountB);
    upload.complete(const ChatFile(
      id: 'uploaded-a',
      name: 'private-a.txt',
      url: '/files/uploaded-a',
    ));
    await uploading;

    expect(model.user, same(accountB));
    expect(model.isUploadingFile, isFalse);
    expect(model.uploadingFileNames, isEmpty);
    expectPrivateStateCleared();
  });
}
