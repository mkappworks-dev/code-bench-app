import 'package:freezed_annotation/freezed_annotation.dart';

part 'claude_cli_failure.freezed.dart';

/// Typed failure union for Claude Code CLI inference transport operations.
///
/// Surfaced to widgets via `AsyncError` on `ClaudeCliActions`-family notifiers
/// (detection, auth probe, streaming). Widgets `switch` on this union to
/// render user-facing messages without importing datasource exception types.
@freezed
sealed class ClaudeCliFailure with _$ClaudeCliFailure {
  const factory ClaudeCliFailure.notInstalled() = ClaudeCliNotInstalled;
  const factory ClaudeCliFailure.unauthenticated() = ClaudeCliUnauthenticated;
  const factory ClaudeCliFailure.crashed({required int exitCode, required String stderr}) = ClaudeCliCrashed;
  const factory ClaudeCliFailure.timedOut() = ClaudeCliTimedOut;
  const factory ClaudeCliFailure.streamParseFailed({required String line, required Object error}) =
      ClaudeCliStreamParseFailed;
  const factory ClaudeCliFailure.cancelled() = ClaudeCliCancelled;
  const factory ClaudeCliFailure.unknown(Object error) = ClaudeCliUnknown;
}
