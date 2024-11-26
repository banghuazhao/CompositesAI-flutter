import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class APIEnvironment {
  static const String _environmentKey = 'current_environment';

  Future<void> setEnvironment(String environment) async {
    if (environment != 'development' && environment != 'production') {
      throw ArgumentError('Invalid environment: $environment');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_environmentKey, environment);
  }

  Future<String> getCurrentEnvironment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_environmentKey) ?? "production";
  }

  Future<String> getBaseUrl() async  {
    final prefs = await SharedPreferences.getInstance();
    final String currentEnvironment = prefs.getString(_environmentKey) ?? "production";
    if (currentEnvironment == "production") {
      return "https://composites-ai-backend-b303708f8d96.herokuapp.com/api";
    } else {
      return "http://localhost:8080/api";
    }
  }
}
