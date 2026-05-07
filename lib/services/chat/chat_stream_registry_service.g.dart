// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_stream_registry_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatStreamRegistryService)
final chatStreamRegistryServiceProvider = ChatStreamRegistryServiceProvider._();

final class ChatStreamRegistryServiceProvider
    extends $FunctionalProvider<ChatStreamRegistryService, ChatStreamRegistryService, ChatStreamRegistryService>
    with $Provider<ChatStreamRegistryService> {
  ChatStreamRegistryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatStreamRegistryServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatStreamRegistryServiceHash();

  @$internal
  @override
  $ProviderElement<ChatStreamRegistryService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ChatStreamRegistryService create(Ref ref) {
    return chatStreamRegistryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatStreamRegistryService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ChatStreamRegistryService>(value));
  }
}

String _$chatStreamRegistryServiceHash() => r'511212f0868b4b9f69c3ac446608b73ec82d4b04';
