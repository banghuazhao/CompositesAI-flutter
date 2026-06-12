import 'dart:async';

class ChatSocketSession {
  String get sessionId => '';

  Stream<Map<String, dynamic>> get events => const Stream.empty();

  static Future<ChatSocketSession?> connect({
    required Uri webBaseUri,
    required String token,
  }) async {
    return null;
  }

  Future<void> close() async {}
}
