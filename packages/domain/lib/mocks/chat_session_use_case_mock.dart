

import 'package:mockito/mockito.dart';

import '../entities/chat_session.dart';
import '../use_cases/chat_session_use_case.dart';

class MockChatSessionUseCase extends Mock implements ChatSessionUseCase {
  @override
  Future<List<ChatSession>> getAllSessions() {
    return super.noSuchMethod(
      Invocation.method(#getAllSessions, []),
      returnValue: Future.value(<ChatSession>[]), // Return an empty Future<List<ChatSession>>
      returnValueForMissingStub: Future.value(<ChatSession>[]), // Provide a default empty Future
    );
  }
}
