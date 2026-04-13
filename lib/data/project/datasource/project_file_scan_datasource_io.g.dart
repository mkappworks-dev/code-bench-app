// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_file_scan_datasource_io.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectFileScanDatasource)
final projectFileScanDatasourceProvider = ProjectFileScanDatasourceProvider._();

final class ProjectFileScanDatasourceProvider
    extends $FunctionalProvider<ProjectFileScanDatasource, ProjectFileScanDatasource, ProjectFileScanDatasource>
    with $Provider<ProjectFileScanDatasource> {
  ProjectFileScanDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectFileScanDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectFileScanDatasourceHash();

  @$internal
  @override
  $ProviderElement<ProjectFileScanDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ProjectFileScanDatasource create(Ref ref) {
    return projectFileScanDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectFileScanDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProjectFileScanDatasource>(value));
  }
}

String _$projectFileScanDatasourceHash() => r'9306e901df28cc32078759eb7a9eaa6ca4905281';
