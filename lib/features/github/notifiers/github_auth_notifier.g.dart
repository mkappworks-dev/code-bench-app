// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(githubInstallations)
final githubInstallationsProvider = GithubInstallationsProvider._();

final class GithubInstallationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GitHubAppInstallation>>,
          List<GitHubAppInstallation>,
          FutureOr<List<GitHubAppInstallation>>
        >
    with $FutureModifier<List<GitHubAppInstallation>>, $FutureProvider<List<GitHubAppInstallation>> {
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

String _$githubInstallationsHash() => r'6ef1e6ac69ee82425c2575b9ae3185e988277603';

@ProviderFor(GitHubAuthNotifier)
final gitHubAuthProvider = GitHubAuthNotifierProvider._();

final class GitHubAuthNotifierProvider extends $AsyncNotifierProvider<GitHubAuthNotifier, GitHubAccount?> {
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

String _$gitHubAuthNotifierHash() => r'f9321346585b8b6b36620bdd9260b7f897059e5a';

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
