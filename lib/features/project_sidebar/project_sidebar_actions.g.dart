// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_sidebar_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier that mediates every imperative project/session mutation
/// triggered from the sidebar. Widgets never reach into [ProjectService] or
/// [SessionService] directly — they call methods here instead.

@ProviderFor(ProjectSidebarActions)
final projectSidebarActionsProvider = ProjectSidebarActionsProvider._();

/// Command notifier that mediates every imperative project/session mutation
/// triggered from the sidebar. Widgets never reach into [ProjectService] or
/// [SessionService] directly — they call methods here instead.
final class ProjectSidebarActionsProvider extends $NotifierProvider<ProjectSidebarActions, void> {
  /// Command notifier that mediates every imperative project/session mutation
  /// triggered from the sidebar. Widgets never reach into [ProjectService] or
  /// [SessionService] directly — they call methods here instead.
  ProjectSidebarActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectSidebarActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectSidebarActionsHash();

  @$internal
  @override
  ProjectSidebarActions create() => ProjectSidebarActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$projectSidebarActionsHash() => r'7ca5081538ebf931bb6a496c57e55e3a9a495b18';

/// Command notifier that mediates every imperative project/session mutation
/// triggered from the sidebar. Widgets never reach into [ProjectService] or
/// [SessionService] directly — they call methods here instead.

abstract class _$ProjectSidebarActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
