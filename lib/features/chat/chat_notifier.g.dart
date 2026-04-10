// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatSessionsHash() => r'bd92b56150cdba1b0318a6538773f19e9755be19';

/// See also [chatSessions].
@ProviderFor(chatSessions)
final chatSessionsProvider = AutoDisposeStreamProvider<List<ChatSession>>.internal(
  chatSessions,
  name: r'chatSessionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : _$chatSessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatSessionsRef = AutoDisposeStreamProviderRef<List<ChatSession>>;
String _$projectSessionsHash() => r'035aba6e7325f7e246c3dc25c052fcc4cee5a5a0';

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

/// See also [projectSessions].
@ProviderFor(projectSessions)
const projectSessionsProvider = ProjectSessionsFamily();

/// See also [projectSessions].
class ProjectSessionsFamily extends Family<AsyncValue<List<ChatSession>>> {
  /// See also [projectSessions].
  const ProjectSessionsFamily();

  /// See also [projectSessions].
  ProjectSessionsProvider call(
    String projectId,
  ) {
    return ProjectSessionsProvider(
      projectId,
    );
  }

  @override
  ProjectSessionsProvider getProviderOverride(
    covariant ProjectSessionsProvider provider,
  ) {
    return call(
      provider.projectId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies => _allTransitiveDependencies;

  @override
  String? get name => r'projectSessionsProvider';
}

/// See also [projectSessions].
class ProjectSessionsProvider extends AutoDisposeStreamProvider<List<ChatSession>> {
  /// See also [projectSessions].
  ProjectSessionsProvider(
    String projectId,
  ) : this._internal(
          (ref) => projectSessions(
            ref as ProjectSessionsRef,
            projectId,
          ),
          from: projectSessionsProvider,
          name: r'projectSessionsProvider',
          debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : _$projectSessionsHash,
          dependencies: ProjectSessionsFamily._dependencies,
          allTransitiveDependencies: ProjectSessionsFamily._allTransitiveDependencies,
          projectId: projectId,
        );

  ProjectSessionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final String projectId;

  @override
  Override overrideWith(
    Stream<List<ChatSession>> Function(ProjectSessionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProjectSessionsProvider._internal(
        (ref) => create(ref as ProjectSessionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ChatSession>> createElement() {
    return _ProjectSessionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectSessionsProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProjectSessionsRef on AutoDisposeStreamProviderRef<List<ChatSession>> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _ProjectSessionsProviderElement extends AutoDisposeStreamProviderElement<List<ChatSession>>
    with ProjectSessionsRef {
  _ProjectSessionsProviderElement(super.provider);

  @override
  String get projectId => (origin as ProjectSessionsProvider).projectId;
}

String _$archivedSessionsHash() => r'ac4a8fe2f5367fe1e8d70a0b1ccde35be9c98173';

/// See also [archivedSessions].
@ProviderFor(archivedSessions)
final archivedSessionsProvider = AutoDisposeStreamProvider<List<ChatSession>>.internal(
  archivedSessions,
  name: r'archivedSessionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : _$archivedSessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ArchivedSessionsRef = AutoDisposeStreamProviderRef<List<ChatSession>>;
String _$sessionSystemPromptHash() => r'54342a5fe93c9a7edc16f005fa6089d539e394b9';

/// See also [SessionSystemPrompt].
@ProviderFor(SessionSystemPrompt)
final sessionSystemPromptProvider = NotifierProvider<SessionSystemPrompt, Map<String, String>>.internal(
  SessionSystemPrompt.new,
  name: r'sessionSystemPromptProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : _$sessionSystemPromptHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SessionSystemPrompt = Notifier<Map<String, String>>;
String _$activeSessionIdHash() => r'6bbf5f2b584ffb0f12be4776b38c2f3a6ca6575e';

/// See also [ActiveSessionId].
@ProviderFor(ActiveSessionId)
final activeSessionIdProvider = NotifierProvider<ActiveSessionId, String?>.internal(
  ActiveSessionId.new,
  name: r'activeSessionIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : _$activeSessionIdHash,
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
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : _$selectedModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedModel = Notifier<AIModel>;
String _$chatMessagesHash() => r'66b3e0472bac949f586adf0de1c32b8c4bacd15d';

abstract class _$ChatMessages extends BuildlessAutoDisposeAsyncNotifier<List<ChatMessage>> {
  late final String sessionId;

  FutureOr<List<ChatMessage>> build(
    String sessionId,
  );
}

/// See also [ChatMessages].
@ProviderFor(ChatMessages)
const chatMessagesProvider = ChatMessagesFamily();

/// See also [ChatMessages].
class ChatMessagesFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// See also [ChatMessages].
  const ChatMessagesFamily();

  /// See also [ChatMessages].
  ChatMessagesProvider call(
    String sessionId,
  ) {
    return ChatMessagesProvider(
      sessionId,
    );
  }

  @override
  ChatMessagesProvider getProviderOverride(
    covariant ChatMessagesProvider provider,
  ) {
    return call(
      provider.sessionId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies => _allTransitiveDependencies;

  @override
  String? get name => r'chatMessagesProvider';
}

/// See also [ChatMessages].
class ChatMessagesProvider extends AutoDisposeAsyncNotifierProviderImpl<ChatMessages, List<ChatMessage>> {
  /// See also [ChatMessages].
  ChatMessagesProvider(
    String sessionId,
  ) : this._internal(
          () => ChatMessages()..sessionId = sessionId,
          from: chatMessagesProvider,
          name: r'chatMessagesProvider',
          debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : _$chatMessagesHash,
          dependencies: ChatMessagesFamily._dependencies,
          allTransitiveDependencies: ChatMessagesFamily._allTransitiveDependencies,
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
    return notifier.build(
      sessionId,
    );
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
  AutoDisposeAsyncNotifierProviderElement<ChatMessages, List<ChatMessage>> createElement() {
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
mixin ChatMessagesRef on AutoDisposeAsyncNotifierProviderRef<List<ChatMessage>> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _ChatMessagesProviderElement extends AutoDisposeAsyncNotifierProviderElement<ChatMessages, List<ChatMessage>>
    with ChatMessagesRef {
  _ChatMessagesProviderElement(super.provider);

  @override
  String get sessionId => (origin as ChatMessagesProvider).sessionId;
}

String _$appliedChangesHash() => r'74ef502b923552c950587dc27d4ac6c1a4f65bcd';

/// See also [AppliedChanges].
@ProviderFor(AppliedChanges)
final appliedChangesProvider = NotifierProvider<AppliedChanges, Map<String, List<AppliedChange>>>.internal(
  AppliedChanges.new,
  name: r'appliedChangesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : _$appliedChangesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppliedChanges = Notifier<Map<String, List<AppliedChange>>>;
String _$changesPanelVisibleHash() => r'eff3a5e9901e430955b5f80c2824460a5064158b';

/// See also [ChangesPanelVisible].
@ProviderFor(ChangesPanelVisible)
final changesPanelVisibleProvider = NotifierProvider<ChangesPanelVisible, bool>.internal(
  ChangesPanelVisible.new,
  name: r'changesPanelVisibleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : _$changesPanelVisibleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChangesPanelVisible = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
