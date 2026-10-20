import 'dart:async';
import 'dart:collection';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_folder.dart';
import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/chat/controllers/chat_composer_controller.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/util/chat_limiter.dart';
import 'package:swiftcomp/util/others.dart';

class _Auth extends Fake implements AuthUseCase {
  @override
  Future<bool> isLoggedIn() async => true;
}

class _Users extends Fake implements UserUseCase {
  User current = User(id: 'account-a', email: 'a@example.test');

  @override
  Future<User> fetchMe() async => current;
}

class _Limiter extends ChatLimiter {
  final pending = Queue<Completer<bool>>();
  int calls = 0;

  @override
  Future<bool> reachChatLimit() {
    calls++;
    return pending.isEmpty ? Future.value(false) : pending.removeFirst().future;
  }
}

class _Chats extends Fake implements ChatUseCase {
  Future<Chat> Function(Message)? create;
  Future<List<Chat>> Function()? loadChats;
  Future<List<Message>> Function(Chat)? loadMessages;
  final sent = <({String chatId, List<String> prompts})>[];
  int created = 0;
  bool failDelete = false;

  @override
  Future<List<Message>> fetchMessages(Chat chat) async =>
      loadMessages == null ? [] : await loadMessages!(chat);

  @override
  Future<List<Chat>> fetchChats({int? page}) async =>
      loadChats == null ? [] : await loadChats!();

  @override
  Future<List<Chat>> fetchPinnedChats() async => [];

  @override
  Future<List<ChatFolder>> fetchFolders() async => [];

  @override
  Future<Chat> createChat(Message message) async {
    created++;
    return create == null
        ? Chat(id: 'created-$created', title: message.content)
        : await create!(message);
  }

  @override
  Stream<ChatStreamEvent> sendMessages(
      List<Message> messages, Chat chat, String id,
      {List<String> toolIds = const [], ChatModel? model}) {
    sent.add((
      chatId: chat.id,
      prompts: [
        for (final message in messages)
          if (message.role == 'user') message.content
      ],
    ));
    return const Stream.empty();
  }

  @override
  Future<void> completeSendMessages(
      List<Message> messages, Chat chat, String id) async {}

  @override
  Future<void> persistMessages(List<Message> messages, Chat chat) async {}

  @override
  Future<void> updateChatMessage(Message message, Chat chat) async {}

