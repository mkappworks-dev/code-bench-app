// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_stream_registry.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatStreamRegistry)
final chatStreamRegistryProvider = ChatStreamRegistryProvider._();

final class ChatStreamRegistryProvider
    extends $FunctionalProvider<ChatStreamRegistry, ChatStreamRegistry, ChatStreamRegistry>
    with $Provider<ChatStreamRegistry> {
  ChatStreamRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatStreamRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatStreamRegistryHash();

  @$internal
  @override
  $ProviderElement<ChatStreamRegistry> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ChatStreamRegistry create(Ref ref) {
    return chatStreamRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatStreamRegistry value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ChatStreamRegistry>(value));
  }
}

String _$chatStreamRegistryHash() => r'8490807d192422efe90298a7cabedc8a5aa5218d';
