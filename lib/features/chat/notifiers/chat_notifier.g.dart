// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SessionSystemPromptNotifier)
final sessionSystemPromptProvider = SessionSystemPromptNotifierProvider._();

final class SessionSystemPromptNotifierProvider
    extends
        $NotifierProvider<SessionSystemPromptNotifier, Map<String, String>> {
  SessionSystemPromptNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$sessionSystemPromptNotifierHash();

  @$internal
  @override
  SessionSystemPromptNotifier create() => SessionSystemPromptNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$sessionSystemPromptNotifierHash() =>
    r'5f1b78b2480e40042244ebc172d7e54fef83145b';

abstract class _$SessionSystemPromptNotifier
    extends $Notifier<Map<String, String>> {
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

@ProviderFor(ActiveSessionIdNotifier)
final activeSessionIdProvider = ActiveSessionIdNotifierProvider._();

final class ActiveSessionIdNotifierProvider
    extends $NotifierProvider<ActiveSessionIdNotifier, String?> {
  ActiveSessionIdNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$activeSessionIdNotifierHash();

  @$internal
  @override
  ActiveSessionIdNotifier create() => ActiveSessionIdNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeSessionIdNotifierHash() =>
    r'97b2e50007213b69dca36097c5699bc476f3103f';

abstract class _$ActiveSessionIdNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedModelNotifier)
final selectedModelProvider = SelectedModelNotifierProvider._();

final class SelectedModelNotifierProvider
    extends $NotifierProvider<SelectedModelNotifier, AIModel> {
  SelectedModelNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$selectedModelNotifierHash();

  @$internal
  @override
  SelectedModelNotifier create() => SelectedModelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AIModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AIModel>(value),
    );
  }
}

String _$selectedModelNotifierHash() =>
    r'558ad12f6ca7e983bc23105b18e55941c75294d0';

abstract class _$SelectedModelNotifier extends $Notifier<AIModel> {
  AIModel build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AIModel, AIModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AIModel, AIModel>,
              AIModel,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SessionModeNotifier)
final sessionModeProvider = SessionModeNotifierProvider._();

final class SessionModeNotifierProvider
    extends $NotifierProvider<SessionModeNotifier, ChatMode> {
  SessionModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionModeNotifierHash();

  @$internal
  @override
  SessionModeNotifier create() => SessionModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatMode>(value),
    );
  }
}

String _$sessionModeNotifierHash() =>
    r'b8c356e232ff88919ad9745362ddb56a771662f8';

abstract class _$SessionModeNotifier extends $Notifier<ChatMode> {
  ChatMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatMode, ChatMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatMode, ChatMode>,
              ChatMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SessionEffortNotifier)
final sessionEffortProvider = SessionEffortNotifierProvider._();

final class SessionEffortNotifierProvider
    extends $NotifierProvider<SessionEffortNotifier, ChatEffort> {
  SessionEffortNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionEffortProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionEffortNotifierHash();

  @$internal
  @override
  SessionEffortNotifier create() => SessionEffortNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatEffort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatEffort>(value),
    );
  }
}

String _$sessionEffortNotifierHash() =>
    r'e4386bf903ddab10f0c82d3c59776ea26620bcb8';

abstract class _$SessionEffortNotifier extends $Notifier<ChatEffort> {
  ChatEffort build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatEffort, ChatEffort>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatEffort, ChatEffort>,
              ChatEffort,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SessionPermissionNotifier)
final sessionPermissionProvider = SessionPermissionNotifierProvider._();

final class SessionPermissionNotifierProvider
    extends $NotifierProvider<SessionPermissionNotifier, ChatPermission> {
  SessionPermissionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionPermissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionPermissionNotifierHash();

  @$internal
  @override
  SessionPermissionNotifier create() => SessionPermissionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatPermission value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatPermission>(value),
    );
  }
}

String _$sessionPermissionNotifierHash() =>
    r'2f2086b673f54c3115048e16533123d9493593af';

abstract class _$SessionPermissionNotifier extends $Notifier<ChatPermission> {
  ChatPermission build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatPermission, ChatPermission>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatPermission, ChatPermission>,
              ChatPermission,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ChatMessagesNotifier)
final chatMessagesProvider = ChatMessagesNotifierFamily._();

