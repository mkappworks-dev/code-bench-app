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

final class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}

/// Returns a user-facing message from any error:
/// - AppException → its own .message
/// - Everything else → the fallback string
String userMessage(Object error, {String fallback = 'Something went wrong.'}) {
  if (error is AppException) return error.message;
  return fallback;
}

/// Converts a Dio HTTP status code into a short, actionable user message.
/// Falls back to [providerName] + "request failed" for unknown codes.
String networkErrorMessage(int? statusCode, {required String providerName}) => switch (statusCode) {
  401 => 'Invalid API key — go to Settings → Providers to update it.',
  403 => 'Access denied — check your API key permissions.',
  429 => 'Rate limit reached — try again in a moment.',
  500 || 502 || 503 || 504 => '$providerName is temporarily unavailable — try again.',
  _ => '$providerName request failed.',
};
