// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_live_state_datasource_process.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gitLiveStateDatasource)
final gitLiveStateDatasourceProvider = GitLiveStateDatasourceProvider._();

final class GitLiveStateDatasourceProvider
    extends $FunctionalProvider<GitLiveStateDatasource, GitLiveStateDatasource, GitLiveStateDatasource>
    with $Provider<GitLiveStateDatasource> {
  GitLiveStateDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitLiveStateDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitLiveStateDatasourceHash();

  @$internal
  @override
  $ProviderElement<GitLiveStateDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  GitLiveStateDatasource create(Ref ref) {
    return gitLiveStateDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitLiveStateDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<GitLiveStateDatasource>(value));
  }
}

String _$gitLiveStateDatasourceHash() => r'6abda28d7a564ec389280d7895ff9148ed4abd0b';
