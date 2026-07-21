import 'dart:async';

import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_configuration.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/chat_folder.dart';
import 'package:domain/chat/entities/chat_knowledge.dart';
import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:domain/chat/entities/chat_tag.dart';
import 'package:domain/chat/entities/chat_tool.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/util/others.dart';

class FakeChatUseCase extends Fake implements ChatUseCase {
  final Map<String, Future<List<Message>>> messageLoads = {};
  List<ChatTool> toolsToFetch = <ChatTool>[];
  List<ChatModel> modelsToFetch = <ChatModel>[];
  ChatConfiguration configurationToFetch = const ChatConfiguration();
  Future<Chat> Function(Message message)? createChatHandler;
  Future<List<Chat>> Function({int? page})? fetchChatsHandler;
  Stream<ChatStreamEvent> Function(
    List<Message> messages,
    Chat chat,
    String id, {
    List<String> toolIds,
    ChatModel? model,
  })? sendMessagesHandler;

  int createChatCalls = 0;
  int sendMessagesCalls = 0;

  @override
  Future<List<Message>> fetchMessages(Chat chat) {
    return messageLoads[chat.id] ?? Future.value(<Message>[]);
  }

  @override
  Future<Chat> createChat(Message message) {
    createChatCalls++;
    final handler = createChatHandler;
    if (handler == null) throw StateError('createChatHandler not set');
    return handler(message);
  }

  @override
  Future<List<Chat>> fetchChats({int? page}) {
    return fetchChatsHandler?.call(page: page) ?? Future.value(<Chat>[]);
  }

  @override
  Future<List<Chat>> fetchPinnedChats() async => <Chat>[];

  @override
  Future<List<ChatTag>> fetchAllTags() async => <ChatTag>[];

  @override
  Future<List<ChatFolder>> fetchFolders() async => <ChatFolder>[];

  @override
  Stream<ChatStreamEvent> sendMessages(
    List<Message> messages,
    Chat chat,
    String id, {
    List<String> toolIds = const [],
    ChatModel? model,
  }) {
    sendMessagesCalls++;
    final handler = sendMessagesHandler;
    if (handler == null) return const Stream<ChatStreamEvent>.empty();
    return handler(
      messages,
      chat,
      id,
      toolIds: toolIds,
      model: model,
    );
  }

  @override
  Future<void> updateChatMessage(Message message, Chat chat) async {}

  @override
  Future<void> persistMessages(List<Message> messages, Chat chat) async {}

  @override
  Future<List<ChatTool>> fetchTools() async => toolsToFetch;

  @override
  Future<List<ChatModel>> fetchModels() async => modelsToFetch;

  @override
  Future<ChatConfiguration> fetchChatConfiguration() async =>
      configurationToFetch;

  @override
  Future<List<ChatKnowledge>> fetchKnowledgeBases() async => <ChatKnowledge>[];

