/// Outcome of an `ApplyService.readFileContent` call. Distinguishes
/// "file not present yet" (legitimate new-file apply) from "could not read"
/// (permission denied, IO failure) so the UI can render an error state on
/// the latter instead of silently treating it as a clean creation.
sealed class FileReadResult {
  const FileReadResult();
  const factory FileReadResult.content(String text) = FileReadContent;
  const factory FileReadResult.notFound() = FileReadNotFound;
  const factory FileReadResult.error(String message) = FileReadError;
}

class FileReadContent extends FileReadResult {
  const FileReadContent(this.text);
  final String text;
}

class FileReadNotFound extends FileReadResult {
  const FileReadNotFound();
}

class FileReadError extends FileReadResult {
  const FileReadError(this.message);
  final String message;
}
