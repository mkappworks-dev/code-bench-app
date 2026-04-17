// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Imperative actions for the Archive screen.

@ProviderFor(ArchiveActions)
final archiveActionsProvider = ArchiveActionsProvider._();

/// Imperative actions for the Archive screen.
final class ArchiveActionsProvider
    extends $AsyncNotifierProvider<ArchiveActions, void> {
  /// Imperative actions for the Archive screen.
  ArchiveActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveActionsHash();

  @$internal
  @override
  ArchiveActions create() => ArchiveActions();
}

String _$archiveActionsHash() => r'ff8468b6a8b20631596608fe141a348b5009c26d';

/// Imperative actions for the Archive screen.

abstract class _$ArchiveActions extends $AsyncNotifier<void> {
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
