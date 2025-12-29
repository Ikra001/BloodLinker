abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException(
    String message, {
    this.fieldErrors = const {},
    String? code,
  }) : super(message, code: code);
}

class DatabaseException extends AppException {
  const DatabaseException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

class LocationException extends AppException {
  const LocationException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}
