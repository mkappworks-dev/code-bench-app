// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_input_bar_options_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Capabilities for the *currently selected* model on its active transport.
///
/// CLI providers (claude-cli, codex) advertise capabilities via their
/// `AIProviderDatasource`. HTTP providers route through `AIRepository` to
/// stay one rung above the datasource layer per the dependency rule.
/// Returns `null` when the API-keys prefs haven't loaded yet — the input
/// bar treats that as "transport unknown" and disables the strip.

@ProviderFor(chatInputBarOptions)
final chatInputBarOptionsProvider = ChatInputBarOptionsProvider._();

/// Capabilities for the *currently selected* model on its active transport.
///
/// CLI providers (claude-cli, codex) advertise capabilities via their
/// `AIProviderDatasource`. HTTP providers route through `AIRepository` to
/// stay one rung above the datasource layer per the dependency rule.
/// Returns `null` when the API-keys prefs haven't loaded yet — the input
/// bar treats that as "transport unknown" and disables the strip.

final class ChatInputBarOptionsProvider
    extends $FunctionalProvider<ProviderCapabilities?, ProviderCapabilities?, ProviderCapabilities?>
    with $Provider<ProviderCapabilities?> {
  /// Capabilities for the *currently selected* model on its active transport.
  ///
  /// CLI providers (claude-cli, codex) advertise capabilities via their
  /// `AIProviderDatasource`. HTTP providers route through `AIRepository` to
  /// stay one rung above the datasource layer per the dependency rule.
  /// Returns `null` when the API-keys prefs haven't loaded yet — the input
  /// bar treats that as "transport unknown" and disables the strip.
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

String _$chatInputBarOptionsHash() => r'e883eb249ff82a0c977df8f5d1dcdcab05505be0';
