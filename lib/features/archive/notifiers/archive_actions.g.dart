// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ArchiveActions)
final archiveActionsProvider = ArchiveActionsProvider._();

final class ArchiveActionsProvider
    extends $AsyncNotifierProvider<ArchiveActions, void> {
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

String _$archiveActionsHash() => r'b2bc3326ad25a09b91ad2514489739fd46dd5afa';

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
