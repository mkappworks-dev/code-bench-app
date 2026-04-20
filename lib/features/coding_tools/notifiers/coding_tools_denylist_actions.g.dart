// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_tools_denylist_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CodingToolsDenylistActions)
final codingToolsDenylistActionsProvider =
    CodingToolsDenylistActionsProvider._();

final class CodingToolsDenylistActionsProvider
    extends $AsyncNotifierProvider<CodingToolsDenylistActions, void> {
  CodingToolsDenylistActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'codingToolsDenylistActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$codingToolsDenylistActionsHash();

  @$internal
  @override
  CodingToolsDenylistActions create() => CodingToolsDenylistActions();
}

String _$codingToolsDenylistActionsHash() =>
    r'9757d73c20c0a0f59632b516774000c69543f012';

abstract class _$CodingToolsDenylistActions extends $AsyncNotifier<void> {
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
