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
    extends
        $FunctionalProvider<
          ChatStreamService,
          ChatStreamService,
          ChatStreamService
        >
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
  $ProviderElement<ChatStreamService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatStreamService create(Ref ref) {
    return chatStreamService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatStreamService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatStreamService>(value),
    );
  }
}

String _$chatStreamServiceHash() => r'847f69aa071a33f4fe48fa1d27012e4ec4786a4d';

@ProviderFor(chatStreamWatch)
final chatStreamWatchProvider = ChatStreamWatchFamily._();

final class ChatStreamWatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChatStreamState>,
          ChatStreamState,
          Stream<ChatStreamState>
        >
    with $FutureModifier<ChatStreamState>, $StreamProvider<ChatStreamState> {
  ChatStreamWatchProvider._({
    required ChatStreamWatchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatStreamWatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatStreamWatchHash();

  @override
  String toString() {
    return r'chatStreamWatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ChatStreamState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ChatStreamState> create(Ref ref) {
    final argument = this.argument as String;
    return chatStreamWatch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatStreamWatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatStreamWatchHash() => r'391338372a632f1221847ee74fa53c9e261ea68f';

final class ChatStreamWatchFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ChatStreamState>, String> {
  ChatStreamWatchFamily._()
    : super(
        retry: null,
        name: r'chatStreamWatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatStreamWatchProvider call(String sessionId) =>
      ChatStreamWatchProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'chatStreamWatchProvider';
}
