// Domain exceptions for git operations.

class GitException implements Exception {
  const GitException(this.message);
  final String message;
  @override
  String toString() => 'GitException: $message';
}

class GitNoUpstreamException extends GitException {
  const GitNoUpstreamException(String branch) : super('No upstream branch for $branch');
}

class GitAuthException extends GitException {
  const GitAuthException() : super('Authentication failed');
}

class GitConflictException extends GitException {
  const GitConflictException() : super('Merge conflict detected');
}
