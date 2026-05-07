// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_input_bar_options_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Capabilities for the *currently selected* model on its active transport.
///
/// Function-style derived provider — no mutable state, only computes the
/// capability surface from `selectedModelProvider` + `apiKeysProvider` and
/// delegates the actual repository/datasource lookup to
/// [ProviderCapabilitiesService]. Returns `null` when prefs haven't loaded —
/// the input bar treats that as "transport unknown" and disables the strip.

@ProviderFor(chatInputBarOptions)
final chatInputBarOptionsProvider = ChatInputBarOptionsProvider._();

/// Capabilities for the *currently selected* model on its active transport.
///
/// Function-style derived provider — no mutable state, only computes the
/// capability surface from `selectedModelProvider` + `apiKeysProvider` and
/// delegates the actual repository/datasource lookup to
/// [ProviderCapabilitiesService]. Returns `null` when prefs haven't loaded —
/// the input bar treats that as "transport unknown" and disables the strip.

final class ChatInputBarOptionsProvider
    extends $FunctionalProvider<ProviderCapabilities?, ProviderCapabilities?, ProviderCapabilities?>
    with $Provider<ProviderCapabilities?> {
  /// Capabilities for the *currently selected* model on its active transport.
  ///
  /// Function-style derived provider — no mutable state, only computes the
  /// capability surface from `selectedModelProvider` + `apiKeysProvider` and
  /// delegates the actual repository/datasource lookup to
  /// [ProviderCapabilitiesService]. Returns `null` when prefs haven't loaded —
  /// the input bar treats that as "transport unknown" and disables the strip.
  ChatInputBarOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatInputBarOptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatInputBarOptionsHash();

  @$internal
  @override
  $ProviderElement<ProviderCapabilities?> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ProviderCapabilities? create(Ref ref) {
    return chatInputBarOptions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProviderCapabilities? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProviderCapabilities?>(value));
  }
}

String _$chatInputBarOptionsHash() => r'4032a70dbe9287705669d574362db21610dcdc7c';
