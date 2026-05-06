// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_stream_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatStreamService)
final chatStreamServiceProvider = ChatStreamServiceProvider._();

final class ChatStreamServiceProvider
    extends $FunctionalProvider<ChatStreamService, ChatStreamService, ChatStreamService>
    with $Provider<ChatStreamService> {
  ChatStreamServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatStreamServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatStreamServiceHash();

  @$internal
  @override
  $ProviderElement<ChatStreamService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ChatStreamService create(Ref ref) {
    return chatStreamService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatStreamService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ChatStreamService>(value));
  }
}

String _$chatStreamServiceHash() => r'847f69aa071a33f4fe48fa1d27012e4ec4786a4d';
