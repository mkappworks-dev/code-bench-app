// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ripgrep_availability_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Feature-layer state notifier for the ripgrep availability check.
/// Widgets watch [ripgrepAvailabilityStateProvider]; "Check again" calls [recheck].

@ProviderFor(RipgrepAvailabilityStateNotifier)
final ripgrepAvailabilityStateProvider = RipgrepAvailabilityStateNotifierProvider._();

/// Feature-layer state notifier for the ripgrep availability check.
/// Widgets watch [ripgrepAvailabilityStateProvider]; "Check again" calls [recheck].
final class RipgrepAvailabilityStateNotifierProvider
    extends $AsyncNotifierProvider<RipgrepAvailabilityStateNotifier, bool> {
  /// Feature-layer state notifier for the ripgrep availability check.
  /// Widgets watch [ripgrepAvailabilityStateProvider]; "Check again" calls [recheck].
  RipgrepAvailabilityStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ripgrepAvailabilityStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ripgrepAvailabilityStateNotifierHash();

  @$internal
  @override
  RipgrepAvailabilityStateNotifier create() => RipgrepAvailabilityStateNotifier();
}

String _$ripgrepAvailabilityStateNotifierHash() => r'f8ab68db9907f5f30b7fb7e7310ab8523ca65cb2';

/// Feature-layer state notifier for the ripgrep availability check.
/// Widgets watch [ripgrepAvailabilityStateProvider]; "Check again" calls [recheck].

abstract class _$RipgrepAvailabilityStateNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<bool>, bool>, AsyncValue<bool>, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
