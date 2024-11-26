// lib/domain/providers/token_provider.dart

abstract class TokenProvider {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
}