final class ChatMessagesNotifierProvider
    extends $AsyncNotifierProvider<ChatMessagesNotifier, List<ChatMessage>> {
  ChatMessagesNotifierProvider._({
    required ChatMessagesNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesNotifierHash();

  @override
  String toString() {
    return r'chatMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatMessagesNotifier create() => ChatMessagesNotifier();

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMessagesNotifierHash() =>
    r'980f1e8af88d9c4cbecc2e5de840da30ef33cdaa';

final class ChatMessagesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatMessagesNotifier,
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          FutureOr<List<ChatMessage>>,
          String
        > {
  ChatMessagesNotifierFamily._()
    : super(
        retry: null,
        name: r'chatMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatMessagesNotifierProvider call(String sessionId) =>
      ChatMessagesNotifierProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'chatMessagesProvider';
}

abstract class _$ChatMessagesNotifier
    extends $AsyncNotifier<List<ChatMessage>> {
  late final _$args = ref.$arg as String;
  String get sessionId => _$args;

  FutureOr<List<ChatMessage>> build(String sessionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ChatMessage>>, List<ChatMessage>>;
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
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatSession>>,
          List<ChatSession>,
          Stream<List<ChatSession>>
        >
    with
        $FutureModifier<List<ChatSession>>,
        $StreamProvider<List<ChatSession>> {
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
  $StreamProviderElement<List<ChatSession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatSession>> create(Ref ref) {
    return chatSessions(ref);
  }
}

String _$chatSessionsHash() => r'a17b925c93b2621c926536e1face4074194e2b9b';

@ProviderFor(projectSessions)
final projectSessionsProvider = ProjectSessionsFamily._();

final class ProjectSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatSession>>,
          List<ChatSession>,
          Stream<List<ChatSession>>
        >
    with
        $FutureModifier<List<ChatSession>>,
        $StreamProvider<List<ChatSession>> {
  ProjectSessionsProvider._({
    required ProjectSessionsFamily super.from,
    required String super.argument,
  }) : super(
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
  $StreamProviderElement<List<ChatSession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

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

String _$projectSessionsHash() => r'3e2ad906ce98f2f38860c59588633dbe792da80e';

final class ProjectSessionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ChatSession>>, String> {
  ProjectSessionsFamily._()
    : super(
        retry: null,
        name: r'projectSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProjectSessionsProvider call(String projectId) =>
      ProjectSessionsProvider._(argument: projectId, from: this);

  @override
  String toString() => r'projectSessionsProvider';
}

@ProviderFor(archivedSessions)
final archivedSessionsProvider = ArchivedSessionsProvider._();

final class ArchivedSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatSession>>,
          List<ChatSession>,
          Stream<List<ChatSession>>
        >
    with
        $FutureModifier<List<ChatSession>>,
        $StreamProvider<List<ChatSession>> {
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
  $StreamProviderElement<List<ChatSession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatSession>> create(Ref ref) {
    return archivedSessions(ref);
  }
}

String _$archivedSessionsHash() => r'e0fd303c99f8aed669324b1460f9c7746488d92a';

@ProviderFor(AppliedChangesNotifier)
final appliedChangesProvider = AppliedChangesNotifierProvider._();

final class AppliedChangesNotifierProvider
    extends
        $NotifierProvider<
          AppliedChangesNotifier,
          Map<String, List<AppliedChange>>
        > {
  AppliedChangesNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$appliedChangesNotifierHash();

  @$internal
  @override
  AppliedChangesNotifier create() => AppliedChangesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<AppliedChange>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<AppliedChange>>>(
        value,
      ),
    );
  }
}

String _$appliedChangesNotifierHash() =>
    r'0e5aeb94b129df8fe39ebbaeb1757e5c84ea497f';

abstract class _$AppliedChangesNotifier
    extends $Notifier<Map<String, List<AppliedChange>>> {
  Map<String, List<AppliedChange>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, List<AppliedChange>>,
              Map<String, List<AppliedChange>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, List<AppliedChange>>,
                Map<String, List<AppliedChange>>
              >,
              Map<String, List<AppliedChange>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ActiveMessageIdNotifier)
final activeMessageIdProvider = ActiveMessageIdNotifierProvider._();

final class ActiveMessageIdNotifierProvider
    extends $NotifierProvider<ActiveMessageIdNotifier, String?> {
  ActiveMessageIdNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$activeMessageIdNotifierHash();

  @$internal
  @override
  ActiveMessageIdNotifier create() => ActiveMessageIdNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeMessageIdNotifierHash() =>
    r'd3115d948a71ff4bfe5b208f9ad17fdf809c5ce7';

abstract class _$ActiveMessageIdNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ChangesPanelVisibleNotifier)
final changesPanelVisibleProvider = ChangesPanelVisibleNotifierProvider._();

final class ChangesPanelVisibleNotifierProvider
    extends $NotifierProvider<ChangesPanelVisibleNotifier, bool> {
  ChangesPanelVisibleNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$changesPanelVisibleNotifierHash();

  @$internal
  @override
  ChangesPanelVisibleNotifier create() => ChangesPanelVisibleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$changesPanelVisibleNotifierHash() =>
    r'61485d0b98c5342c00a038a1fa8f096407586301';

abstract class _$ChangesPanelVisibleNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
