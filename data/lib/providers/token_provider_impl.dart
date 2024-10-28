// lib/data/providers/token_provider_impl.dart

import 'package:domain/repositories_abstract/token_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenProviderImpl implements TokenProvider {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'accessToken';

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