  @override
  Future<void> deleteChat(Chat chat) async {
    if (failDelete) throw StateError('Delete failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Composer cache', () {
    test('New/A/B preserve exact text and selection without stale composition',
        () {
      final composer = ChatComposerController();
      addTearDown(composer.dispose);
      const original = TextEditingValue(
        text: '  New\n原稿  ',
        selection:
            TextSelection(baseOffset: 7, extentOffset: 3, isDirectional: true),
        composing: TextRange(start: 2, end: 5),
      );
      composer.textController.value = original;
      composer.selectChat('a');
      composer.textController.text = 'A draft';
      composer.selectChat('b');
      composer.textController.text = 'B draft';
      composer.selectChat(null);
      expect(composer.textController.text, original.text);
      expect(composer.textController.selection, original.selection);
      expect(composer.textController.value.composing, TextRange.empty);
      composer.selectChat('a');
      expect(composer.textController.text, 'A draft');
      expect(composer.textController.selection,
          const TextSelection.collapsed(offset: 7));
      composer.selectChat('b');
      expect(composer.textController.text, 'B draft');
      composer.selectChat('');
      expect(composer.textController.text, isEmpty,
          reason: 'An empty server ID must not alias New chat.');
    });

    test('LRU cache is bounded and revisiting a draft keeps it recent', () {
      final composer = ChatComposerController(maximumDrafts: 3);
      addTearDown(composer.dispose);
      for (final id in ['a', 'b', 'c']) {
        composer.selectChat(id);
        composer.textController.text = '$id draft';
      }
      composer.selectChat('a');
      composer.selectChat('d');
      composer.textController.text = 'd draft';
      expect(composer.cachedDraftCount, 3);
      composer.selectChat('a');
      expect(composer.textController.text, 'a draft');
      composer.selectChat('b');
      expect(composer.textController.text, isEmpty);
      expect(composer.cachedDraftCount, 3);
    });

    test('tickets ignore caret moves but protect text edits and edit-undo ABA',
        () {
      final composer = ChatComposerController();
      addTearDown(composer.dispose);
      composer.textController.text = 'Original';
      final caretTicket = composer.takeTicket();
      composer.textController.selection =
          const TextSelection.collapsed(offset: 2);
      composer.accept(caretTicket);
      expect(composer.textController.text, isEmpty);
      composer.textController.text = 'Original';
      final oldTicket = composer.takeTicket();
      composer.textController.text = 'Newer';
      composer.textController.text = 'Original';
      composer.accept(oldTicket);
      expect(composer.textController.text, 'Original');
      composer.clear();
      composer.textController.text = 'Original';
      composer.accept(oldTicket);
      expect(composer.textController.text, 'Original',
          reason:
              'A ticket from an earlier session cannot clear matching text.');
    });
  });

  group('View-model drafts and send admission', () {
    late _Chats chats;
    late _Users users;
    late _Limiter limiter;
    late ChatViewModel model;
    final a = Chat(id: 'a', title: 'A');
    final b = Chat(id: 'b', title: 'B');

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SharedPreferencesHelper.init();
      chats = _Chats();
      users = _Users();
      limiter = _Limiter();
      model = ChatViewModel(
        chatUseCase: chats,
        authUseCase: _Auth(),
        userUserCase: users,
        chatLimiter: limiter,
      );
      await model.checkAuthStatus();
    });
    tearDown(() => model.dispose());

    test('direct selection and notify paths keep New/A/B drafts separate', () {
      model.composerTextController.text = 'New raw\n  ';
      model.selectedChat = a;
      model.composerTextController.text = 'A raw  ';
      model.selectedChat = b;
      model.notifyListeners();
      model.composerTextController.text = 'B raw';
      model.onTapNewChat();
      expect(model.composerTextController.text, 'New raw\n  ');
      model.selectedChat = a;
      expect(model.composerTextController.text, 'A raw  ');
      model.selectedChat = b;
      expect(model.composerTextController.text, 'B raw');
      expect(SharedPreferencesHelper.localStorage.getKeys(), isEmpty,
          reason: 'Draft contents remain memory-only.');
    });

    test('late message loads cannot overwrite the selected conversation draft',
        () async {
      final loadA = Completer<List<Message>>();
      final loadB = Completer<List<Message>>();
      chats.loadMessages =
          (chat) => chat.id == a.id ? loadA.future : loadB.future;
      final first = model.selectChat(a);
      model.composerTextController.text = 'A draft';
      final second = model.selectChat(b);
      model.composerTextController.text = 'B draft';
      loadB.complete([]);
      await second;
      loadA.complete([]);
      await first;
      expect(model.selectedChat?.id, b.id);
      expect(model.composerTextController.text, 'B draft');
      model.selectedChat = a;
      expect(model.composerTextController.text, 'A draft');
    });

    test('accepted unchanged draft clears while the sent prompt stays trimmed',
        () async {
      model.selectedChat = a;
      model.composerTextController.text = '  Question A\n ';
      final gate = Completer<bool>();
      limiter.pending.add(gate);
      final send = model.sendComposerMessage();
      expect(model.composerTextController.text, '  Question A\n ');
      gate.complete(false);
      await send;
      expect(model.composerTextController.text, isEmpty);
      expect(chats.sent.single.chatId, a.id);
      expect(chats.sent.single.prompts, ['Question A']);
    });

    test(
        'direct selection retires an earlier message load and preserves drafts',
        () async {
      final loadA = Completer<List<Message>>();
      chats.loadMessages = (_) => loadA.future;
      final loading = model.selectChat(a);
      model.composerTextController.text = 'A unfinished';
      model.selectedChat = b;
      model.composerTextController.text = 'B unfinished';
      loadA.complete([Message(role: 'user', content: 'A server content')]);
      await loading;
      expect(model.selectedChat?.id, b.id);
      expect(model.messages, isEmpty);
      expect(model.isLoadingMessages, isFalse);
      expect(model.composerTextController.text, 'B unfinished');
      model.selectedChat = a;
      expect(model.composerTextController.text, 'A unfinished');
    });

    test('new text typed during admission survives acceptance of the old draft',
        () async {
      model.selectedChat = a;
      model.composerTextController.text = 'Original';
      final gate = Completer<bool>();
      limiter.pending.add(gate);
      final send = model.sendComposerMessage();
      model.composerTextController.text = '  Follow-up\n ';
      gate.complete(false);
      await send;
      expect(chats.sent.single.prompts, ['Original']);
      expect(model.composerTextController.text, '  Follow-up\n ');
    });

    test(
        'limit denial and admission failure retain drafts; retry may accept them',
        () async {
      model.selectedChat = a;
      model.composerTextController.text = '  Keep me  ';
      final denied = Completer<bool>();
      limiter.pending.add(denied);
      final first = model.sendComposerMessage();
      denied.complete(true);
      await first;
      expect(model.composerTextController.text, '  Keep me  ');
      expect(chats.sent, isEmpty);
      final failed = Completer<bool>();
      limiter.pending.add(failed);
      final second = model.sendComposerMessage();
      failed.completeError(StateError('Admission unavailable'));
      await second;
      expect(model.composerTextController.text, '  Keep me  ');
      final notice = model.activeError!;
      expect(notice.hasRetry, isTrue);
      await model.retryError(notice.id);
      expect(chats.sent.single.prompts, ['Keep me']);
      expect(model.composerTextController.text, isEmpty);
    });

    test('switching during admission cancels A and permits a pending B send',
        () async {
      model.selectedChat = a;
      model.composerTextController.text = 'A original';
      final admissionA = Completer<bool>();
      final admissionB = Completer<bool>();
      limiter.pending.addAll([admissionA, admissionB]);
      final first = model.sendComposerMessage();
      model.selectedChat = b;
      model.composerTextController.text = 'B original';
      final second = model.sendComposerMessage();
      expect(limiter.calls, 2);
      admissionA.complete(false);
      await first;
      expect(model.composerTextController.text, 'B original');
      expect(chats.sent, isEmpty);
      admissionB.complete(false);
      await second;
      expect(chats.sent.single.chatId, b.id);
      expect(chats.sent.single.prompts, ['B original']);
      model.selectedChat = a;
      expect(model.composerTextController.text, 'A original');
    });

    test(
        'logout/relogin invalidates pending sends even when chat IDs are reused',
        () async {
      model.selectedChat = a;
      model.composerTextController.text = 'Private A';
      final oldSession = model.chatSessionKey;
      final admissionA = Completer<bool>();
      final admissionB = Completer<bool>();
      limiter.pending.addAll([admissionA, admissionB]);
      final first = model.sendComposerMessage();
      final logout = model.clearChatStateOnLogout();
      expect(model.chatSessionKey, isNot(oldSession));
      expect(model.composerTextController.text, isEmpty);
      await logout;
      users.current = User(id: 'account-b', email: 'b@example.test');
      await model.checkAuthStatus();
      model.selectedChat = a;
      model.composerTextController.text = 'Private B';
      final second = model.sendComposerMessage();
      admissionA.complete(false);
      await first;
      expect(model.composerTextController.text, 'Private B');
      expect(chats.sent, isEmpty);
      admissionB.complete(false);
      await second;
      expect(chats.sent.single.prompts, ['Private B']);
      model.onTapNewChat();
      expect(model.composerTextController.text, isEmpty);
    });

    test(
        'actual owner changes clear drafts and session tokens have stable equality',
        () async {
      model.composerTextController.text = 'New private';
      model.selectedChat = a;
      model.composerTextController.text = 'A private';
      final ownerA = model.chatSessionKey;
      expect(model.chatSessionKey, ownerA);
      users.current = User(id: 'account-b', email: 'b@example.test');
      await model.checkAuthStatus();
      expect(model.chatSessionKey, isNot(ownerA));
      expect(model.composerTextController.text, isEmpty);
      model.selectedChat = a;
      expect(model.composerTextController.text, isEmpty);
      model.composerTextController.text = 'Direct fake owner draft';
      final ownerB = model.chatSessionKey;
      model.user = User(id: 'account-c', email: 'c@example.test');
      model.notifyListeners();
      expect(model.chatSessionKey, isNot(ownerB));
      expect(model.composerTextController.text, isEmpty);
    });

    test(
        'accepted New chat moves new follow-up text without resurrecting prompt',
        () async {
      final created = Completer<Chat>();
      chats.create = (_) => created.future;
      model.composerTextController.text = 'Original New prompt';
      final send = model.sendComposerMessage();
      // Admission completes before createChat is entered.
      while (chats.created == 0) {
        await Future<void>.value();
      }
      expect(model.composerTextController.text, isEmpty);
      model.composerTextController.value = const TextEditingValue(
          text: '  Newly typed follow-up  ',
          selection: TextSelection.collapsed(offset: 8));
      created.complete(Chat(id: 'created', title: 'Original New prompt'));
      await send;
      expect(model.selectedChat?.id, 'created');
      expect(model.composerTextController.text, '  Newly typed follow-up  ');
      expect(model.composerTextController.selection.baseOffset, 8);
      model.onTapNewChat();
      expect(model.composerTextController.text, isEmpty);
      model.selectedChat = Chat(id: 'created', title: 'Created');
      expect(model.composerTextController.text, '  Newly typed follow-up  ');
    });

    test('late created-chat list refresh cannot switch away from B', () async {
      final list = Completer<List<Chat>>();
      chats.loadChats = () => list.future;
      model.composerTextController.text = 'Create A';
      final send = model.sendComposerMessage();
      while (model.selectedChat == null) {
        await Future<void>.value();
      }
      model.composerTextController.text = 'Created-chat follow-up';
      model.selectedChat = b;
      model.composerTextController.text = 'B follow-up';
      list.complete([]);
      await send;
      expect(model.selectedChat?.id, b.id);
      expect(model.composerTextController.text, 'B follow-up');
      expect(chats.sent, isEmpty);
    });

    test('deletion removes only a successfully deleted chat draft', () async {
      model.selectedChat = a;
      model.composerTextController.text = 'A draft';
      model.selectedChat = b;
      model.composerTextController.text = 'B draft';
      chats.failDelete = true;
      await model.deleteChat(a);
      model.selectedChat = a;
      expect(model.composerTextController.text, 'A draft');
      chats.failDelete = false;
      await model.deleteChat(a);
      expect(model.selectedChat, isNull);
      model.selectedChat = a;
      expect(model.composerTextController.text, isEmpty);
      model.selectedChat = b;
      expect(model.composerTextController.text, 'B draft');
    });

    test(
        'disposal clears private composer text and invalidates pending admission',
        () async {
      model.selectedChat = a;
      final controller = model.composerTextController;
      controller.text = 'Private pending draft';
      final admission = Completer<bool>();
      limiter.pending.add(admission);
      final send = model.sendComposerMessage();
      model.dispose();
      expect(controller.text, isEmpty);
      admission.complete(false);
      await send;
      expect(chats.sent, isEmpty);
    });
  });
}
