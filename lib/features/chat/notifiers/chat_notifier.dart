import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/ai/models/auth_status.dart';
import '../../../data/ai/models/provider_setting_drop.dart';
import '../../../data/chat/models/agent_failure.dart';
import '../../../data/chat/models/transport_readiness.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/apply/models/applied_change.dart';
import '../../../data/shared/session_settings.dart';
import '../../../data/shared/chat_message.dart';
import '../../../data/session/models/chat_session.dart';
import '../../../services/ai_provider/ai_provider_service.dart';
import '../../../services/chat/chat_stream_service.dart';
import '../../../services/chat/chat_stream_state.dart';
import '../../../services/session/session_service.dart';
import '../../project_sidebar/notifiers/project_sidebar_notifier.dart';
import '../../mcp_servers/notifiers/mcp_server_status_notifier.dart';
import '../../providers/notifiers/providers_notifier.dart';
import 'agent_cancel_notifier.dart';
import 'agent_permission_request_notifier.dart';
import 'chat_input_bar_options_provider.dart';
import 'dropped_settings_notifier.dart';
import 'transport_readiness_notifier.dart';

part 'chat_notifier.g.dart';

@Riverpod(keepAlive: true)
class SessionSystemPromptNotifier extends _$SessionSystemPromptNotifier {
  @override
  Map<String, String> build() => {};

  void setPrompt(String sessionId, String prompt) {
    state = Map.of(state)..[sessionId] = prompt;
  }

  String? getPrompt(String sessionId) => state[sessionId];
}

@Riverpod(keepAlive: true)
class ActiveSessionIdNotifier extends _$ActiveSessionIdNotifier {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

@Riverpod(keepAlive: true)
class SelectedModelNotifier extends _$SelectedModelNotifier {
  @override
  AIModel build() => AIModels.sonnet46;

  void select(AIModel model) => state = model;
}

@Riverpod(keepAlive: true)
class SessionModeNotifier extends _$SessionModeNotifier {
  @override
  ChatMode build() => ChatMode.chat;

  void set(ChatMode mode) => state = mode;
}

@Riverpod(keepAlive: true)
class SessionEffortNotifier extends _$SessionEffortNotifier {
  @override
  ChatEffort build() => ChatEffort.high;

  void set(ChatEffort effort) => state = effort;
}

@Riverpod(keepAlive: true)
class SessionPermissionNotifier extends _$SessionPermissionNotifier {
  @override
  ChatPermission build() => ChatPermission.fullAccess;

  void set(ChatPermission permission) => state = permission;
}

const _validTransports = {'api-key', 'cli'};

/// Resolves which `AIProviderDatasource` ID (in `AIProviderService`) should
/// handle this turn, based on the active model and the persisted per-provider
/// transport choice. Returns null when the user has selected the API-key
/// (HTTP) path, which routes through `streamMessage` inside `SessionService`.
String? _resolveProviderId(AIModel model, ApiKeysNotifierState? prefs) {
  if (prefs == null) return null;
  if (model.provider == AIProvider.anthropic && !_validTransports.contains(prefs.anthropicTransport)) {
    dLog('[ChatMessagesNotifier] unrecognised anthropicTransport=${prefs.anthropicTransport} — falling back to HTTP');
  }
  if (model.provider == AIProvider.openai && !_validTransports.contains(prefs.openaiTransport)) {
    dLog('[ChatMessagesNotifier] unrecognised openaiTransport=${prefs.openaiTransport} — falling back to HTTP');
  }
  return switch ((model.provider, prefs)) {
    (AIProvider.anthropic, ApiKeysNotifierState(anthropicTransport: 'cli')) => 'claude-cli',
    (AIProvider.openai, ApiKeysNotifierState(openaiTransport: 'cli')) => 'codex',
    _ => null,
  };
}

@riverpod
class ChatMessagesNotifier extends _$ChatMessagesNotifier {
  static const _uuid = Uuid();
  bool _cancelRequested = false;
  bool _sendInProgress = false;
  List<ChatMessage> _preSendMessages = [];

