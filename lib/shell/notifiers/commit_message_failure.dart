import 'package:freezed_annotation/freezed_annotation.dart';

part 'commit_message_failure.freezed.dart';

@freezed
sealed class CommitMessageFailure with _$CommitMessageFailure {
  /// The AI call for generating a commit message failed (offline, bad key,
  /// rate limit). The widget proceeds with the fallback message.
  const factory CommitMessageFailure.commitMessageUnavailable() = CommitMessageUnavailable;

  /// The AI call for generating PR title / body failed. The widget proceeds
  /// with the branch-name fallback title and an empty body.
  const factory CommitMessageFailure.prContentUnavailable() = PrContentUnavailable;

  /// Non-network AI failures — missing/invalid API key, parse errors,
  /// provider-specific failures not wrapped as [NetworkException]. The widget
  /// still proceeds with fallback text, but the user is told the AI call
  /// failed so they know why their commit message is generic.
  const factory CommitMessageFailure.unknown(Object error) = CommitMessageUnknown;
}
