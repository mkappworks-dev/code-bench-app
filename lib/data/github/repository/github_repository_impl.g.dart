// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(githubRepository)
final githubRepositoryProvider = GithubRepositoryProvider._();

final class GithubRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<GitHubRepository>,
          GitHubRepository,
          FutureOr<GitHubRepository>
        >
    with $FutureModifier<GitHubRepository>, $FutureProvider<GitHubRepository> {
  GithubRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<GitHubRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GitHubRepository> create(Ref ref) {
    return githubRepository(ref);
  }
}

String _$githubRepositoryHash() => r'319ae19c6cb353b879ee5a83d94c0b6a3b5f32fc';