  @override
  Future<List<ChatMessage>> build(String sessionId) async {
    final svc = await ref.watch(sessionServiceProvider.future);
    final history = await svc.loadHistory(sessionId);

    final registry = ref.watch(chatStreamServiceProvider);
    final stateSub = registry.watchState(sessionId).listen((s) {
      // `stateSub.cancel` is async; a final event can race the dispose callback.
      if (!ref.mounted) return;
      switch (s) {
        case ChatStreamFailed(:final failure):
          dLog('[ChatMessagesNotifier] stream failed for $sessionId: $failure');
        case ChatStreamDone() || ChatStreamIdle():
          ref.read(activeMessageIdProvider.notifier).set(null);
        default:
          break;
      }
    });
    ref.onDispose(stateSub.cancel);

    return history;
  }

  /// Sends [input] and streams the response into state.
  ///
  /// Returns `null` on success, or the caught error object on failure.
  /// The caller (widget) checks the return value to show a snackbar without
  /// needing a try-catch around a notifier call.
  Future<Object?> sendMessage(String input, {String? systemPrompt}) async {
    _cancelRequested = false;
    _sendInProgress = true;
    ref.read(agentCancelProvider.notifier).clear();

    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) {
      _sendInProgress = false;
      throw StateError('No active session — cannot send message.');
    }

    final model = ref.read(selectedModelProvider);
    final service = await ref.read(sessionServiceProvider.future);

    _preSendMessages = state.value ?? [];
    state = AsyncData(List.from(_preSendMessages));

    final activeMessageIdNotifier = ref.read(activeMessageIdProvider.notifier);
    activeMessageIdNotifier.set('pending');

    final permission = ref.read(sessionPermissionProvider);
    final projectPath = ref.read(activeProjectProvider)?.path;
    // Await prefs explicitly: `apiKeysProvider` is autoDispose, so when the
    // chat tab opens fresh (without the Providers screen being mounted) the
    // first `.value` is null and we'd silently fall through to the legacy
    // HTTP path even when CLI transport is selected. Always wait for storage.
    final prefs = await ref.read(apiKeysProvider.future);
    final providerId = _resolveProviderId(model, prefs);

    // Mode can lag behind a model switch: a session left on `act` by Claude
    // would still hold `act` after switching to Gemini / Anthropic-HTTP /
    // OpenAI-HTTP, where the chip is hidden but the stored value persists.
    // Coerce for the send only — don't touch persisted state, so toggling
    // back to a tools-capable transport restores the user's preference.
    // Read AFTER `apiKeysProvider` has resolved so caps reflects the current
    // model+transport rather than a transient null.
    final caps = ref.read(chatInputBarOptionsProvider);
    final storedMode = ref.read(sessionModeProvider);
    final modeWasCoerced = caps != null && !caps.supportedModes.contains(storedMode);
    final mode = modeWasCoerced ? ChatMode.chat : storedMode;
    if (modeWasCoerced) {
      dLog(
        '[ChatMessagesNotifier] coerced mode $storedMode → chat — '
        'transport supports only ${caps.supportedModes}',
      );
    }
    final pendingDrops = <ProviderSettingDrop>[
      if (modeWasCoerced)
        ProviderSettingDropMode(
          requested: storedMode,
          reason: 'Selected model does not support ${storedMode.name} mode — coerced to chat',
        ),
    ];

    // Belt+suspenders: catches paths that bypass the input bar (continueAgenticTurn).
    final readiness = ref.read(transportReadinessProvider);
    if (readiness is! TransportReady && readiness is! TransportUnknown) {
      state = AsyncData(_preSendMessages);
      activeMessageIdNotifier.set(null);
      _sendInProgress = false;
      return AgentFailure.transportNotReady(readiness);
    }

    // Cached readiness can be stale — re-probe to catch out-of-band sign-outs.
    // Route through the service so probe failures share the fail-open contract.
    if (providerId != null) {
      final freshAuth = await ref.read(aIProviderServiceProvider.notifier).getAuthStatus(providerId);
      if (freshAuth is AuthUnauthenticated) {
        state = AsyncData(_preSendMessages);
        activeMessageIdNotifier.set(null);
        _sendInProgress = false;
        return AgentFailure.transportNotReady(
          TransportReadiness.signedOut(provider: providerId, signInCommand: freshAuth.signInCommand),
        );
      }
    }

    final registry = ref.read(chatStreamServiceProvider);
    final completer = Completer<Object?>();

    var disposed = false;
    ref.onDispose(() => disposed = true);

    // Capture stable notifier instances; the registry outlives this notifier and `ref` would throw post-dispose.
    final cancelN = ref.read(agentCancelProvider.notifier);
    final permN = ref.read(agentPermissionRequestProvider.notifier);
    final mcpN = ref.read(mcpServerStatusProvider.notifier);

