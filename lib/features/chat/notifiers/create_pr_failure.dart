import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_pr_failure.freezed.dart';

@freezed
sealed class CreatePrFailure with _$CreatePrFailure {
  const factory CreatePrFailure.notAuthenticated() = CreatePrNotAuthenticated;

  /// GitHub returned 404 from a repo-scoped endpoint. Almost always means
  /// the Benchlabs Codebench GitHub App is not installed on this repository
  /// (GitHub returns 404 instead of 403 to avoid leaking the existence of
  /// private resources). Could also indicate a typo'd or deleted repo.
  const factory CreatePrFailure.appNotInstalled() = CreatePrAppNotInstalled;

  const factory CreatePrFailure.network(String message) = CreatePrNetwork;
  const factory CreatePrFailure.permissionDenied() = CreatePrPermissionDenied;
  const factory CreatePrFailure.unknown(Object error) = CreatePrUnknownError;

  /// Raised by [CreatePrActions.loadContent] when branch listing or AI content
  /// generation cannot be completed. Carries a pre-formatted, user-facing
  /// message so the dialog can display it without re-translating the
  /// underlying failure type.
  const factory CreatePrFailure.loadContentFailed(String message) = CreatePrLoadContentFailed;
}
