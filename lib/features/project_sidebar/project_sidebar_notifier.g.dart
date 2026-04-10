// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_sidebar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectsHash() => r'0be3045c68894954fca99a743e530ae28a245a27';

/// Watch all projects from the database
///
/// Copied from [projects].
@ProviderFor(projects)
final projectsProvider = AutoDisposeStreamProvider<List<Project>>.internal(
  projects,
  name: r'projectsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$projectsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProjectsRef = AutoDisposeStreamProviderRef<List<Project>>;
String _$activeProjectIdHash() => r'9166eb23f2a190859c51c0f097b8e07b131ecd9c';

/// Currently active project ID
///
/// Copied from [ActiveProjectId].
@ProviderFor(ActiveProjectId)
final activeProjectIdProvider =
    NotifierProvider<ActiveProjectId, String?>.internal(
  ActiveProjectId.new,
  name: r'activeProjectIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeProjectIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveProjectId = Notifier<String?>;
String _$expandedProjectIdsHash() =>
    r'ba128c593215ffa366e3ced754f30b3551a7d111';

/// Set of expanded project IDs in the sidebar
///
/// Copied from [ExpandedProjectIds].
@ProviderFor(ExpandedProjectIds)
final expandedProjectIdsProvider =
    NotifierProvider<ExpandedProjectIds, Set<String>>.internal(
  ExpandedProjectIds.new,
  name: r'expandedProjectIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$expandedProjectIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ExpandedProjectIds = Notifier<Set<String>>;
String _$projectSortHash() => r'b4fd5fbc44ad448ba62978dc91636fce8aa67b68';

/// See also [ProjectSort].
@ProviderFor(ProjectSort)
final projectSortProvider =
    AsyncNotifierProvider<ProjectSort, ProjectSortState>.internal(
  ProjectSort.new,
  name: r'projectSortProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$projectSortHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProjectSort = AsyncNotifier<ProjectSortState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
