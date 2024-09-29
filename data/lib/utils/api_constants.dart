import 'chat_config.dart';

class ApiConstants {
  static const String baseUrl = 'https://api.openai.com/v1';
  static const String chatCompletionsEndpoint = '$baseUrl/chat/completions';
  static String apiKey = ChatConfig.apiKey;
}
