import '../repositories_abstract/api_env_repository.dart';

class APIEnvironmentUseCase {
  final APIEnvironmentRepository repository;

  APIEnvironmentUseCase({required this.repository});

  Future<String> getCurrentAPIEnvironment() {
    return repository.getCurrentEnvironment();
  }

  Future<void> changeAPIEnvironment(String environment) async {
    if (environment != 'development' && environment != 'production') {
      throw ArgumentError('Invalid environment: $environment');
    }
    await repository.setEnvironment(environment);
  }

  Future<String> getBaseUrl() {
    return repository.getBaseUrl();
  }
}
