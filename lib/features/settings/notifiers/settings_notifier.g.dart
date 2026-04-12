// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads API keys on first watch and exposes save/delete actions.
/// Auto-disposes when the settings screen is not in view.

@ProviderFor(ApiKeysNotifier)
final apiKeysProvider = ApiKeysNotifierProvider._();

/// Loads API keys on first watch and exposes save/delete actions.
/// Auto-disposes when the settings screen is not in view.
final class ApiKeysNotifierProvider extends $AsyncNotifierProvider<ApiKeysNotifier, ApiKeysNotifierState> {
  /// Loads API keys on first watch and exposes save/delete actions.
  /// Auto-disposes when the settings screen is not in view.
  ApiKeysNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiKeysNotifierHash();

  @$internal
  @override
  ApiKeysNotifier create() => ApiKeysNotifier();
}

String _$apiKeysNotifierHash() => r'07a4080d3cde1cf6255e6f17195024e51075a798';

/// Loads API keys on first watch and exposes save/delete actions.
/// Auto-disposes when the settings screen is not in view.

abstract class _$ApiKeysNotifier extends $AsyncNotifier<ApiKeysNotifierState> {
  FutureOr<ApiKeysNotifierState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ApiKeysNotifierState>, ApiKeysNotifierState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ApiKeysNotifierState>, ApiKeysNotifierState>,
              AsyncValue<ApiKeysNotifierState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Loads general preferences on first watch and exposes setters.
/// Auto-disposes when the settings screen is not in view.

@ProviderFor(GeneralPrefsNotifier)
final generalPrefsProvider = GeneralPrefsNotifierProvider._();

/// Loads general preferences on first watch and exposes setters.
/// Auto-disposes when the settings screen is not in view.
final class GeneralPrefsNotifierProvider
    extends $AsyncNotifierProvider<GeneralPrefsNotifier, GeneralPrefsNotifierState> {
  /// Loads general preferences on first watch and exposes setters.
  /// Auto-disposes when the settings screen is not in view.
  GeneralPrefsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'generalPrefsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$generalPrefsNotifierHash();

  @$internal
  @override
  GeneralPrefsNotifier create() => GeneralPrefsNotifier();
}

String _$generalPrefsNotifierHash() => r'97a314b6c01be854700f5fb6661b29c7a4562025';

/// Loads general preferences on first watch and exposes setters.
/// Auto-disposes when the settings screen is not in view.

abstract class _$GeneralPrefsNotifier extends $AsyncNotifier<GeneralPrefsNotifierState> {
  FutureOr<GeneralPrefsNotifierState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GeneralPrefsNotifierState>, GeneralPrefsNotifierState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GeneralPrefsNotifierState>, GeneralPrefsNotifierState>,
              AsyncValue<GeneralPrefsNotifierState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Imperative actions that don't own observable state: wipe all data,
/// unarchive sessions, save a single API key, mark onboarding complete.

@ProviderFor(SettingsActions)
final settingsActionsProvider = SettingsActionsProvider._();

/// Imperative actions that don't own observable state: wipe all data,
/// unarchive sessions, save a single API key, mark onboarding complete.
final class SettingsActionsProvider extends $AsyncNotifierProvider<SettingsActions, void> {
  /// Imperative actions that don't own observable state: wipe all data,
  /// unarchive sessions, save a single API key, mark onboarding complete.
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

String _$settingsActionsHash() => r'bb64a9a4681a27827ecc649f5a51cae8d509cbf0';

/// Imperative actions that don't own observable state: wipe all data,
/// unarchive sessions, save a single API key, mark onboarding complete.

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
