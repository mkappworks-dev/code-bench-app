// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session_streaming.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatSessionStreaming)
final chatSessionStreamingProvider = ChatSessionStreamingFamily._();

final class ChatSessionStreamingProvider extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  ChatSessionStreamingProvider._({required ChatSessionStreamingFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'chatSessionStreamingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatSessionStreamingHash();

  @override
  String toString() {
    return r'chatSessionStreamingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as String;
    return chatSessionStreaming(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatSessionStreamingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatSessionStreamingHash() => r'd1f6bbea9d49a7b1bd932bc4ad98e64c7e276653';

final class ChatSessionStreamingFamily extends $Family with $FunctionalFamilyOverride<Stream<bool>, String> {
  ChatSessionStreamingFamily._()
    : super(
        retry: null,
        name: r'chatSessionStreamingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatSessionStreamingProvider call(String sessionId) =>
      ChatSessionStreamingProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'chatSessionStreamingProvider';
}
