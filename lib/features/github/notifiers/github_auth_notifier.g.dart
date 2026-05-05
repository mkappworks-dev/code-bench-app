// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auto-dispose query provider — re-fetches every time a widget mounts fresh
/// (tab switch), and can be invalidated in-place (e.g. on app resume after the
/// user installs or removes the GitHub App in the browser).

@ProviderFor(githubInstallations)
final githubInstallationsProvider = GithubInstallationsProvider._();

/// Auto-dispose query provider — re-fetches every time a widget mounts fresh
/// (tab switch), and can be invalidated in-place (e.g. on app resume after the
/// user installs or removes the GitHub App in the browser).

final class GithubInstallationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GitHubAppInstallation>>,
          List<GitHubAppInstallation>,
          FutureOr<List<GitHubAppInstallation>>
        >
    with $FutureModifier<List<GitHubAppInstallation>>, $FutureProvider<List<GitHubAppInstallation>> {
  /// Auto-dispose query provider — re-fetches every time a widget mounts fresh
  /// (tab switch), and can be invalidated in-place (e.g. on app resume after the
  /// user installs or removes the GitHub App in the browser).
  GithubInstallationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubInstallationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubInstallationsHash();

  @$internal
  @override
  $FutureProviderElement<List<GitHubAppInstallation>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<GitHubAppInstallation>> create(Ref ref) {
    return githubInstallations(ref);
  }
}

String _$githubInstallationsHash() => r'fad012dc395cd22ed0d00e26f725d6d6f445167a';

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubService] directly.

@ProviderFor(GitHubAuthNotifier)
final gitHubAuthProvider = GitHubAuthNotifierProvider._();

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubService] directly.
final class GitHubAuthNotifierProvider extends $AsyncNotifierProvider<GitHubAuthNotifier, GitHubAccount?> {
  /// Holds the currently authenticated GitHub account and exposes auth actions.
  ///
  /// Widgets read `gitHubAuthProvider` for account state and call methods on
  /// its notifier for auth flows — they never touch [GitHubService] directly.
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

String _$gitHubAuthNotifierHash() => r'3e015dad9c0a96eadfba816e6b681326524f7e9a';

/// Holds the currently authenticated GitHub account and exposes auth actions.
///
/// Widgets read `gitHubAuthProvider` for account state and call methods on
/// its notifier for auth flows — they never touch [GitHubService] directly.

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
