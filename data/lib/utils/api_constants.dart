import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const String baseUrl = 'https://api.openai.com/v1';
  static const String chatCompletionsEndpoint = '$baseUrl/chat/completions';
  static String apiKey = dotenv.env['OPENAI_API_KEY'] ?? "";
}
