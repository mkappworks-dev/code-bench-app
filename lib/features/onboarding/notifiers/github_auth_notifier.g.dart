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
/// its notifier for auth flows — they never touch [GitHubAuthService] directly.

@ProviderFor(GitHubAuth)
final gitHubAuthProvider = GitHubAuthProvider._();

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubAuthService] directly.
final class GitHubAuthProvider extends $AsyncNotifierProvider<GitHubAuth, GitHubAccount?> {
  /// Holds the currently authenticated GitHub account and exposes auth actions.
  ///
  /// Widgets read `gitHubAuthProvider` for account state and call methods on
  /// its notifier for auth flows — they never touch [GitHubAuthService] directly.
  GitHubAuthProvider._()
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
  String debugGetCreateSourceHash() => _$gitHubAuthHash();

  @$internal
  @override
  GitHubAuth create() => GitHubAuth();
}

String _$gitHubAuthHash() => r'eb890af57b392176d7ace5b31e81335595454411';

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubAuthService] directly.

abstract class _$GitHubAuth extends $AsyncNotifier<GitHubAccount?> {
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
