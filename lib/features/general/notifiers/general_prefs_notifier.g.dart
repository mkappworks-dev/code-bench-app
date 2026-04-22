// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'general_prefs_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$generalPrefsNotifierHash() => r'f8a1b2b5c30ea93a4698afdcfc3a409a86a0544d';

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
