// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_tools_preferences.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(codingToolsPreferences)
final codingToolsPreferencesProvider = CodingToolsPreferencesProvider._();

final class CodingToolsPreferencesProvider
    extends
        $FunctionalProvider<
          CodingToolsPreferences,
          CodingToolsPreferences,
          CodingToolsPreferences
        >
    with $Provider<CodingToolsPreferences> {
  CodingToolsPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'codingToolsPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$codingToolsPreferencesHash();

  @$internal
  @override
  $ProviderElement<CodingToolsPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CodingToolsPreferences create(Ref ref) {
    return codingToolsPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CodingToolsPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CodingToolsPreferences>(value),
    );
  }
}

String _$codingToolsPreferencesHash() =>
    r'91b63a335088c7a07f8a4a0c5c76ec64469dddc4';
