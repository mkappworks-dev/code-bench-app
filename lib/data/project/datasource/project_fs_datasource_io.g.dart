// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_fs_datasource_io.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectFsDatasource)
final projectFsDatasourceProvider = ProjectFsDatasourceProvider._();

final class ProjectFsDatasourceProvider
    extends $FunctionalProvider<ProjectFsDatasource, ProjectFsDatasource, ProjectFsDatasource>
    with $Provider<ProjectFsDatasource> {
  ProjectFsDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectFsDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectFsDatasourceHash();

  @$internal
  @override
  $ProviderElement<ProjectFsDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ProjectFsDatasource create(Ref ref) {
    return projectFsDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectFsDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProjectFsDatasource>(value));
  }
}

String _$projectFsDatasourceHash() => r'19dfde9b5ce54678570ff046eec787ccd6fb5065';
