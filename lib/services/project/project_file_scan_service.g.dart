// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_file_scan_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectFileScanService)
final projectFileScanServiceProvider = ProjectFileScanServiceProvider._();

final class ProjectFileScanServiceProvider
    extends $FunctionalProvider<ProjectFileScanService, ProjectFileScanService, ProjectFileScanService>
    with $Provider<ProjectFileScanService> {
  ProjectFileScanServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectFileScanServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectFileScanServiceHash();

  @$internal
  @override
  $ProviderElement<ProjectFileScanService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ProjectFileScanService create(Ref ref) {
    return projectFileScanService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectFileScanService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProjectFileScanService>(value));
  }
}

String _$projectFileScanServiceHash() => r'86e73cd7af038ea6881135bc557795fd1cd3b4f6';
