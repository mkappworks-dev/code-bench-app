// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'general_preferences.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(generalPreferences)
final generalPreferencesProvider = GeneralPreferencesProvider._();

final class GeneralPreferencesProvider
    extends $FunctionalProvider<GeneralPreferences, GeneralPreferences, GeneralPreferences>
    with $Provider<GeneralPreferences> {
  GeneralPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'generalPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$generalPreferencesHash();

  @$internal
  @override
  $ProviderElement<GeneralPreferences> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  GeneralPreferences create(Ref ref) {
    return generalPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeneralPreferences value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<GeneralPreferences>(value));
  }
}

String _$generalPreferencesHash() => r'45c3499e243189d6a6bd66afdeb2736ffba541dc';
