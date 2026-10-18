import 'package:http/http.dart' as http;
import 'package:infrastructure/token_provider.dart';

class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final TokenProvider _tokenProvider;
  final String? _sessionToken;
  final bool Function()? _isActive;

  AuthenticatedHttpClient(this._inner, this._tokenProvider)
      : _sessionToken = null,
        _isActive = null;

  AuthenticatedHttpClient._forSession(
      this._inner, this._tokenProvider, this._sessionToken, this._isActive);

  /// Pins related requests to one session without owning the shared transport.
  /// Each send checks that session is still current before using its token.
  Future<AuthenticatedHttpClient> forCurrentSession({
    bool Function()? isActive,
  }) async {
    bool active() => (_isActive?.call() ?? true) && (isActive?.call() ?? true);
    if (!active()) throw const AuthenticatedSessionChangedException();
    final token = await _tokenProvider.getToken();
    if (token == null ||
        token.trim().isEmpty ||
        !active() ||
        (_sessionToken != null && token != _sessionToken)) {
      throw const AuthenticatedSessionChangedException();
    }
    return AuthenticatedHttpClient._forSession(
        _inner, _tokenProvider, token, active);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_isActive?.call() == false) {
      throw const AuthenticatedSessionChangedException();
    }
    final currentToken = await _tokenProvider.getToken();
    if (_isActive?.call() == false ||
        (_sessionToken != null && currentToken != _sessionToken)) {
      throw const AuthenticatedSessionChangedException();
    }
    final token = _sessionToken ?? currentToken;
    final hasToken = token != null && token.trim().isNotEmpty;
    if (hasToken) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    var response = await _inner.send(request);

    if (response.statusCode == 401 && hasToken) {
      await _tokenProvider.deleteTokenIfMatches(token);
    }

    return response;
  }
}

class AuthenticatedSessionChangedException implements Exception {
  const AuthenticatedSessionChangedException();

  @override
  String toString() => 'Your session changed. Please sign in again.';
}
