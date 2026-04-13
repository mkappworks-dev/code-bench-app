// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_bar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Synchronously derives [StatusBarState] from lower-level providers.
///
/// [changesPanelVisibleProvider] is intentionally excluded — it is a UI-only
/// toggle that the status bar both reads and writes, so it stays a direct
/// [ref.watch] in the widget.

@ProviderFor(statusBarState)
final statusBarStateProvider = StatusBarStateProvider._();

/// Synchronously derives [StatusBarState] from lower-level providers.
///
/// [changesPanelVisibleProvider] is intentionally excluded — it is a UI-only
/// toggle that the status bar both reads and writes, so it stays a direct
/// [ref.watch] in the widget.

final class StatusBarStateProvider extends $FunctionalProvider<StatusBarState, StatusBarState, StatusBarState>
    with $Provider<StatusBarState> {
  /// Synchronously derives [StatusBarState] from lower-level providers.
  ///
  /// [changesPanelVisibleProvider] is intentionally excluded — it is a UI-only
  /// toggle that the status bar both reads and writes, so it stays a direct
  /// [ref.watch] in the widget.
  StatusBarStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statusBarStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statusBarStateHash();

  @$internal
  @override
  $ProviderElement<StatusBarState> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  StatusBarState create(Ref ref) {
    return statusBarState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatusBarState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<StatusBarState>(value));
  }
}

String _$statusBarStateHash() => r'c4d1c0fdf192e8342fbccc338caa9a89b4ec3641';
