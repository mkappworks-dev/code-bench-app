import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_auth_failure.freezed.dart';

@freezed
sealed class GitHubAuthFailure with _$GitHubAuthFailure {
  /// The stored token was rejected by GitHub (revoked or expired server-side).
  /// The user has been signed out and must reconnect.
  const factory GitHubAuthFailure.tokenRevoked() = GitHubAuthTokenRevoked;

  /// The initial device-code request failed (network down, bad client_id, etc.).
  const factory GitHubAuthFailure.requestFailed(String message) = GitHubAuthRequestFailed;

  /// The polling loop failed with a terminal OAuth error or network issue
  /// that exhausted the device code's lifetime.
  const factory GitHubAuthFailure.pollFailed(String message) = GitHubAuthPollFailed;

  /// Secure-storage cleanup failed during sign-out. The user may still have
  /// a live credential on disk — they should try signing out again.
  const factory GitHubAuthFailure.signOutFailed(String message) = GitHubAuthSignOutFailed;

  const factory GitHubAuthFailure.unknown(Object error) = GitHubAuthUnknown;
}
