sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.originalError});

  final String message;
  final String? code;
  final Object? originalError;

  @override
  String toString() => 'AppException: $message';
}

final class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    this.statusCode,
  });

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
  const FileSystemException(
    super.message, {
    super.code,
    super.originalError,
    this.path,
  });

  final String? path;
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}
