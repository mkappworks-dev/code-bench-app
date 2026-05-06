sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.originalError});

  final String message;
  final String? code;
  final Object? originalError;

  @override
  String toString() => 'AppException: $message';
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError, this.statusCode});

  final int? statusCode;
}

final class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

final class ParseException extends AppException {
  const ParseException(super.message, {super.code, super.originalError});
}

final class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});
}

final class FileSystemException extends AppException {
  const FileSystemException(super.message, {super.code, super.originalError, this.path});

  final String? path;
}

/// Thrown when a file or directory lookup finds nothing at the given path.
/// Subclass of [FileSystemException] so callers that only care about "any I/O
/// error" can still catch the parent type.
final class FileNotFoundException extends FileSystemException {
  const FileNotFoundException(super.message, {super.code, super.originalError, super.path});
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}

String userMessage(Object error, {String fallback = 'Something went wrong.'}) {
  if (error is AppException) return error.message;
  return fallback;
}
