import 'package:freezed_annotation/freezed_annotation.dart';

part 'git_actions_failure.freezed.dart';

@freezed
sealed class GitActionsFailure with _$GitActionsFailure {
  /// Generic git command failure (non-zero exit code).
  const factory GitActionsFailure.gitError(String message) = GitActionsGitError;

  /// The current branch has no upstream configured.
  const factory GitActionsFailure.noUpstream(String branch) = GitActionsNoUpstream;

  /// Remote authentication failed.
  const factory GitActionsFailure.authFailed() = GitActionsAuthFailed;

  /// A merge conflict was detected during pull.
  const factory GitActionsFailure.conflict() = GitActionsConflict;

  /// Fallback for any unrecognised exception type.
  const factory GitActionsFailure.unknown(Object error) = GitActionsUnknownError;
}
