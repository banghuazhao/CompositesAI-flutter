import 'package:swiftcomp/data/core/chat_config.dart';

class ApiConstants {
  static const String baseUrl = 'https://api.openai.com/v1';
  static const String chatEndpoint = '$baseUrl/chat/completions';
  static String apiKey = ChatConfig.apiKey;
}
