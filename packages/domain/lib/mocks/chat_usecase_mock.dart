import 'package:mockito/mockito.dart';

import '../entities/chat_session.dart';
import '../entities/message.dart';
import '../usecases/chat_usecase.dart';

class MockChatUseCase extends Mock implements ChatUseCase {
  @override
  Stream<Message> sendMessage(Message newMessage, ChatSession session) {
    return super.noSuchMethod(
      Invocation.method(#sendMessage, [newMessage, session]),
      returnValue: Stream<Message>.empty(), // Provide a default empty Stream
      returnValueForMissingStub: Stream<Message>.empty(),
    );
  }
}
