// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SessionSystemPrompt)
final sessionSystemPromptProvider = SessionSystemPromptProvider._();

final class SessionSystemPromptProvider extends $NotifierProvider<SessionSystemPrompt, Map<String, String>> {
  SessionSystemPromptProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionSystemPromptProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionSystemPromptHash();

  @$internal
  @override
  SessionSystemPrompt create() => SessionSystemPrompt();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Map<String, String>>(value));
  }
}

String _$sessionSystemPromptHash() => r'cbf00e1c70fcc8c90707dd1122dea62958d5be1e';

abstract class _$SessionSystemPrompt extends $Notifier<Map<String, String>> {
  Map<String, String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, String>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, String>, Map<String, String>>,
              Map<String, String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ActiveSessionId)
final activeSessionIdProvider = ActiveSessionIdProvider._();

final class ActiveSessionIdProvider extends $NotifierProvider<ActiveSessionId, String?> {
  ActiveSessionIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSessionIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSessionIdHash();

  @$internal
  @override
  ActiveSessionId create() => ActiveSessionId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String?>(value));
  }
}

String _$activeSessionIdHash() => r'6bbf5f2b584ffb0f12be4776b38c2f3a6ca6575e';

abstract class _$ActiveSessionId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<String?, String?>, String?, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedModel)
final selectedModelProvider = SelectedModelProvider._();

final class SelectedModelProvider extends $NotifierProvider<SelectedModel, AIModel> {
  SelectedModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedModelHash();

  @$internal
  @override
  SelectedModel create() => SelectedModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AIModel value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AIModel>(value));
  }
}

String _$selectedModelHash() => r'23dfb6790a1851dce12997ba05dd7e1b89da9fcc';

abstract class _$SelectedModel extends $Notifier<AIModel> {
  AIModel build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AIModel, AIModel>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<AIModel, AIModel>, AIModel, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ChatMessages)
final chatMessagesProvider = ChatMessagesFamily._();

final class ChatMessagesProvider extends $AsyncNotifierProvider<ChatMessages, List<ChatMessage>> {
  ChatMessagesProvider._({required ChatMessagesFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'chatMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesHash();

  @override
  String toString() {
    return r'chatMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatMessages create() => ChatMessages();

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMessagesHash() => r'56dd04d7d6dfb300cca21c430b8064691f4a0be2';

final class ChatMessagesFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatMessages,
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          FutureOr<List<ChatMessage>>,
          String
        > {
  ChatMessagesFamily._()
    : super(
        retry: null,
        name: r'chatMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatMessagesProvider call(String sessionId) => ChatMessagesProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'chatMessagesProvider';
}

abstract class _$ChatMessages extends $AsyncNotifier<List<ChatMessage>> {
  late final _$args = ref.$arg as String;
  String get sessionId => _$args;

  FutureOr<List<ChatMessage>> build(String sessionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<ChatMessage>>, List<ChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatMessage>>, List<ChatMessage>>,
              AsyncValue<List<ChatMessage>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(chatSessions)
final chatSessionsProvider = ChatSessionsProvider._();

final class ChatSessionsProvider
    extends $FunctionalProvider<AsyncValue<List<ChatSession>>, List<ChatSession>, Stream<List<ChatSession>>>
    with $FutureModifier<List<ChatSession>>, $StreamProvider<List<ChatSession>> {
  ChatSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<ChatSession>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatSession>> create(Ref ref) {
    return chatSessions(ref);
  }
}

String _$chatSessionsHash() => r'bd92b56150cdba1b0318a6538773f19e9755be19';

@ProviderFor(projectSessions)
final projectSessionsProvider = ProjectSessionsFamily._();

final class ProjectSessionsProvider
    extends $FunctionalProvider<AsyncValue<List<ChatSession>>, List<ChatSession>, Stream<List<ChatSession>>>
    with $FutureModifier<List<ChatSession>>, $StreamProvider<List<ChatSession>> {
  ProjectSessionsProvider._({required ProjectSessionsFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'projectSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectSessionsHash();

  @override
  String toString() {
    return r'projectSessionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatSession>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatSession>> create(Ref ref) {
    final argument = this.argument as String;
    return projectSessions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectSessionsHash() => r'035aba6e7325f7e246c3dc25c052fcc4cee5a5a0';

final class ProjectSessionsFamily extends $Family with $FunctionalFamilyOverride<Stream<List<ChatSession>>, String> {
  ProjectSessionsFamily._()
    : super(
        retry: null,
        name: r'projectSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProjectSessionsProvider call(String projectId) => ProjectSessionsProvider._(argument: projectId, from: this);

  @override
  String toString() => r'projectSessionsProvider';
}

@ProviderFor(archivedSessions)
final archivedSessionsProvider = ArchivedSessionsProvider._();

final class ArchivedSessionsProvider
    extends $FunctionalProvider<AsyncValue<List<ChatSession>>, List<ChatSession>, Stream<List<ChatSession>>>
    with $FutureModifier<List<ChatSession>>, $StreamProvider<List<ChatSession>> {
  ArchivedSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archivedSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archivedSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<ChatSession>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatSession>> create(Ref ref) {
    return archivedSessions(ref);
  }
}

String _$archivedSessionsHash() => r'ac4a8fe2f5367fe1e8d70a0b1ccde35be9c98173';

@ProviderFor(AppliedChanges)
final appliedChangesProvider = AppliedChangesProvider._();

final class AppliedChangesProvider extends $NotifierProvider<AppliedChanges, Map<String, List<AppliedChange>>> {
  AppliedChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appliedChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appliedChangesHash();

  @$internal
  @override
  AppliedChanges create() => AppliedChanges();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<AppliedChange>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<AppliedChange>>>(value),
    );
  }
}

String _$appliedChangesHash() => r'2f1446537e686532ec607fd36b2475b2adf7d9f9';

abstract class _$AppliedChanges extends $Notifier<Map<String, List<AppliedChange>>> {
  Map<String, List<AppliedChange>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, List<AppliedChange>>, Map<String, List<AppliedChange>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, List<AppliedChange>>, Map<String, List<AppliedChange>>>,
              Map<String, List<AppliedChange>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ActiveMessageId)
final activeMessageIdProvider = ActiveMessageIdProvider._();

final class ActiveMessageIdProvider extends $NotifierProvider<ActiveMessageId, String?> {
  ActiveMessageIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeMessageIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeMessageIdHash();

  @$internal
  @override
  ActiveMessageId create() => ActiveMessageId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String?>(value));
  }
}

String _$activeMessageIdHash() => r'd627282d12802c332c95db784dade7149af8531a';

abstract class _$ActiveMessageId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<String?, String?>, String?, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ChangesPanelVisible)
final changesPanelVisibleProvider = ChangesPanelVisibleProvider._();

final class ChangesPanelVisibleProvider extends $NotifierProvider<ChangesPanelVisible, bool> {
  ChangesPanelVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changesPanelVisibleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changesPanelVisibleHash();

  @$internal
  @override
  ChangesPanelVisible create() => ChangesPanelVisible();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$changesPanelVisibleHash() => r'f81f3dbb0aeb38ffb87bbd472846a33f732504e3';

abstract class _$ChangesPanelVisible extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
