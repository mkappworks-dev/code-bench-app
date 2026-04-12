import 'package:freezed_annotation/freezed_annotation.dart';

part 'pr_preflight_result.freezed.dart';

/// Result of [CommitMessageActions.preparePr]. Either all data needed to
/// open the Create PR dialog is ready, or a message explaining why the
/// flow cannot proceed.
@freezed
sealed class PrPreflightResult with _$PrPreflightResult {
  const factory PrPreflightResult.ready({
    required String title,
    required String body,
    required List<String> branches,
    required String owner,
    required String repo,
    required String currentBranch,
  }) = PrPreflightReady;

  const factory PrPreflightResult.failed(String message) = PrPreflightFailed;
}
