// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_api_datasource_dio.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [GitHubApiDatasource] initialised with the stored token,
/// or `null` when no token is available.
///
/// Wires an `onUnauthorized` callback that fires when GitHub rejects the
/// token on a real API call (not a deliberate `validateToken()` probe).
/// The callback clears the stored credential and self-invalidates this
/// provider. Because [githubRepositoryProvider] watches this provider,
/// and [githubServiceProvider] watches the repo, and [gitHubAuthProvider]
/// watches the service, the invalidation cascades up the reactive graph
/// and the UI transitions to the disconnected state automatically — with
/// no cross-layer import required.

@ProviderFor(githubApiDatasource)
final githubApiDatasourceProvider = GithubApiDatasourceProvider._();

/// Provides a [GitHubApiDatasource] initialised with the stored token,
/// or `null` when no token is available.
///
/// Wires an `onUnauthorized` callback that fires when GitHub rejects the
/// token on a real API call (not a deliberate `validateToken()` probe).
/// The callback clears the stored credential and self-invalidates this
/// provider. Because [githubRepositoryProvider] watches this provider,
/// and [githubServiceProvider] watches the repo, and [gitHubAuthProvider]
/// watches the service, the invalidation cascades up the reactive graph
/// and the UI transitions to the disconnected state automatically — with
/// no cross-layer import required.

final class GithubApiDatasourceProvider
    extends $FunctionalProvider<AsyncValue<GitHubApiDatasource?>, GitHubApiDatasource?, FutureOr<GitHubApiDatasource?>>
    with $FutureModifier<GitHubApiDatasource?>, $FutureProvider<GitHubApiDatasource?> {
  /// Provides a [GitHubApiDatasource] initialised with the stored token,
  /// or `null` when no token is available.
  ///
  /// Wires an `onUnauthorized` callback that fires when GitHub rejects the
  /// token on a real API call (not a deliberate `validateToken()` probe).
  /// The callback clears the stored credential and self-invalidates this
  /// provider. Because [githubRepositoryProvider] watches this provider,
  /// and [githubServiceProvider] watches the repo, and [gitHubAuthProvider]
  /// watches the service, the invalidation cascades up the reactive graph
  /// and the UI transitions to the disconnected state automatically — with
  /// no cross-layer import required.
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
