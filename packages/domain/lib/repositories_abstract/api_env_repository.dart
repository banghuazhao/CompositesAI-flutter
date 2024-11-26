abstract class APIEnvironmentRepository {
  Future<String> getCurrentEnvironment();
  Future<void> setEnvironment(String environment) ;
  Future<String> getBaseUrl();
}