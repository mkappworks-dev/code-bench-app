// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_apply_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier for code-apply and revert operations.
///
/// Widgets never reach [ApplyService] directly — they call methods here.
/// On [ProjectMissingException], [applyChange] also triggers a project-status
/// refresh so the sidebar reflects the missing state without the widget needing
/// to know about [ProjectSidebarActions].

@ProviderFor(CodeApplyActions)
final codeApplyActionsProvider = CodeApplyActionsProvider._();

/// Command notifier for code-apply and revert operations.
///
/// Widgets never reach [ApplyService] directly — they call methods here.
/// On [ProjectMissingException], [applyChange] also triggers a project-status
/// refresh so the sidebar reflects the missing state without the widget needing
/// to know about [ProjectSidebarActions].
final class CodeApplyActionsProvider extends $NotifierProvider<CodeApplyActions, void> {
  /// Command notifier for code-apply and revert operations.
  ///
  /// Widgets never reach [ApplyService] directly — they call methods here.
  /// On [ProjectMissingException], [applyChange] also triggers a project-status
  /// refresh so the sidebar reflects the missing state without the widget needing
  /// to know about [ProjectSidebarActions].
  CodeApplyActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'codeApplyActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$codeApplyActionsHash();

  @$internal
  @override
  CodeApplyActions create() => CodeApplyActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$codeApplyActionsHash() => r'1c67bde6a0b27a429a9e7c1e3513854789f28ddd';

/// Command notifier for code-apply and revert operations.
///
/// Widgets never reach [ApplyService] directly — they call methods here.
/// On [ProjectMissingException], [applyChange] also triggers a project-status
/// refresh so the sidebar reflects the missing state without the widget needing
/// to know about [ProjectSidebarActions].

abstract class _$CodeApplyActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
