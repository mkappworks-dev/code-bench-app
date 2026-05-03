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
/// The callback clears the stored credential and invalidates
/// [gitHubAuthProvider] so the UI transitions to the disconnected state
/// without waiting for the user to surface the error themselves.
///
/// Layering note: this provider intentionally imports a feature notifier
/// (`gitHubAuthProvider`) — the alternative (a side-channel
/// `unauthorizedHandlerProvider` in `lib/data/github/`) added a layer
/// of indirection without giving us anything testable in return. The
/// callback is only fired from within the datasource, so the seam stays
/// at the provider boundary, not inside the class.

@ProviderFor(githubApiDatasource)
final githubApiDatasourceProvider = GithubApiDatasourceProvider._();

/// Provides a [GitHubApiDatasource] initialised with the stored token,
/// or `null` when no token is available.
///
/// Wires an `onUnauthorized` callback that fires when GitHub rejects the
/// token on a real API call (not a deliberate `validateToken()` probe).
/// The callback clears the stored credential and invalidates
/// [gitHubAuthProvider] so the UI transitions to the disconnected state
/// without waiting for the user to surface the error themselves.
///
/// Layering note: this provider intentionally imports a feature notifier
/// (`gitHubAuthProvider`) — the alternative (a side-channel
/// `unauthorizedHandlerProvider` in `lib/data/github/`) added a layer
/// of indirection without giving us anything testable in return. The
/// callback is only fired from within the datasource, so the seam stays
/// at the provider boundary, not inside the class.

final class GithubApiDatasourceProvider
    extends $FunctionalProvider<AsyncValue<GitHubApiDatasource?>, GitHubApiDatasource?, FutureOr<GitHubApiDatasource?>>
    with $FutureModifier<GitHubApiDatasource?>, $FutureProvider<GitHubApiDatasource?> {
  /// Provides a [GitHubApiDatasource] initialised with the stored token,
  /// or `null` when no token is available.
  ///
  /// Wires an `onUnauthorized` callback that fires when GitHub rejects the
  /// token on a real API call (not a deliberate `validateToken()` probe).
  /// The callback clears the stored credential and invalidates
  /// [gitHubAuthProvider] so the UI transitions to the disconnected state
  /// without waiting for the user to surface the error themselves.
  ///
  /// Layering note: this provider intentionally imports a feature notifier
  /// (`gitHubAuthProvider`) — the alternative (a side-channel
  /// `unauthorizedHandlerProvider` in `lib/data/github/`) added a layer
  /// of indirection without giving us anything testable in return. The
  /// callback is only fired from within the datasource, so the seam stays
  /// at the provider boundary, not inside the class.
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

String _$githubApiDatasourceHash() => r'e4f9b46c24164c379a4b70d70797d89840454d95';
