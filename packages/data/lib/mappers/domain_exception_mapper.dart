import 'dart:convert';

import 'package:domain/entities/domain_exceptions.dart';
import 'package:http/http.dart';

/// Helper function to map server errors to domain-specific exceptions
DomainException mapServerErrorToDomainException(Response response) {
  final statusCode = response.statusCode;
  final responseData = jsonDecode(response.body);
  final message = responseData['message'];

  switch (statusCode) {
    case 400:
      return BadRequestException(message ?? 'Bad Request');
    case 401:
      return UnauthorizedException(message ?? 'Unauthorized. Access Token is expired or invalid.');
    case 403:
      return ForbiddenException(message ?? 'Forbidden');
    case 404:
      return NotFoundException(message ?? 'Not Found');
    case 409:
      return ResourceAlreadyExistsException(message ?? 'Resource already exists');
    case 422:
      return UnprocessableEntityException(message ?? 'Unprocessable Entity');
    case 429:
      return TooManyRequestsException(message ?? 'Too Many Requests');
    case 500:
      return InternalServerErrorException(message ?? 'Internal Server Error');
    default:
      return InternalServerErrorException(message ?? 'Server error with status code $statusCode');
  }
}
