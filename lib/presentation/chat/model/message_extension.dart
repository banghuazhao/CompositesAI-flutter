import 'package:domain/domain.dart';

extension MessageExtension on Message {
  bool get isUserMessage {
    return role == 'user';
  }

  bool get isAssistantMessage {
    return role == 'assistant';
  }
}