import 'package:domain/chat/entities/message.dart';

/// Immutable text from one explicitly linked, uniquely loaded exchange.
class ChatExchangeSnapshot {
  ChatExchangeSnapshot._(this.question, this.answer)
      : questionText = question.content,
        answerText = answer.content,
        _parentId = answer.parentId,
        _questionTimestamp = question.timestamp,
        _answerTimestamp = answer.timestamp;

  final Message question;
  final Message answer;
  final String questionText;
  final String answerText;
  final String? _parentId;
  final int _questionTimestamp;
  final int _answerTimestamp;

  static ChatExchangeSnapshot? resolve({
    required List<Message> messages,
    required Message answer,
  }) {
    final parentId = answer.parentId;
    if (answer.role != 'assistant' ||
        answer.id.trim().isEmpty ||
        answer.content.trim().isEmpty ||
        parentId == null ||
        parentId.trim().isEmpty) {
      return null;
    }
    var answerIndex = -1;
    var questionIndex = -1;
    var answerMatches = 0;
    var parentMatches = 0;
    for (var index = 0; index < messages.length; index++) {
      final message = messages[index];
      if (message.id == answer.id) {
        answerMatches++;
        if (identical(message, answer)) answerIndex = index;
      }
      if (message.id == parentId) {
        parentMatches++;
        questionIndex = index;
      }
    }
    if (answerMatches != 1 ||
        parentMatches != 1 ||
        answerIndex < 0 ||
        questionIndex < 0 ||
        questionIndex >= answerIndex) {
      return null;
    }
    final question = messages[questionIndex];
    if (question.role != 'user' ||
        (question.timestamp > 0 &&
            answer.timestamp > 0 &&
            question.timestamp > answer.timestamp)) {
      return null;
    }
    return ChatExchangeSnapshot._(question, answer);
  }

  bool matches(ChatExchangeSnapshot other) =>
      identical(question, other.question) &&
      identical(answer, other.answer) &&
      questionText == other.questionText &&
      answerText == other.answerText &&
      _parentId == other._parentId &&
      _questionTimestamp == other._questionTimestamp &&
      _answerTimestamp == other._answerTimestamp;

  String toMarkdown({
    String questionLabel = 'Question',
    String answerLabel = 'Answer',
  }) =>
      '## $questionLabel\n\n$questionText\n\n## $answerLabel\n\n$answerText';
}
