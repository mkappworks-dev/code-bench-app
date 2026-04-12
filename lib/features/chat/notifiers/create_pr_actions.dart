import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/github/github_api_service.dart';

part 'create_pr_actions.g.dart';

/// Command notifier mediating every GitHub-API call the "Create PR"
/// dialog flow makes. Widgets never touch [GitHubApiService] or
/// [SecureStorageSource] directly — they go through here so the
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
  void build() {}

  /// Returns `true` when a GitHub token is available (PAT or OAuth).
  /// Resolves the shared [githubApiServiceProvider] rather than reading
  /// secure storage directly, so the widget never sees the token.
  Future<bool> hasToken() async {
    final svc = await ref.read(githubApiServiceProvider.future);
    return svc != null;
  }

  /// Lists branches for [owner]/[repo]. Throws [AuthException] when
  /// no token is configured; other network errors propagate as-is so
  /// the caller can map them to a user-facing message.
  Future<List<String>> listBranches(String owner, String repo) async {
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) throw const AuthException('Not signed in to GitHub');
    try {
      return await svc.listBranches(owner, repo);
    } catch (e) {
      dLog('[CreatePrActions] listBranches failed: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Creates a pull request and returns the PR's html_url.
  /// Throws [AuthException] when no token is configured.
  Future<String> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    required bool draft,
  }) async {
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) throw const AuthException('Not signed in to GitHub');
    try {
      return await svc.createPullRequest(
        owner: owner,
        repo: repo,
        title: title,
        body: body,
        head: head,
        base: base,
        draft: draft,
      );
    } catch (e) {
      dLog('[CreatePrActions] createPullRequest failed: ${e.runtimeType}');
      rethrow;
    }
  }
}
