// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_sidebar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently active project ID

@ProviderFor(ActiveProjectIdNotifier)
final activeProjectIdProvider = ActiveProjectIdNotifierProvider._();

/// Currently active project ID
final class ActiveProjectIdNotifierProvider
    extends $NotifierProvider<ActiveProjectIdNotifier, String?> {
  /// Currently active project ID
  ActiveProjectIdNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$activeProjectIdNotifierHash();

  @$internal
  @override
  ActiveProjectIdNotifier create() => ActiveProjectIdNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeProjectIdNotifierHash() =>
    r'032bad49dc96f9a471be8df596a2fdd7dee6737a';

/// Currently active project ID

abstract class _$ActiveProjectIdNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Persisted worktree path overrides: sessionId → effective filesystem path.
///
/// When the user switches to a worktree via the branch picker, the entry
/// for the active session is stored here and written through to SharedPreferences
/// so each thread remembers its worktree context across app restarts.
/// Cleared when the user switches back to the main working tree.

@ProviderFor(ActiveWorktreePathNotifier)
final activeWorktreePathProvider = ActiveWorktreePathNotifierProvider._();

/// Persisted worktree path overrides: sessionId → effective filesystem path.
///
/// When the user switches to a worktree via the branch picker, the entry
/// for the active session is stored here and written through to SharedPreferences
/// so each thread remembers its worktree context across app restarts.
/// Cleared when the user switches back to the main working tree.
final class ActiveWorktreePathNotifierProvider
    extends $NotifierProvider<ActiveWorktreePathNotifier, Map<String, String>> {
  /// Persisted worktree path overrides: sessionId → effective filesystem path.
  ///
  /// When the user switches to a worktree via the branch picker, the entry
  /// for the active session is stored here and written through to SharedPreferences
  /// so each thread remembers its worktree context across app restarts.
  /// Cleared when the user switches back to the main working tree.
  ActiveWorktreePathNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWorktreePathProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWorktreePathNotifierHash();

  @$internal
  @override
  ActiveWorktreePathNotifier create() => ActiveWorktreePathNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$activeWorktreePathNotifierHash() =>
    r'232db4ee6455b27903824e088648e9fa104a238d';

/// Persisted worktree path overrides: sessionId → effective filesystem path.
///
/// When the user switches to a worktree via the branch picker, the entry
/// for the active session is stored here and written through to SharedPreferences
/// so each thread remembers its worktree context across app restarts.
/// Cleared when the user switches back to the main working tree.

abstract class _$ActiveWorktreePathNotifier
    extends $Notifier<Map<String, String>> {
  Map<String, String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, String>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, String>, Map<String, String>>,
              Map<String, String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Set of expanded project IDs in the sidebar

@ProviderFor(ExpandedProjectIdsNotifier)
final expandedProjectIdsProvider = ExpandedProjectIdsNotifierProvider._();

/// Set of expanded project IDs in the sidebar
final class ExpandedProjectIdsNotifierProvider
    extends $NotifierProvider<ExpandedProjectIdsNotifier, Set<String>> {
  /// Set of expanded project IDs in the sidebar
  ExpandedProjectIdsNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$expandedProjectIdsNotifierHash();

  @$internal
  @override
  ExpandedProjectIdsNotifier create() => ExpandedProjectIdsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$expandedProjectIdsNotifierHash() =>
    r'b3106ff766a9bc2d09a4d5e1112b2311e21bf9d9';

/// Set of expanded project IDs in the sidebar

abstract class _$ExpandedProjectIdsNotifier extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ProjectSortNotifier)
final projectSortProvider = ProjectSortNotifierProvider._();

final class ProjectSortNotifierProvider
    extends $AsyncNotifierProvider<ProjectSortNotifier, ProjectSortState> {
  ProjectSortNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$projectSortNotifierHash();

  @$internal
  @override
  ProjectSortNotifier create() => ProjectSortNotifier();
}

String _$projectSortNotifierHash() =>
    r'de1aa25f10417f8a4f6be433b0613438fb1fcaff';

abstract class _$ProjectSortNotifier extends $AsyncNotifier<ProjectSortState> {
  FutureOr<ProjectSortState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ProjectSortState>, ProjectSortState>;
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
    extends
        $FunctionalProvider<
          AsyncValue<List<Project>>,
          List<Project>,
          Stream<List<Project>>
        >
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
  $StreamProviderElement<List<Project>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Project>> create(Ref ref) {
    return projects(ref);
  }
}

String _$projectsHash() => r'4f937a9e5fc03054ae7f22ce9343e0519b76fb71';

/// Derives the currently active [Project] from [activeProjectIdProvider] and
/// [projectsProvider]. Returns null while projects are loading or if no project
/// is selected. Use `ref.watch` in build for reactivity; `ref.read` in handlers.

@ProviderFor(activeProject)
final activeProjectProvider = ActiveProjectProvider._();

/// Derives the currently active [Project] from [activeProjectIdProvider] and
/// [projectsProvider]. Returns null while projects are loading or if no project
/// is selected. Use `ref.watch` in build for reactivity; `ref.read` in handlers.

final class ActiveProjectProvider
    extends $FunctionalProvider<Project?, Project?, Project?>
    with $Provider<Project?> {
  /// Derives the currently active [Project] from [activeProjectIdProvider] and
  /// [projectsProvider]. Returns null while projects are loading or if no project
  /// is selected. Use `ref.watch` in build for reactivity; `ref.read` in handlers.
  ActiveProjectProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeProjectProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeProjectHash();

  @$internal
  @override
  $ProviderElement<Project?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Project? create(Ref ref) {
    return activeProject(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Project? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Project?>(value),
    );
  }
}

String _$activeProjectHash() => r'50cfe3f344265aaa023cd311a587d048deaeeadd';
