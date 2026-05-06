// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_action_bar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Synchronously derives [TopActionBarState] from lower-level providers.

@ProviderFor(topActionBarState)
final topActionBarStateProvider = TopActionBarStateProvider._();

/// Synchronously derives [TopActionBarState] from lower-level providers.

final class TopActionBarStateProvider
    extends
        $FunctionalProvider<
          TopActionBarState,
          TopActionBarState,
          TopActionBarState
        >
    with $Provider<TopActionBarState> {
  /// Synchronously derives [TopActionBarState] from lower-level providers.
  TopActionBarStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topActionBarStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topActionBarStateHash();

  @$internal
  @override
  $ProviderElement<TopActionBarState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TopActionBarState create(Ref ref) {
    return topActionBarState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TopActionBarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TopActionBarState>(value),
    );
  }
}

String _$topActionBarStateHash() => r'989e88a0935717d23c5cceb5017fea8dce644c16';
