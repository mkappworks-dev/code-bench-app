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
/// State is [AsyncValue<void>]: loading/error/data are driven by each method.
/// Typed failures are emitted as [AsyncError] carrying a [CodeApplyFailure].
///
/// On [ProjectMissingException], [applyChange] also triggers a project-status
/// refresh so the sidebar reflects the missing state without the widget needing
/// to know about [ProjectSidebarActions].

@ProviderFor(CodeApplyActions)
final codeApplyActionsProvider = CodeApplyActionsProvider._();

/// Command notifier for code-apply and revert operations.
///
/// Widgets never reach [ApplyService] directly — they call methods here.
/// State is [AsyncValue<void>]: loading/error/data are driven by each method.
/// Typed failures are emitted as [AsyncError] carrying a [CodeApplyFailure].
///
/// On [ProjectMissingException], [applyChange] also triggers a project-status
/// refresh so the sidebar reflects the missing state without the widget needing
/// to know about [ProjectSidebarActions].
final class CodeApplyActionsProvider
    extends $AsyncNotifierProvider<CodeApplyActions, void> {
  /// Command notifier for code-apply and revert operations.
  ///
  /// Widgets never reach [ApplyService] directly — they call methods here.
  /// State is [AsyncValue<void>]: loading/error/data are driven by each method.
  /// Typed failures are emitted as [AsyncError] carrying a [CodeApplyFailure].
  ///
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
}

String _$codeApplyActionsHash() => r'3519b422ac0e4f5eb3e6a5a0f6174eb8584f32ad';

/// Command notifier for code-apply and revert operations.
///
/// Widgets never reach [ApplyService] directly — they call methods here.
/// State is [AsyncValue<void>]: loading/error/data are driven by each method.
/// Typed failures are emitted as [AsyncError] carrying a [CodeApplyFailure].
///
/// On [ProjectMissingException], [applyChange] also triggers a project-status
/// refresh so the sidebar reflects the missing state without the widget needing
/// to know about [ProjectSidebarActions].

abstract class _$CodeApplyActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