    String? streamingAssistantId;
    String? userMessageId;
    final dropsN = ref.read(messageDroppedSettingsProvider.notifier);

    registry.start(
      sessionId: sessionId,
      streamFactory: () => service
          .sendAndStream(
            sessionId: sessionId,
            userInput: input,
            model: model,
            systemPrompt: systemPrompt,
            mode: mode,
            permission: permission,
            projectPath: projectPath,
            providerId: providerId,
            cancelFlag: () => cancelN.cancelled,
            requestPermission: permN.request,
            onMcpStatusChanged: mcpN.setStatus,
            onMcpServerRemoved: mcpN.remove,
            onSettingDropped: (drop) {
              final assistantId = streamingAssistantId;
              if (assistantId != null) {
                dropsN.add(assistantId, drop);
              } else {
                pendingDrops.add(drop);
              }
            },
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: (sink) =>
                sink.addError(NetworkException('No response — the model may still be loading.'), StackTrace.current),
          ),
      // Flip the cooperative cancel flag from the registry so bulk cancels (e.g. delete-all-sessions) reach the underlying CLI process, not just the Dart subscription.
      onCancel: cancelN.request,
      onMessage: (msg) {
        if (disposed) return;
        if (msg.sessionId != sessionId) return;
        if (msg.role == MessageRole.user && userMessageId == null) {
          userMessageId = msg.id;
        }
        if (msg.role == MessageRole.assistant && streamingAssistantId == null) {
          streamingAssistantId = msg.id;
          activeMessageIdNotifier.set(msg.id);
          if (pendingDrops.isNotEmpty) {
            dropsN.addAll(msg.id, pendingDrops);
            pendingDrops.clear();
          }
        }
        final current = state.value ?? [];
        final idx = current.indexWhere((m) => m.id == msg.id);
        if (idx >= 0) {
          final updated = List<ChatMessage>.from(current);
          updated[idx] = msg;
          state = AsyncData(updated);
        } else {
          state = AsyncData([...current, msg]);
        }
      },
    );

    if (_cancelRequested) {
      unawaited(registry.cancel(sessionId));
      _sendInProgress = false;
      return null;
    }

    // Subscribe after start() so watchState's first yield is connecting, not idle.
    late final StreamSubscription<ChatStreamState> termSub;
    void flushPendingDropsOnTermination() {
      if (pendingDrops.isEmpty) return;
      final anchor = streamingAssistantId ?? userMessageId;
      if (anchor == null) {
        pendingDrops.clear();
        return;
      }
      dropsN.addAll(anchor, pendingDrops);
      pendingDrops.clear();
    }

    termSub = registry.watchState(sessionId).listen((s) {
      if (disposed) {
        if (!completer.isCompleted) completer.complete(null);
        termSub.cancel();
        return;
      }
      switch (s) {
        case ChatStreamDone():
          flushPendingDropsOnTermination();
          if (!completer.isCompleted) completer.complete(null);
          termSub.cancel();
        case ChatStreamFailed(:final failure):
          flushPendingDropsOnTermination();
          if (!completer.isCompleted) completer.complete(failure);
          termSub.cancel();
        case ChatStreamIdle():
          flushPendingDropsOnTermination();
          if (!completer.isCompleted) completer.complete(null);
          termSub.cancel();
        default:
          break;
      }
    });
    ref.onDispose(() => termSub.cancel());

    final result = await completer.future;
    _sendInProgress = false;
    return result;
  }

  /// Cancels the in-flight send (if any) and appends an in-memory
  /// `interrupted` marker. Persistence is fire-and-forget — failures are
  /// logged via [sLog] so they remain visible in release builds, but no UI
  /// error is surfaced (the badge is already on screen; only its survival
  /// across app restarts is at risk).
  void cancelSend() {
    if (!_sendInProgress) return;
    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) return;

    _cancelRequested = true;
    _sendInProgress = false;
    final registry = ref.read(chatStreamServiceProvider);
    unawaited(registry.cancel(sessionId));
    ref.read(agentCancelProvider.notifier).request();
    // Unblock any in-flight permission dialog so the agent loop can exit its
    // `await requestPermission(...)` rather than hanging until the UI is
    // manually dismissed.
    ref.read(agentPermissionRequestProvider.notifier).cancel();
    ref.read(activeMessageIdProvider.notifier).set(null);

