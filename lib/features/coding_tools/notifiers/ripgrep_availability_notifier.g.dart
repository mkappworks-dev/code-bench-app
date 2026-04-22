// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ripgrep_availability_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Feature-layer state notifier for the ripgrep availability check.
/// Widgets watch [ripgrepAvailabilityProvider]; "Check again" calls [recheck].

@ProviderFor(RipgrepAvailabilityNotifier)
final ripgrepAvailabilityProvider = RipgrepAvailabilityNotifierProvider._();

/// Feature-layer state notifier for the ripgrep availability check.
/// Widgets watch [ripgrepAvailabilityProvider]; "Check again" calls [recheck].
final class RipgrepAvailabilityNotifierProvider extends $AsyncNotifierProvider<RipgrepAvailabilityNotifier, bool> {
  /// Feature-layer state notifier for the ripgrep availability check.
  /// Widgets watch [ripgrepAvailabilityProvider]; "Check again" calls [recheck].
  RipgrepAvailabilityNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ripgrepAvailabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ripgrepAvailabilityNotifierHash();

  @$internal
  @override
  RipgrepAvailabilityNotifier create() => RipgrepAvailabilityNotifier();
}

String _$ripgrepAvailabilityNotifierHash() => r'edec1fa5a3cb93bc95aa0ed97efe65560b681399';

/// Feature-layer state notifier for the ripgrep availability check.
/// Widgets watch [ripgrepAvailabilityProvider]; "Check again" calls [recheck].

abstract class _$RipgrepAvailabilityNotifier extends $AsyncNotifier<bool> {
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
