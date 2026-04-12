// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_file_scan_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier for the file picker's project scan.
///
/// On [FileSystemException] the notifier emits [AsyncError] carrying a
/// [ProjectFileScanFailure] so widgets can surface an inline error message
/// via [ref.listen] without catching exceptions themselves.

@ProviderFor(ProjectFileScanActions)
final projectFileScanActionsProvider = ProjectFileScanActionsProvider._();

/// Command notifier for the file picker's project scan.
///
/// On [FileSystemException] the notifier emits [AsyncError] carrying a
/// [ProjectFileScanFailure] so widgets can surface an inline error message
/// via [ref.listen] without catching exceptions themselves.
final class ProjectFileScanActionsProvider extends $AsyncNotifierProvider<ProjectFileScanActions, void> {
  /// Command notifier for the file picker's project scan.
  ///
  /// On [FileSystemException] the notifier emits [AsyncError] carrying a
  /// [ProjectFileScanFailure] so widgets can surface an inline error message
  /// via [ref.listen] without catching exceptions themselves.
  ProjectFileScanActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectFileScanActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectFileScanActionsHash();

  @$internal
  @override
  ProjectFileScanActions create() => ProjectFileScanActions();
}

String _$projectFileScanActionsHash() => r'92799547fea6642be3445fb88c1e265809d66afd';

/// Command notifier for the file picker's project scan.
///
/// On [FileSystemException] the notifier emits [AsyncError] carrying a
/// [ProjectFileScanFailure] so widgets can surface an inline error message
/// via [ref.listen] without catching exceptions themselves.

abstract class _$ProjectFileScanActions extends $AsyncNotifier<void> {
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
