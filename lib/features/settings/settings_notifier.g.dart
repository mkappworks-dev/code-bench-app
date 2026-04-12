// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads API keys on first watch and exposes save/delete actions.
/// Auto-disposes when the settings screen is not in view.

@ProviderFor(ApiKeys)
final apiKeysProvider = ApiKeysProvider._();

/// Loads API keys on first watch and exposes save/delete actions.
/// Auto-disposes when the settings screen is not in view.
final class ApiKeysProvider extends $AsyncNotifierProvider<ApiKeys, ApiKeysState> {
  /// Loads API keys on first watch and exposes save/delete actions.
  /// Auto-disposes when the settings screen is not in view.
  ApiKeysProvider._()
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
  String debugGetCreateSourceHash() => _$apiKeysHash();

  @$internal
  @override
  ApiKeys create() => ApiKeys();
}

String _$apiKeysHash() => r'7b73607582580b8db097c46a7f7f0622f201b515';

/// Loads API keys on first watch and exposes save/delete actions.
/// Auto-disposes when the settings screen is not in view.

abstract class _$ApiKeys extends $AsyncNotifier<ApiKeysState> {
  FutureOr<ApiKeysState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ApiKeysState>, ApiKeysState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ApiKeysState>, ApiKeysState>,
              AsyncValue<ApiKeysState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Loads general preferences on first watch and exposes setters.
/// Auto-disposes when the settings screen is not in view.

@ProviderFor(GeneralPrefs)
final generalPrefsProvider = GeneralPrefsProvider._();

/// Loads general preferences on first watch and exposes setters.
/// Auto-disposes when the settings screen is not in view.
final class GeneralPrefsProvider extends $AsyncNotifierProvider<GeneralPrefs, GeneralPrefsState> {
  /// Loads general preferences on first watch and exposes setters.
  /// Auto-disposes when the settings screen is not in view.
  GeneralPrefsProvider._()
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
  String debugGetCreateSourceHash() => _$generalPrefsHash();

  @$internal
  @override
  GeneralPrefs create() => GeneralPrefs();
}

String _$generalPrefsHash() => r'48d70efb752b24c440837a2e0a3cd465870b8105';

/// Loads general preferences on first watch and exposes setters.
/// Auto-disposes when the settings screen is not in view.

abstract class _$GeneralPrefs extends $AsyncNotifier<GeneralPrefsState> {
  FutureOr<GeneralPrefsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GeneralPrefsState>, GeneralPrefsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GeneralPrefsState>, GeneralPrefsState>,
              AsyncValue<GeneralPrefsState>,
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
final class SettingsActionsProvider extends $NotifierProvider<SettingsActions, void> {
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$settingsActionsHash() => r'5549063ed607a10188be18757d3a0d996c46891c';

/// Imperative actions that don't own observable state: wipe all data,
/// unarchive sessions, save a single API key, mark onboarding complete.

abstract class _$SettingsActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
