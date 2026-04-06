import 'entities/message.dart';
import 'entities/chat.dart';
import 'chat_repository.dart';

abstract class ChatUseCase {
  Future<List<Chat>> fetchChats();

  Future<List<Message>> fetchMessages(Chat chat);

  Future<Chat> createChat(Message message);

  Future<void> deleteChat(Chat chat);

  Future<Chat> updateChatTitle(Chat chat, String newTitle);

  Future<Chat> togglePin(Chat chat);

  Stream<String> sendMessages(List<Message> messages, Chat chat, String id);

  Future<String> shareChat(Chat chat);

  Future<void> completeSendMessages(
      List<Message> messages, Chat chat, String id);

  Future<void> persistMessages(List<Message> messages, Chat chat);

  Future<void> updateChatMessage(Message message, Chat chat);

  /// Create or update rating feedback for an assistant message.
  /// Returns feedback id (stored into message.feedbackId).
  Future<String> submitMessageFeedback({
    required Chat chat,
    required Message message,
    required int goodBadRating, // 1 for Good, -1 for Bad
    required int detailsRating, // 1..10 from UI
    required List<String> reasons, // selected chips
    String? comment, // optional
    required int messageIndex, // backend meta.message_index (1-based)
  });
}

class ChatUseCaseImpl implements ChatUseCase {
  final ChatRepository repository;

  ChatUseCaseImpl({required this.repository});

  @override
  Future<List<Chat>> fetchChats() async {
    return repository.fetchChats();
  }

  @override
  Future<List<Message>> fetchMessages(Chat chat) async {
    return repository.fetchMessages(chat);
  }

  @override
  Future<Chat> createChat(Message message) {
    return repository.createChat(message);
  }

  @override
  Future<void> deleteChat(Chat chat) async {
    return repository.deleteChat(chat);
  }

  @override
  Future<Chat> updateChatTitle(Chat chat, String newTitle) async {
    return repository.updateChatTitle(chat, newTitle);
  }

  @override
  Future<Chat> togglePin(Chat chat) async {
    return repository.togglePin(chat);
  }

  @override
  Stream<String> sendMessages(List<Message> messages, Chat chat, String id) {
    return repository.sendMessages(messages, chat, id);
  }

  @override
  Future<String> shareChat(Chat chat) async {
    return repository.shareChat(chat);
  }

  @override
  Future<void> completeSendMessages(
      List<Message> messages, Chat chat, String id) async {
    return repository.completeSendMessages(messages, chat, id);
  }

  @override
  Future<void> persistMessages(
      List<Message> messages, Chat chat) async {
    return repository.persistMessages(messages, chat);
  }

  @override
  Future<void> updateChatMessage(Message message, Chat chat) async {
    return repository.updateChatMessage(message, chat);
  }

  @override
  Future<String> submitMessageFeedback({
    required Chat chat,
    required Message message,
    required int goodBadRating,
    required int detailsRating,
    required List<String> reasons,
    String? comment,
    required int messageIndex,
  }) async {
    final Map<String, dynamic> commonForm = {
      'type': 'rating',
      'data': {
        'rating': goodBadRating,
        'model_id': message.model,
        'sibling_model_ids': message.models,
        'tags': reasons,
        'reason': reasons.isEmpty ? 'Other' : reasons.join(', '),
        'comment': comment ?? '',
        'details': {
          'rating': detailsRating,
        },
      },
      'meta': {
        'arena': false,
        'chat_id': chat.id,
        'message_id': message.id,
        'message_index': messageIndex, // 1-based
        'tags': reasons,
        'model_id': message.model,
        // Backend allows extra meta fields; best-effort.
        'base_models': {for (final m in message.models) m: null},
      },
    };

    if (message.feedbackId == null) {
      // Create: must include snapshot.chat (ChatResponse verbatim).
      final snapshotChat = await repository.fetchChatSnapshot(chat.id);
      final Map<String, dynamic> createForm = {
        ...commonForm,
        'snapshot': {
          'chat': snapshotChat,
        },
      };

      final created = await repository.createFeedback(createForm);
      final feedbackId = created.id.trim();
      if (feedbackId.isEmpty) {
        throw Exception('Feedback created but id missing.');
      }
      return feedbackId;
    }

    // Update: omit snapshot to keep old snapshot on backend.
    final Map<String, dynamic> updateForm = commonForm;

    final updated = await repository.updateFeedback(
      message.feedbackId!,
      updateForm,
    );
    final feedbackId = updated.id.trim();
    if (feedbackId.isEmpty) {
      throw Exception('Feedback updated but id missing in response.');
    }
    return feedbackId;
  }
}
