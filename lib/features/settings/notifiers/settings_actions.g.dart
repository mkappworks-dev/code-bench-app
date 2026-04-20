// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Imperative actions for onboarding and data wipe. API key test/save
/// methods have moved to ProvidersActions in features/providers/.

@ProviderFor(SettingsActions)
final settingsActionsProvider = SettingsActionsProvider._();

/// Imperative actions for onboarding and data wipe. API key test/save
/// methods have moved to ProvidersActions in features/providers/.
final class SettingsActionsProvider
    extends $AsyncNotifierProvider<SettingsActions, void> {
  /// Imperative actions for onboarding and data wipe. API key test/save
  /// methods have moved to ProvidersActions in features/providers/.
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

String _$settingsActionsHash() => r'df4c363605fa2574b95359880b2233efba0165ad';

/// Imperative actions for onboarding and data wipe. API key test/save
/// methods have moved to ProvidersActions in features/providers/.

abstract class _$SettingsActions extends $AsyncNotifier<void> {
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
