// lib/domain/exceptions/domain_exceptions.dart
abstract class DomainException implements Exception {
  final String message;
  DomainException(this.message);
  @override
  String toString() => '$runtimeType: $message';
}

class BadRequestException extends DomainException {
  BadRequestException([String message = 'Bad Request']) : super(message);
}

class UnauthorizedException extends DomainException {
  UnauthorizedException([String message = 'Unauthorized']) : super(message);
}

class ForbiddenException extends DomainException {
  ForbiddenException([String message = 'Forbidden']) : super(message);
}

class NotFoundException extends DomainException {
  NotFoundException([String message = 'Not Found']) : super(message);
}

class ResourceAlreadyExistsException extends DomainException {
  ResourceAlreadyExistsException([String message = 'Resource already exists']) : super(message);
}

class UnprocessableEntityException extends DomainException {
  UnprocessableEntityException([String message = 'Unprocessable Entity']) : super(message);
}

class TooManyRequestsException extends DomainException {
  TooManyRequestsException([String message = 'Too Many Requests']) : super(message);
}

class InternalServerErrorException extends DomainException {
  InternalServerErrorException([String message = 'Internal Server Error']) : super(message);
}

// Add additional exceptions here
