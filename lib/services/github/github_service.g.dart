// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(githubService)
final githubServiceProvider = GithubServiceProvider._();

final class GithubServiceProvider
    extends $FunctionalProvider<AsyncValue<GitHubService>, GitHubService, FutureOr<GitHubService>>
    with $FutureModifier<GitHubService>, $FutureProvider<GitHubService> {
  GithubServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubServiceHash();

  @$internal
  @override
  $FutureProviderElement<GitHubService> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<GitHubService> create(Ref ref) {
    return githubService(ref);
  }
}

String _$githubServiceHash() => r'14612b81633eb8ca1d5ee164815445f91c0a756e';
