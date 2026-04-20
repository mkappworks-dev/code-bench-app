// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_tools_denylist_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads the user's denylist divergence and rebuilds when the Actions
/// notifier invalidates this provider after a mutation.

@ProviderFor(CodingToolsDenylistNotifier)
final codingToolsDenylistProvider = CodingToolsDenylistNotifierProvider._();

/// Loads the user's denylist divergence and rebuilds when the Actions
/// notifier invalidates this provider after a mutation.
final class CodingToolsDenylistNotifierProvider
    extends $AsyncNotifierProvider<CodingToolsDenylistNotifier, CodingToolsDenylistState> {
  /// Loads the user's denylist divergence and rebuilds when the Actions
  /// notifier invalidates this provider after a mutation.
  CodingToolsDenylistNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'codingToolsDenylistProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$codingToolsDenylistNotifierHash();

  @$internal
  @override
  CodingToolsDenylistNotifier create() => CodingToolsDenylistNotifier();
}

String _$codingToolsDenylistNotifierHash() => r'254e0315828e34b4074ef2f314c39a2cfc292bd0';

/// Loads the user's denylist divergence and rebuilds when the Actions
/// notifier invalidates this provider after a mutation.

abstract class _$CodingToolsDenylistNotifier extends $AsyncNotifier<CodingToolsDenylistState> {
  FutureOr<CodingToolsDenylistState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CodingToolsDenylistState>, CodingToolsDenylistState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CodingToolsDenylistState>, CodingToolsDenylistState>,
              AsyncValue<CodingToolsDenylistState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
