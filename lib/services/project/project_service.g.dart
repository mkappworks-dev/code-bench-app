// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectService)
final projectServiceProvider = ProjectServiceProvider._();

final class ProjectServiceProvider extends $FunctionalProvider<ProjectService, ProjectService, ProjectService>
    with $Provider<ProjectService> {
  ProjectServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectServiceHash();

  @$internal
  @override
  $ProviderElement<ProjectService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ProjectService create(Ref ref) {
    return projectService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProjectService>(value));
  }
}

String _$projectServiceHash() => r'1b41c407dcf5073cc7602c8a5cbfc14ebe299bf3';
