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

String _$githubInstallationsHash() => r'fad012dc395cd22ed0d00e26f725d6d6f445167a';

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

String _$gitHubAuthNotifierHash() => r'3e015dad9c0a96eadfba816e6b681326524f7e9a';

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
