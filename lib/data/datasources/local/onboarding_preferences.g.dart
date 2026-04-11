// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_preferences.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(onboardingPreferences)
final onboardingPreferencesProvider = OnboardingPreferencesProvider._();

final class OnboardingPreferencesProvider
    extends $FunctionalProvider<OnboardingPreferences, OnboardingPreferences, OnboardingPreferences>
    with $Provider<OnboardingPreferences> {
  OnboardingPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingPreferencesHash();

  @$internal
  @override
  $ProviderElement<OnboardingPreferences> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  OnboardingPreferences create(Ref ref) {
    return onboardingPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingPreferences value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<OnboardingPreferences>(value));
  }
}

String _$onboardingPreferencesHash() => r'3c6c84da8828282f8d3848a4a4a2bd3a14e5a646';