    final current = state.value ?? _preSendMessages;
    final marker = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.interrupted,
      content: '',
      timestamp: DateTime.now(),
    );
    state = AsyncData([...current, marker]);
    unawaited(_persistInterrupted(sessionId, marker));
  }

  Future<void> _persistInterrupted(String sessionId, ChatMessage marker) async {
    try {
      final service = await ref.read(sessionServiceProvider.future);
      await service.persistMessage(sessionId, marker);
    } catch (e) {
      // Use sLog (survives release builds) — the marker is on screen, but its
      // failure to persist is a data-integrity event the user can't see.
      sLog('[ChatMessagesNotifier] failed to persist interrupted marker: sessionId=$sessionId error=$e');
    }
  }

  /// State-mutator helper for [ChatMessagesActions.deleteMessage]. Removes
  /// every message whose id is in [ids] from the in-memory list.
  void removeFromState(Iterable<String> ids) {
    final removed = ids.toSet();
    final current = state.value ?? const <ChatMessage>[];
    state = AsyncData(current.where((m) => !removed.contains(m.id)).toList());
  }

  /// State-mutator helper for [ChatMessagesActions.loadMore]. Prepends a page
  /// of [older] messages to the in-memory list.
  void prependOlder(List<ChatMessage> older) {
    final current = state.value ?? const <ChatMessage>[];
    state = AsyncData([...older, ...current]);
  }

  /// Sets the [ChatMessage.iterationCapReached] flag on [messageId]. No-op if
  /// the message is not found. Used both to clear the cap before re-entering
  /// the agentic loop and to restore it if that attempt itself fails.
  void setIterationCapReached(String messageId, bool reached) {
    final current = state.value ?? [];
    final idx = current.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    final updated = List<ChatMessage>.from(current);
    updated[idx] = updated[idx].copyWith(iterationCapReached: reached);
    state = AsyncData(updated);
  }

  /// Clears the cap and re-enters the agentic loop without injecting a new
  /// user message (empty [userInput] is skipped by [SessionService] and
  /// [AgentService]). If the continuation itself fails, the cap is restored
  /// so the banner reappears and the user can retry.
  ///
  /// Returns `null` on success, or the caught error object on failure.
  Future<Object?> continueAgenticTurn(String messageId) async {
    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) {
      throw StateError('No active session — cannot continue agentic turn.');
    }
    setIterationCapReached(messageId, false);
    final result = await sendMessage('', systemPrompt: null);
    if (result != null) setIterationCapReached(messageId, true);
    return result;
  }
}

@riverpod
Stream<List<ChatSession>> chatSessions(Ref ref) {
  return ref
      .watch(sessionServiceProvider)
      .maybeWhen(data: (svc) => svc.watchAllSessions(), orElse: () => const Stream.empty());
}

@riverpod
Stream<List<ChatSession>> projectSessions(Ref ref, String projectId) {
  return ref
      .watch(sessionServiceProvider)
      .maybeWhen(data: (svc) => svc.watchSessionsByProject(projectId), orElse: () => const Stream.empty());
}

@riverpod
Stream<List<ChatSession>> archivedSessions(Ref ref) {
  return ref
      .watch(sessionServiceProvider)
      .maybeWhen(data: (svc) => svc.watchArchivedSessions(), orElse: () => const Stream.empty());
}

@Riverpod(keepAlive: true)
class AppliedChangesNotifier extends _$AppliedChangesNotifier {
  @override
  Map<String, List<AppliedChange>> build() => {};

  void apply(AppliedChange change) {
    final list = <AppliedChange>[...(state[change.sessionId] ?? []), change];
    state = {...state, change.sessionId: list};
  }

  void revert(String id) {
    final next = {for (final entry in state.entries) entry.key: entry.value.where((c) => c.id != id).toList()};
    state = Map.fromEntries(next.entries.where((e) => e.value.isNotEmpty));
  }

  List<AppliedChange> changesForSession(String sessionId) => state[sessionId] ?? [];
}

@Riverpod(keepAlive: true)
class ActiveMessageIdNotifier extends _$ActiveMessageIdNotifier {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

@Riverpod(keepAlive: true)
class ChangesPanelVisibleNotifier extends _$ChangesPanelVisibleNotifier {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void show() => state = true;
  void hide() => state = false;
}
