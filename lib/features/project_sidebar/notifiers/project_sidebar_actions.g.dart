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
final class ProjectSidebarActionsProvider extends $AsyncNotifierProvider<ProjectSidebarActions, void> {
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
}

String _$projectSidebarActionsHash() => r'80dd6c245af6726c0766e9594b7037ecabe1dc86';

/// Command notifier that mediates every imperative project/session mutation
/// triggered from the sidebar. Widgets never reach into [ProjectService] or
/// [SessionService] directly — they call methods here instead.

abstract class _$ProjectSidebarActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<void>, void>, AsyncValue<void>, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
