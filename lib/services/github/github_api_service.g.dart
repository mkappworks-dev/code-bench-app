// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_api_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(githubApiService)
final githubApiServiceProvider = GithubApiServiceProvider._();

final class GithubApiServiceProvider
    extends $FunctionalProvider<AsyncValue<GitHubApiService?>, GitHubApiService?, FutureOr<GitHubApiService?>>
    with $FutureModifier<GitHubApiService?>, $FutureProvider<GitHubApiService?> {
  GithubApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubApiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubApiServiceHash();

  @$internal
  @override
  $FutureProviderElement<GitHubApiService?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<GitHubApiService?> create(Ref ref) {
    return githubApiService(ref);
  }
}

String _$githubApiServiceHash() => r'5a8db4c5420b844bba260a6d33ecfc913d689d81';
