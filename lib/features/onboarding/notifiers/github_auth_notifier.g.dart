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
/// its notifier for auth flows — they never touch [GitHubAuthNotifierService] directly.

@ProviderFor(GitHubAuthNotifier)
final gitHubAuthProvider = GitHubAuthNotifierProvider._();

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubAuthNotifierService] directly.
final class GitHubAuthNotifierProvider extends $AsyncNotifierProvider<GitHubAuthNotifier, GitHubAccount?> {
  /// Holds the currently authenticated GitHub account and exposes auth actions.
  ///
  /// Widgets read `gitHubAuthProvider` for account state and call methods on
  /// its notifier for auth flows — they never touch [GitHubAuthNotifierService] directly.
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

String _$gitHubAuthNotifierHash() => r'30bd570b7515ce755a406c12f8b834cfba0c0005';

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubAuthNotifierService] directly.

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
