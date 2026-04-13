// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_auth_datasource_web.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(githubAuthDatasource)
final githubAuthDatasourceProvider = GithubAuthDatasourceProvider._();

final class GithubAuthDatasourceProvider
    extends $FunctionalProvider<GitHubAuthDatasource, GitHubAuthDatasource, GitHubAuthDatasource>
    with $Provider<GitHubAuthDatasource> {
  GithubAuthDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubAuthDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubAuthDatasourceHash();

  @$internal
  @override
  $ProviderElement<GitHubAuthDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  GitHubAuthDatasource create(Ref ref) {
    return githubAuthDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitHubAuthDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<GitHubAuthDatasource>(value));
  }
}

String _$githubAuthDatasourceHash() => r'cddde24bd45751e32e0139fc3ab25a97b02bcfb4';
