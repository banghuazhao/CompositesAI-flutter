import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenProvider {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'accessToken';
  // All providers access the same storage key. Keep a conditional removal and
  // a newly completed sign-in write in order, including across provider instances.
  static Future<void> _storageOperations = Future<void>.value();

  static Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _storageOperations.then((_) => operation());
    _storageOperations =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> saveToken(String token) => _serialize(
        () => _secureStorage.write(key: _tokenKey, value: token),
      );

  Future<String?> getToken() =>
      _serialize(() => _secureStorage.read(key: _tokenKey));

  Future<void> deleteToken() =>
      _serialize(() => _secureStorage.delete(key: _tokenKey));

  /// Removes and returns the departing session in one storage operation.
  /// A new sign-in cannot write between the read and deletion.
  Future<String?> takeToken() => _serialize(() async {
        final token = await _secureStorage.read(key: _tokenKey);
        if (token != null) await _secureStorage.delete(key: _tokenKey);
        return token;
      });

  /// A request may only invalidate the session it actually used. A late 401
  /// from an old account must not delete a newer account's saved session.
  Future<bool> deleteTokenIfMatches(String expectedToken) =>
      _serialize(() async {
        if (await _secureStorage.read(key: _tokenKey) != expectedToken) {
          return false;
        }
        await _secureStorage.delete(key: _tokenKey);
        return true;
      });
}
