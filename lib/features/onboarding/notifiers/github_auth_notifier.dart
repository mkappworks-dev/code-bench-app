import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/github/repository/github_repository_impl.dart';
import '../../../data/models/repository.dart';

part 'github_auth_notifier.g.dart';

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubRepository] directly.
@Riverpod(keepAlive: true)
class GitHubAuthNotifier extends _$GitHubAuthNotifier {
  @override
  Future<GitHubAccount?> build() async {
    final repo = await ref.read(githubRepositoryProvider.future);
    return repo.getStoredAccount();
  }

  /// Launches the OAuth browser flow. Updates state optimistically to loading
  /// then resolves to the new account or an error.
  Future<void> authenticate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(githubRepositoryProvider.future);
      return repo.authenticate();
    });
  }

  /// Deletes the stored PAT, then clears account state on success.
  ///
  /// We must delete before clearing: an optimistic `AsyncData(null)` followed
  /// by a failed keychain delete would leave the token on disk while the UI
  /// reports "signed out", and the next `build()` would silently
  /// re-authenticate from the leaked credential. On cleanup failure the
  /// notifier surfaces an [AsyncError] so a listener can warn the user.
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(githubRepositoryProvider.future);
      await repo.signOut();
      return null;
    });
  }

  /// Validates [token] against the GitHub API, persists it on success, and
  /// updates state. The token never leaves the service layer.
  Future<void> signInWithPat(String token) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(githubRepositoryProvider.future);
      return repo.signInWithPat(token);
    });
  }
}
