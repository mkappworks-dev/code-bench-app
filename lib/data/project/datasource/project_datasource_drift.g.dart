// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_datasource_drift.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectDatasource)
final projectDatasourceProvider = ProjectDatasourceProvider._();

final class ProjectDatasourceProvider
    extends $FunctionalProvider<ProjectDatasource, ProjectDatasource, ProjectDatasource>
    with $Provider<ProjectDatasource> {
  ProjectDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectDatasourceHash();

  @$internal
  @override
  $ProviderElement<ProjectDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ProjectDatasource create(Ref ref) {
    return projectDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProjectDatasource>(value));
  }
}

String _$projectDatasourceHash() => r'25fe5a45658bbd280fe14e91fce34f7cd3bfcd0a';