  @override
  Future<ChatFile> uploadChatFile({
    required String name,
    required int size,
    String? path,
    List<int>? bytes,
  }) async {
    return ChatFile(id: 'file-id', name: name, url: '', size: size);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatViewModel', () {
    late FakeChatUseCase chatUseCase;
    late ChatViewModel viewModel;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SharedPreferencesHelper.init();
      chatUseCase = FakeChatUseCase();
      viewModel = ChatViewModel(
        chatUseCase: chatUseCase,
        authUseCase: MockAuthUseCase(),
        userUserCase: MockUserUseCase(),
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('selectChat ignores stale message loads', () async {
      final chatA = Chat(id: 'a', title: 'A');
      final chatB = Chat(id: 'b', title: 'B');
      final completerA = Completer<List<Message>>();
      final completerB = Completer<List<Message>>();

      chatUseCase.messageLoads[chatA.id] = completerA.future;
      chatUseCase.messageLoads[chatB.id] = completerB.future;

      final firstLoad = viewModel.selectChat(chatA);
      final secondLoad = viewModel.selectChat(chatB);

      completerB.complete([Message(role: 'user', content: 'from b')]);
      await secondLoad;

      completerA.complete([Message(role: 'user', content: 'from a')]);
      await firstLoad;

      expect(viewModel.selectedChat?.id, 'b');
      expect(viewModel.messages, hasLength(1));
      expect(viewModel.messages.single.content, 'from b');
      expect(viewModel.isLoadingMessages, false);
    });

    test('sendInputMessage blocks when the daily limit is reached', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      SharedPreferences.setMockInitialValues({
        'chat_last_reset': today,
        'chat_count': 50,
      });

      await viewModel.sendInputMessage('hello');

      expect(viewModel.messages, isEmpty);
      expect(viewModel.errorMessage, 'Daily chat limit reached (50/day)');
      expect(chatUseCase.createChatCalls, 0);
      expect(chatUseCase.sendMessagesCalls, 0);
    });

    test('fetchTools uses the CompositesAI workspace model for non-admin users',
        () async {
      chatUseCase.toolsToFetch = const [
        ChatTool(id: 'tool-a', name: 'Tool A'),
        ChatTool(id: 'tool-b', name: 'Tool B'),
      ];
      chatUseCase.modelsToFetch = [
        ChatModel.fromJson({
          'id': 'composites-ai-2026-02-23',
          'name': 'CompositesAI',
          'meta': {
            'toolIds': ['tool-a'],
            'suggestion_prompts': [
              {'content': 'Composites workspace prompt'},
            ],
          },
        }),
        ChatModel(
          id: 'gpt-4.1',
          name: 'GPT-4.1',
          rawJson: const {'id': 'gpt-4.1'},
          toolIds: const ['tool-b'],
        ),
      ];
      chatUseCase.configurationToFetch = const ChatConfiguration(
        defaultModelIds: ['gpt-4.1'],
        defaultPrompts: ['Web prompt one', 'Web prompt two'],
      );
      viewModel.isLoggedIn = true;

      await viewModel.fetchTools();

      expect(viewModel.selectedModel?.id, 'composites-ai-2026-02-23');
      expect(viewModel.selectedToolIds, {'tool-a'});
      expect(viewModel.defaultQuestions, hasLength(5));
      expect(viewModel.defaultQuestions.first, 'Composites workspace prompt');
      expect(
        viewModel.defaultQuestions.skip(1),
        containsAll(<String>[
          'What are the main differences between carbon-fiber and glass-fiber composites?',
          "How do I estimate a unidirectional composite's longitudinal Young's modulus using the rule of mixtures?",
          'What causes delamination in composite laminates, and how can it be prevented?',
          'How do fiber orientation and stacking sequence affect laminate performance?',
        ]),
      );
    });

    test('model prompt suggestions override global web prompts', () async {
      chatUseCase.modelsToFetch = [
        ChatModel.fromJson({
          'id': 'composites-ai-2026-02-23',
          'name': 'CompositesAI',
          'meta': {
            'suggestion_prompts': [
              {'content': 'Model-specific prompt'},
            ],
          },
        }),
      ];
      chatUseCase.configurationToFetch = const ChatConfiguration(
        defaultModelIds: ['gpt-4.1'],
        defaultPrompts: ['Global prompt'],
      );
      viewModel.isLoggedIn = true;

      await viewModel.fetchTools();

      expect(viewModel.defaultQuestions, hasLength(5));
      expect(viewModel.defaultQuestions.first, 'Model-specific prompt');
    });

    test('suggested prompts are unique and limited to five', () async {
      chatUseCase.modelsToFetch = [
        ChatModel.fromJson({
          'id': 'composites-ai-2026-02-23',
          'name': 'CompositesAI',
          'meta': {
            'suggestion_prompts': [
              {'content': 'Prompt one'},
              {'content': ' prompt one '},
              {'content': 'Prompt two'},
              {'content': 'Prompt three'},
              {'content': 'Prompt four'},
              {'content': 'Prompt five'},
              {'content': 'Prompt six'},
            ],
          },
        }),
      ];
      viewModel.isLoggedIn = true;

      await viewModel.fetchTools();

      expect(viewModel.defaultQuestions, [
        'Prompt one',
        'Prompt two',
        'Prompt three',
        'Prompt four',
        'Prompt five',
      ]);
    });

    test('admin users still start with the configured web default model',
        () async {
      chatUseCase.modelsToFetch = [
        ChatModel.fallback(
          id: 'composites-ai-2026-02-23',
          name: 'CompositesAI',
        ),
        ChatModel.fallback(id: 'gpt-4.1', name: 'GPT-4.1'),
      ];
      chatUseCase.configurationToFetch = const ChatConfiguration(
        defaultModelIds: ['gpt-4.1'],
      );
      viewModel
        ..isLoggedIn = true
        ..user = User(email: 'admin@example.com', isAdmin: true);

      await viewModel.fetchTools();

      expect(viewModel.selectedModel?.id, 'gpt-4.1');
    });

    test('sendInputMessage keeps new chat selected if refreshed list omits it',
        () async {
      final newChat = Chat(id: 'new-chat', title: 'hello');

      chatUseCase.createChatHandler = (_) async => newChat;
      chatUseCase.fetchChatsHandler = ({int? page}) async => <Chat>[];
      chatUseCase.sendMessagesHandler = (
        messages,
        chat,
        id, {
        List<String> toolIds = const [],
        ChatModel? model,
      }) {
        return Stream<ChatStreamEvent>.fromIterable([
          ChatStreamEvent(content: 'response'),
        ]);
      };

      await viewModel.sendInputMessage('hello');

      expect(viewModel.selectedChat?.id, 'new-chat');
      expect(viewModel.chats.map((chat) => chat.id), contains('new-chat'));
      expect(viewModel.messages.last.content, 'response');
    });
  });
}
