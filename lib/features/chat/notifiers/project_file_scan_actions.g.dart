// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_file_scan_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier for the @-mention file picker's project scan.
///
/// Widgets never touch [ProjectFileScanService] directly — they call
/// [scanCodeFiles] here, which owns the FileSystemException logging so the
/// widget can render a plain error string without a second log site.

@ProviderFor(ProjectFileScanActions)
final projectFileScanActionsProvider = ProjectFileScanActionsProvider._();

/// Command notifier for the @-mention file picker's project scan.
///
/// Widgets never touch [ProjectFileScanService] directly — they call
/// [scanCodeFiles] here, which owns the FileSystemException logging so the
/// widget can render a plain error string without a second log site.
final class ProjectFileScanActionsProvider extends $NotifierProvider<ProjectFileScanActions, void> {
  /// Command notifier for the @-mention file picker's project scan.
  ///
  /// Widgets never touch [ProjectFileScanService] directly — they call
  /// [scanCodeFiles] here, which owns the FileSystemException logging so the
  /// widget can render a plain error string without a second log site.
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$projectFileScanActionsHash() => r'a3f8c3b048ad5b698ee45a7ab1987f1416ed7b4c';

/// Command notifier for the @-mention file picker's project scan.
///
/// Widgets never touch [ProjectFileScanService] directly — they call
/// [scanCodeFiles] here, which owns the FileSystemException logging so the
/// widget can render a plain error string without a second log site.

abstract class _$ProjectFileScanActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
