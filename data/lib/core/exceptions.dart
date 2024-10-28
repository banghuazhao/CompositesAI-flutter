class UnauthenticatedException implements Exception {
  final String message;

  UnauthenticatedException(this.message);

  @override
  String toString() => 'UnauthenticatedException: $message';
}

class ServerException implements Exception {
  final String message;

  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}
