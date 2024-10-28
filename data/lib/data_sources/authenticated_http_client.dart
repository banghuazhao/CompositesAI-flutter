// lib/data/datasources/authenticated_http_client.dart

import 'package:domain/repositories_abstract/token_provider.dart';
import 'package:http/http.dart' as http;

import '../core/exceptions.dart';

class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final TokenProvider _tokenProvider;

  AuthenticatedHttpClient(this._inner, this._tokenProvider);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _tokenProvider.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    var response = await _inner.send(request);

    if (response.statusCode == 401) {
      // Token is invalid or expired, delete it
      await _tokenProvider.deleteToken();

      // Notify the app or handle as needed
      throw UnauthenticatedException('Token expired');
    }

    return response;
  }
}
