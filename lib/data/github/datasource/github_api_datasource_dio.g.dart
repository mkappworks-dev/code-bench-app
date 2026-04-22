// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_api_datasource_dio.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [GitHubApiDatasource] initialised with the stored token,
/// or `null` when no token is available.

@ProviderFor(githubApiDatasource)
final githubApiDatasourceProvider = GithubApiDatasourceProvider._();

/// Provides a [GitHubApiDatasource] initialised with the stored token,
/// or `null` when no token is available.

final class GithubApiDatasourceProvider
    extends
        $FunctionalProvider<
          AsyncValue<GitHubApiDatasource?>,
          GitHubApiDatasource?,
          FutureOr<GitHubApiDatasource?>
        >
    with
        $FutureModifier<GitHubApiDatasource?>,
        $FutureProvider<GitHubApiDatasource?> {
  /// Provides a [GitHubApiDatasource] initialised with the stored token,
  /// or `null` when no token is available.
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
  $FutureProviderElement<GitHubApiDatasource?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GitHubApiDatasource?> create(Ref ref) {
    return githubApiDatasource(ref);
  }
}

String _$githubApiDatasourceHash() =>
    r'abbfd833c5946af9da45d67350263800eec8beee';
