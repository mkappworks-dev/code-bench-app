// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_detector_datasource_io.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gitDetectorDatasource)
final gitDetectorDatasourceProvider = GitDetectorDatasourceProvider._();

final class GitDetectorDatasourceProvider
    extends
        $FunctionalProvider<
          GitDetectorDatasource,
          GitDetectorDatasource,
          GitDetectorDatasource
        >
    with $Provider<GitDetectorDatasource> {
  GitDetectorDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitDetectorDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitDetectorDatasourceHash();

  @$internal
  @override
  $ProviderElement<GitDetectorDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GitDetectorDatasource create(Ref ref) {
    return gitDetectorDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitDetectorDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitDetectorDatasource>(value),
    );
  }
}

String _$gitDetectorDatasourceHash() =>
    r'7ab31dc1359bb1921fe8322fd5da109bcbcde654';
