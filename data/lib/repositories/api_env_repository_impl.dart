import 'dart:async';

import 'package:domain/repositories_abstract/api_env_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class APIEnvironmentRepositoryImpl implements APIEnvironmentRepository {
  static const String _environmentKey = 'current_environment';

  @override
  Future<void> setEnvironment(String environment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_environmentKey, environment);
  }

  @override
  Future<String> getCurrentEnvironment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_environmentKey) ?? "production";
  }


  @override
  Future<String> getBaseUrl() async  {
    final prefs = await SharedPreferences.getInstance();
    final String currentEnvironment = prefs.getString(_environmentKey) ?? "production";
    if (currentEnvironment == "production") {
      return "http://compositesai.eba-dxj2wppi.us-west-2.elasticbeanstalk.com/api";
    } else {
      return "http://localhost:8080/api";
    }
  }
}
