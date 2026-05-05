// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_api_datasource_dio.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(githubApiDatasource)
final githubApiDatasourceProvider = GithubApiDatasourceProvider._();

final class GithubApiDatasourceProvider
    extends $FunctionalProvider<AsyncValue<GitHubApiDatasource?>, GitHubApiDatasource?, FutureOr<GitHubApiDatasource?>>
    with $FutureModifier<GitHubApiDatasource?>, $FutureProvider<GitHubApiDatasource?> {
  GithubApiDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubApiDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubApiDatasourceHash();

  @$internal
  @override
  $FutureProviderElement<GitHubApiDatasource?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GitHubApiDatasource?> create(Ref ref) {
    return githubApiDatasource(ref);
  }
}

String _$githubApiDatasourceHash() => r'4f23c6d78b98ebe609b7e64861f4c0b8ff10da8d';
