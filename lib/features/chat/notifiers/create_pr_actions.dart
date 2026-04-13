import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/github/github_service.dart';
import 'create_pr_failure.dart';

part 'create_pr_actions.g.dart';

/// Command notifier mediating every GitHub-API call the "Create PR"
/// dialog flow makes. Widgets never touch [GitHubRepository] or
/// [SecureStorage] directly — they go through here so the
/// GitHub PAT never crosses the widget layer.
///
/// ### Security
///
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. Same discipline as
/// [PrCardNotifier]; see `macos/Runner/README.md`.
@Riverpod(keepAlive: true)
class CreatePrActions extends _$CreatePrActions {
  @override
  FutureOr<void> build() {}

  CreatePrFailure _asFailure(Object e) => switch (e) {
    AuthException() => const CreatePrFailure.notAuthenticated(),
    NetworkException(:final statusCode) when statusCode == 403 => const CreatePrFailure.permissionDenied(),
    NetworkException(:final message) => CreatePrFailure.network(message),
    _ => CreatePrFailure.unknown(e),
  };

  /// Returns `true` when a GitHub token is available (PAT or OAuth).
  /// Resolves the shared [githubRepositoryProvider] rather than reading
  /// secure storage directly, so the widget never sees the token.
  Future<bool> hasToken() async {
    final repo = await ref.read(githubServiceProvider.future);
    return repo.isAuthenticated();
  }

  /// Lists branches for [owner]/[repo]. Returns `null` and emits
  /// [AsyncError] carrying a [CreatePrFailure] when the call fails.
  Future<List<String>?> listBranches(String owner, String repo) async {
    state = const AsyncLoading();
    List<String>? result;
    state = await AsyncValue.guard(() async {
      try {
        final repository = await ref.read(githubServiceProvider.future);
        result = await repository.listBranches(owner, repo);
      } catch (e, st) {
        dLog('[CreatePrActions] listBranches failed: ${e.runtimeType}');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return result;
  }

  /// Creates a pull request and returns the PR's html_url, or `null`
  /// and emits [AsyncError] carrying a [CreatePrFailure] on failure.
  Future<String?> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    required bool draft,
  }) async {
    state = const AsyncLoading();
    String? result;
    state = await AsyncValue.guard(() async {
      try {
        final repository = await ref.read(githubServiceProvider.future);
        result = await repository.createPullRequest(
          owner: owner,
          repo: repo,
          title: title,
          body: body,
          head: head,
          base: base,
          draft: draft,
        );
      } catch (e, st) {
        dLog('[CreatePrActions] createPullRequest failed: ${e.runtimeType}');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return result;
  }
}
