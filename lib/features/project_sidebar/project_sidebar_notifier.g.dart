// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_sidebar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently active project ID

@ProviderFor(ActiveProjectId)
final activeProjectIdProvider = ActiveProjectIdProvider._();

/// Currently active project ID
final class ActiveProjectIdProvider extends $NotifierProvider<ActiveProjectId, String?> {
  /// Currently active project ID
  ActiveProjectIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeProjectIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeProjectIdHash();

  @$internal
  @override
  ActiveProjectId create() => ActiveProjectId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String?>(value));
  }
}

String _$activeProjectIdHash() => r'9166eb23f2a190859c51c0f097b8e07b131ecd9c';

/// Currently active project ID

abstract class _$ActiveProjectId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<String?, String?>, String?, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

/// Set of expanded project IDs in the sidebar

@ProviderFor(ExpandedProjectIds)
final expandedProjectIdsProvider = ExpandedProjectIdsProvider._();

/// Set of expanded project IDs in the sidebar
final class ExpandedProjectIdsProvider extends $NotifierProvider<ExpandedProjectIds, Set<String>> {
  /// Set of expanded project IDs in the sidebar
  ExpandedProjectIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expandedProjectIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expandedProjectIdsHash();

  @$internal
  @override
  ExpandedProjectIds create() => ExpandedProjectIds();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Set<String>>(value));
  }
}

String _$expandedProjectIdsHash() => r'ba128c593215ffa366e3ced754f30b3551a7d111';

/// Set of expanded project IDs in the sidebar

abstract class _$ExpandedProjectIds extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<Set<String>, Set<String>>, Set<String>, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ProjectSort)
final projectSortProvider = ProjectSortProvider._();

final class ProjectSortProvider extends $AsyncNotifierProvider<ProjectSort, ProjectSortState> {
  ProjectSortProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectSortProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectSortHash();

  @$internal
  @override
  ProjectSort create() => ProjectSort();
}

String _$projectSortHash() => r'4e71b840509f03a4e46fcaaffa3b696b3544dbac';

abstract class _$ProjectSort extends $AsyncNotifier<ProjectSortState> {
  FutureOr<ProjectSortState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ProjectSortState>, ProjectSortState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ProjectSortState>, ProjectSortState>,
              AsyncValue<ProjectSortState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Watch all projects from the database

@ProviderFor(projects)
final projectsProvider = ProjectsProvider._();

/// Watch all projects from the database

final class ProjectsProvider
    extends $FunctionalProvider<AsyncValue<List<Project>>, List<Project>, Stream<List<Project>>>
    with $FutureModifier<List<Project>>, $StreamProvider<List<Project>> {
  /// Watch all projects from the database
  ProjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectsHash();

  @$internal
  @override
  $StreamProviderElement<List<Project>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<Project>> create(Ref ref) {
    return projects(ref);
  }
}

String _$projectsHash() => r'0be3045c68894954fca99a743e530ae28a245a27';
