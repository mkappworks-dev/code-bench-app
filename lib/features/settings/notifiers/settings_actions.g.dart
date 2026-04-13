// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Imperative actions that don't own observable state: wipe all data,
/// save a single API key, mark onboarding complete.

@ProviderFor(SettingsActions)
final settingsActionsProvider = SettingsActionsProvider._();

/// Imperative actions that don't own observable state: wipe all data,
/// save a single API key, mark onboarding complete.
final class SettingsActionsProvider extends $AsyncNotifierProvider<SettingsActions, void> {
  /// Imperative actions that don't own observable state: wipe all data,
  /// save a single API key, mark onboarding complete.
  SettingsActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsActionsHash();

  @$internal
  @override
  SettingsActions create() => SettingsActions();
}

String _$settingsActionsHash() => r'a46e48f69ccd975998fdcbdb5479d43d3affc5cc';

/// Imperative actions that don't own observable state: wipe all data,
/// save a single API key, mark onboarding complete.

abstract class _$SettingsActions extends $AsyncNotifier<void> {
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
