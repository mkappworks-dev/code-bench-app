// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionSystemPromptHash() =>
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

/// See also [SessionSystemPrompt].
@ProviderFor(SessionSystemPrompt)
final sessionSystemPromptProvider =
    NotifierProvider<SessionSystemPrompt, Map<String, String>>.internal(
  SessionSystemPrompt.new,
  name: r'sessionSystemPromptProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sessionSystemPromptHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SessionSystemPrompt = Notifier<Map<String, String>>;
String _$chatSessionsHash() => r'bd92b56150cdba1b0318a6538773f19e9755be19';

/// See also [chatSessions].
@ProviderFor(chatSessions)
final chatSessionsProvider =
    AutoDisposeStreamProvider<List<ChatSession>>.internal(
  chatSessions,
  name: r'chatSessionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatSessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatSessionsRef = AutoDisposeStreamProviderRef<List<ChatSession>>;
String _$activeSessionIdHash() => r'6bbf5f2b584ffb0f12be4776b38c2f3a6ca6575e';

/// See also [ActiveSessionId].
@ProviderFor(ActiveSessionId)
final activeSessionIdProvider =
    NotifierProvider<ActiveSessionId, String?>.internal(
  ActiveSessionId.new,
  name: r'activeSessionIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSessionIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveSessionId = Notifier<String?>;
String _$selectedModelHash() => r'23dfb6790a1851dce12997ba05dd7e1b89da9fcc';

/// See also [SelectedModel].
@ProviderFor(SelectedModel)
final selectedModelProvider = NotifierProvider<SelectedModel, AIModel>.internal(
  SelectedModel.new,
  name: r'selectedModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedModel = Notifier<AIModel>;
String _$chatMessagesHash() => r'66b3e0472bac949f586adf0de1c32b8c4bacd15d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ChatMessages
    extends BuildlessAutoDisposeAsyncNotifier<List<ChatMessage>> {
  late final String sessionId;

  FutureOr<List<ChatMessage>> build(String sessionId);
}

/// See also [ChatMessages].
@ProviderFor(ChatMessages)
const chatMessagesProvider = ChatMessagesFamily();

/// See also [ChatMessages].
class ChatMessagesFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// See also [ChatMessages].
  const ChatMessagesFamily();

  /// See also [ChatMessages].
  ChatMessagesProvider call(String sessionId) {
    return ChatMessagesProvider(sessionId);
  }

  @override
  ChatMessagesProvider getProviderOverride(
    covariant ChatMessagesProvider provider,
  ) {
    return call(provider.sessionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatMessagesProvider';
}

/// See also [ChatMessages].
class ChatMessagesProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ChatMessages, List<ChatMessage>> {
  /// See also [ChatMessages].
  ChatMessagesProvider(String sessionId)
      : this._internal(
          () => ChatMessages()..sessionId = sessionId,
          from: chatMessagesProvider,
          name: r'chatMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatMessagesHash,
          dependencies: ChatMessagesFamily._dependencies,
          allTransitiveDependencies:
              ChatMessagesFamily._allTransitiveDependencies,
          sessionId: sessionId,
        );

  ChatMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sessionId,
  }) : super.internal();

  final String sessionId;

  @override
  FutureOr<List<ChatMessage>> runNotifierBuild(
    covariant ChatMessages notifier,
  ) {
    return notifier.build(sessionId);
  }

  @override
  Override overrideWith(ChatMessages Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatMessagesProvider._internal(
        () => create()..sessionId = sessionId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sessionId: sessionId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ChatMessages, List<ChatMessage>>
      createElement() {
    return _ChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatMessagesRef
    on AutoDisposeAsyncNotifierProviderRef<List<ChatMessage>> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _ChatMessagesProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChatMessages,
        List<ChatMessage>> with ChatMessagesRef {
  _ChatMessagesProviderElement(super.provider);

  @override
  String get sessionId => (origin as ChatMessagesProvider).sessionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
