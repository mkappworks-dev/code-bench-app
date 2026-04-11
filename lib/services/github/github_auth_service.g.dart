// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_auth_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(githubAuthService)
final githubAuthServiceProvider = GithubAuthServiceProvider._();

final class GithubAuthServiceProvider
    extends $FunctionalProvider<GitHubAuthService, GitHubAuthService, GitHubAuthService>
    with $Provider<GitHubAuthService> {
  GithubAuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubAuthServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubAuthServiceHash();

  @$internal
  @override
  $ProviderElement<GitHubAuthService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  GitHubAuthService create(Ref ref) {
    return githubAuthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitHubAuthService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<GitHubAuthService>(value));
  }
}

String _$githubAuthServiceHash() => r'b33369cec83e38488c69619c3341245921675043';
