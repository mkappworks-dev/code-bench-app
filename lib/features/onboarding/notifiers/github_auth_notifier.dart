import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/models/repository.dart';
import '../../../services/github/github_auth_service.dart';

part 'github_auth_notifier.g.dart';

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubAuthNotifierService] directly.
@Riverpod(keepAlive: true)
class GitHubAuthNotifier extends _$GitHubAuthNotifier {
  @override
  Future<GitHubAccount?> build() => ref.read(githubAuthServiceProvider).getStoredAccount();

  /// Launches the OAuth browser flow. Updates state optimistically to loading
  /// then resolves to the new account or an error.
  Future<void> authenticate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(githubAuthServiceProvider).authenticate());
  }

  /// Clears account state optimistically. If the token delete fails,
  /// logs and swallows — the UI already shows "signed out" and there is
  /// no recovery action available to the user.
  Future<void> signOut() async {
    state = const AsyncData(null);
    try {
      await ref.read(githubAuthServiceProvider).signOut();
    } catch (e, st) {
      dLog('[GitHubAuthNotifier] signOut cleanup failed: $e\n$st');
      // State already cleared — swallow so the widget sees clean state.
    }
  }

  /// Validates [token] against the GitHub API, persists it on success, and
  /// updates state. The token never leaves the service layer.
  Future<void> signInWithPat(String token) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(githubAuthServiceProvider).signInWithPat(token));
  }
}
