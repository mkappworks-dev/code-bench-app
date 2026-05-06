sealed class UpdateException implements Exception {
  const UpdateException([this.message]);
  final String? message;
}

final class UpdateNetworkException extends UpdateException {
  const UpdateNetworkException([super.message]);
}

final class UpdateDownloadException extends UpdateException {
  const UpdateDownloadException([super.message]);
}

final class UpdateInstallException extends UpdateException {
  const UpdateInstallException([super.message]);
}
