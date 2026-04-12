import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/github/github_api_service.dart';

part 'pr_notifier.g.dart';

class PrCardState {
  const PrCardState({
    required this.pr,
    required this.checkRuns,
    required this.approved,
    required this.merged,
    this.pollError,
  });

  final Map<String, dynamic> pr;
  final List<Map<String, dynamic>> checkRuns;
  final bool approved;
  final bool merged;

  /// Non-null when a background poll failed but we still have stale data to
  /// show. Rendered as an inline warning banner on the card.
  final String? pollError;

  PrCardState copyWith({
    Map<String, dynamic>? pr,
    List<Map<String, dynamic>>? checkRuns,
    bool? approved,
    bool? merged,
    String? pollError,
    bool clearPollError = false,
  }) => PrCardState(
    pr: pr ?? this.pr,
    checkRuns: checkRuns ?? this.checkRuns,
    approved: approved ?? this.approved,
    merged: merged ?? this.merged,
    pollError: clearPollError ? null : (pollError ?? this.pollError),
  );
}

/// Manages live state for a single GitHub pull request card.
///
/// Widgets call [refresh] from their poll timer, [approve] and [merge] from
/// button taps — they never touch [GitHubApiService] directly.
///
/// ### Security
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. See `macos/Runner/README.md`.
@riverpod
class PrCardNotifier extends _$PrCardNotifier {
  @override
  Future<PrCardState> build(String owner, String repo, int prNumber) async {
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) throw const AuthException('Not signed in to GitHub');
    return _fetch(svc);
  }

  /// Called by the widget's poll timer. Updates state in-place so a poll
  /// failure shows a warning banner rather than replacing the whole card with
  /// an error widget.
  Future<void> refresh() async {
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) return;
    try {
      final fresh = await _fetch(svc);
      // Preserve the local approved/merged flags — once set they should not
      // flip back to false just because a poll returns a stale snapshot.
      final current = state.value;
      state = AsyncData(
        fresh.copyWith(
          approved: current?.approved ?? false,
          merged: fresh.merged || (current?.merged ?? false),
          clearPollError: true,
        ),
      );
    } catch (e) {
      dLog('[PrCardNotifier] poll failed: ${e.runtimeType}');
      final current = state.value;
      if (current != null) {
        state = AsyncData(current.copyWith(pollError: _friendlyError(e)));
      }
    }
  }

  Future<void> approve() async {
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) return;
    try {
      await svc.approvePullRequest(owner, repo, prNumber);
    } catch (e) {
      dLog('[PrCardNotifier] approve failed: ${e.runtimeType}');
      rethrow;
    }
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(approved: true));
  }

  Future<void> merge() async {
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) return;
    try {
      await svc.mergePullRequest(owner, repo, prNumber);
    } catch (e) {
      dLog('[PrCardNotifier] merge failed: ${e.runtimeType}');
      rethrow;
    }
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(merged: true));
    await refresh();
  }

  Future<PrCardState> _fetch(GitHubApiService svc) async {
    final pr = await svc.getPullRequest(owner, repo, prNumber);
    final sha = (pr['head'] as Map<String, dynamic>?)?['sha'] as String?;
    final checks = sha != null ? await svc.getCheckRuns(owner, repo, sha) : const <Map<String, dynamic>>[];
    final merged = pr['merged'] as bool? ?? (pr['merged_at'] != null);
    return PrCardState(pr: pr, checkRuns: checks, approved: false, merged: merged);
  }

  String _friendlyError(Object e) {
    if (e is NetworkException) {
      final s = e.statusCode;
      if (s == null) return 'Network error — check your connection.';
      if (s == 401) return 'GitHub authentication failed — check your token.';
      if (s == 403) return 'Permission denied.';
      if (s == 404) return 'Pull request not found.';
      if (s == 405) return 'Merge not allowed — state changed.';
      if (s == 409 || s == 422) return 'Cannot merge — resolve conflicts or required checks.';
      if (s >= 500) return 'GitHub service error ($s).';
      return 'Request failed ($s).';
    }
    if (e is AppException) return e.message;
    return 'Unexpected error.';
  }

  bool isFatalError(Object e) {
    if (e is! NetworkException) return false;
    final s = e.statusCode;
    return s == 401 || s == 403 || s == 404;
  }
}
