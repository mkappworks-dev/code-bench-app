// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubRepository] directly.

@ProviderFor(GitHubAuthNotifier)
final gitHubAuthProvider = GitHubAuthNotifierProvider._();

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubRepository] directly.
final class GitHubAuthNotifierProvider extends $AsyncNotifierProvider<GitHubAuthNotifier, GitHubAccount?> {
  /// Holds the currently authenticated GitHub account and exposes auth actions.
  ///
  /// Widgets read `gitHubAuthProvider` for account state and call methods on
  /// its notifier for auth flows — they never touch [GitHubRepository] directly.
  GitHubAuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubAuthNotifierHash();

  @$internal
  @override
  GitHubAuthNotifier create() => GitHubAuthNotifier();
}

String _$gitHubAuthNotifierHash() => r'7984a6c1a335765e15a583548b0b67e55ea57e1a';

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubRepository] directly.

abstract class _$GitHubAuthNotifier extends $AsyncNotifier<GitHubAccount?> {
  FutureOr<GitHubAccount?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GitHubAccount?>, GitHubAccount?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GitHubAccount?>, GitHubAccount?>,
              AsyncValue<GitHubAccount?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
