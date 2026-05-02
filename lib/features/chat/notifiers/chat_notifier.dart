import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/apply/models/applied_change.dart';
import '../../../data/session/models/session_settings.dart';
import '../../../data/shared/chat_message.dart';
import '../../../data/session/models/chat_session.dart';
import '../../../services/agent/agent_exceptions.dart';
import '../../../services/session/session_service.dart';
import '../../project_sidebar/notifiers/project_sidebar_notifier.dart';
import '../../mcp_servers/notifiers/mcp_server_status_notifier.dart';
import '../../providers/notifiers/providers_notifier.dart';
import 'agent_cancel_notifier.dart';
import 'agent_failure.dart';
import 'agent_permission_request_notifier.dart';

part 'chat_notifier.g.dart';

// System prompt per session (in-memory only, keyed by sessionId)
@Riverpod(keepAlive: true)
class SessionSystemPromptNotifier extends _$SessionSystemPromptNotifier {
  @override
  Map<String, String> build() => {};

  void setPrompt(String sessionId, String prompt) {
    state = Map.of(state)..[sessionId] = prompt;
  }

  String? getPrompt(String sessionId) => state[sessionId];
}

// Currently active session ID
@Riverpod(keepAlive: true)
class ActiveSessionIdNotifier extends _$ActiveSessionIdNotifier {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

// Currently selected model
@Riverpod(keepAlive: true)
class SelectedModelNotifier extends _$SelectedModelNotifier {
  @override
  AIModel build() => AIModels.claude35Sonnet;

  void select(AIModel model) => state = model;
}

// Mode for the current session (chat / plan / act)
@Riverpod(keepAlive: true)
class SessionModeNotifier extends _$SessionModeNotifier {
  @override
  ChatMode build() => ChatMode.chat;

  void set(ChatMode mode) => state = mode;
}

// Effort level for the current session (low / medium / high / max)
@Riverpod(keepAlive: true)
class SessionEffortNotifier extends _$SessionEffortNotifier {
  @override
  ChatEffort build() => ChatEffort.high;

  void set(ChatEffort effort) => state = effort;
}

// Permission level for the current session
@Riverpod(keepAlive: true)
class SessionPermissionNotifier extends _$SessionPermissionNotifier {
  @override
  ChatPermission build() => ChatPermission.fullAccess;

  void set(ChatPermission permission) => state = permission;
}

/// Maps service-layer [AgentException]s into the widget-facing [AgentFailure]
/// union. Kept file-private so widgets never see the raw exception types.
AgentFailure _asAgentFailure(Object e) => switch (e) {
  ProviderDoesNotSupportToolsException() => const AgentFailure.providerDoesNotSupportTools(),
  StreamAbortedUnexpectedlyException(:final reason) => AgentFailure.streamAbortedUnexpectedly(reason),
  _ => AgentFailure.unknown(e),
};

/// Resolves which `AIProviderDatasource` ID (in `AIProviderService`) should
/// handle this turn, based on the active model and the persisted per-provider
/// transport choice. Returns null when the user has selected the API-key
/// (HTTP) path, which routes through `streamMessage` inside `SessionService`.
String? _resolveProviderId(AIModel model, ApiKeysNotifierState? prefs) {
  if (prefs == null) return null;
  return switch ((model.provider, prefs)) {
    (AIProvider.anthropic, ApiKeysNotifierState(anthropicTransport: 'cli')) => 'claude-cli',
    (AIProvider.openai, ApiKeysNotifierState(openaiTransport: 'cli')) => 'codex',
    _ => null,
  };
}

// Messages for the current session
@riverpod
class ChatMessagesNotifier extends _$ChatMessagesNotifier {
  static const _uuid = Uuid();
  StreamSubscription<ChatMessage>? _activeSubscription;
  Completer<Object?>? _sendCompleter;
  bool _cancelRequested = false;
  List<ChatMessage> _preSendMessages = [];

  @override
  Future<List<ChatMessage>> build(String sessionId) async {
    final svc = await ref.watch(sessionServiceProvider.future);
    return svc.loadHistory(sessionId);
  }

  /// Sends [input] and streams the response into state.
  ///
  /// Returns `null` on success, or the caught error object on failure.
  /// The caller (widget) checks the return value to show a snackbar without
  /// needing a try-catch around a notifier call.
  Future<Object?> sendMessage(String input, {String? systemPrompt}) async {
    _cancelRequested = false;
    ref.read(agentCancelProvider.notifier).clear();

    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) throw StateError('No active session — cannot send message.');

    final model = ref.read(selectedModelProvider);
    final service = await ref.read(sessionServiceProvider.future);

    _preSendMessages = state.value ?? [];
    state = AsyncData(List.from(_preSendMessages));

    final activeMessageIdNotifier = ref.read(activeMessageIdProvider.notifier);
    // Sentinel value: communicates "send in progress" to widgets that gate
    // hover actions (Retry/Edit/Delete) on `activeMessageIdProvider`. Replaced
    // with the real assistant message ID as soon as the first chunk arrives.
    activeMessageIdNotifier.set('pending');
    String? streamingAssistantId;
    _sendCompleter = Completer<Object?>();

    final mode = ref.read(sessionModeProvider);
    final permission = ref.read(sessionPermissionProvider);
    final projectPath = ref.read(activeProjectProvider)?.path;
    // Await prefs explicitly: `apiKeysProvider` is autoDispose, so when the
    // chat tab opens fresh (without the Providers screen being mounted) the
    // first `.value` is null and we'd silently fall through to the legacy
    // HTTP path even when CLI transport is selected. Always wait for storage.
    final prefs = await ref.read(apiKeysProvider.future);
    final providerId = _resolveProviderId(model, prefs);

    _activeSubscription = service
        .sendAndStream(
          sessionId: sessionId,
          userInput: input,
          model: model,
          systemPrompt: systemPrompt,
          mode: mode,
          permission: permission,
          projectPath: projectPath,
          providerId: providerId,
          cancelFlag: () => ref.read(agentCancelProvider),
          requestPermission: (req) => ref.read(agentPermissionRequestProvider.notifier).request(req),
          onMcpStatusChanged: ref.read(mcpServerStatusProvider.notifier).setStatus,
          onMcpServerRemoved: ref.read(mcpServerStatusProvider.notifier).remove,
        )
        .timeout(
          const Duration(seconds: 60),
          onTimeout: (sink) =>
              sink.addError(NetworkException('No response — the model may still be loading.'), StackTrace.current),
        )
        .listen(
          (msg) {
            if (msg.role == MessageRole.assistant && streamingAssistantId == null) {
              streamingAssistantId = msg.id;
              activeMessageIdNotifier.set(msg.id);
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
          onError: (Object e, StackTrace st) {
            dLog('[sendMessage] stream error: $e\n$st');
            // Preserve any partial assistant snapshot the agent loop yielded
            // before the abort — rolling back to _preSendMessages would erase
            // the user-visible content that already streamed in.
            final failure = _asAgentFailure(e);
            final completer = _sendCompleter;
            if (completer != null && !completer.isCompleted) completer.complete(failure);
          },
          onDone: () {
            final completer = _sendCompleter;
            if (completer != null && !completer.isCompleted) completer.complete(null);
          },
          cancelOnError: true,
        );

    if (_cancelRequested) {
      _activeSubscription?.cancel();
      _activeSubscription = null;
      // completer already completed by cancelSend, nothing more to do
      return null;
    }

    final result = await _sendCompleter!.future;
    _sendCompleter = null;
    _activeSubscription = null;
    activeMessageIdNotifier.set(null);
    return result;
  }

  /// Cancels the in-flight send (if any) and appends an in-memory
  /// `interrupted` marker. Persistence is fire-and-forget — failures are
  /// logged via [sLog] so they remain visible in release builds, but no UI
  /// error is surfaced (the badge is already on screen; only its survival
  /// across app restarts is at risk).
  void cancelSend() {
    if (_sendCompleter == null) return; // nothing to cancel
    _cancelRequested = true;
    _activeSubscription?.cancel();
    _activeSubscription = null;
    ref.read(agentCancelProvider.notifier).request();
    // Unblock any in-flight permission dialog so the agent loop can exit its
    // `await requestPermission(...)` rather than hanging until the UI is
    // manually dismissed.
    ref.read(agentPermissionRequestProvider.notifier).cancel();
    ref.read(activeMessageIdProvider.notifier).set(null);

    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) {
      // No active session — nothing to persist or attribute the marker to.
      // Complete the completer so sendMessage unblocks.
      final completer = _sendCompleter;
      _sendCompleter = null;
      if (completer != null && !completer.isCompleted) completer.complete(null);
      return;
    }

    final current = state.value ?? _preSendMessages;
    final marker = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.interrupted,
      content: '',
      timestamp: DateTime.now(),
    );
    state = AsyncData([...current, marker]);

    // Null the completer BEFORE completing so a late `onDone` from the
    // already-cancelled subscription doesn't double-complete and throw a
    // StateError that Dart's stream infrastructure would silently swallow.
    final completer = _sendCompleter;
    _sendCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete(null);
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

// Sessions list
@riverpod
Stream<List<ChatSession>> chatSessions(Ref ref) {
  return ref
      .watch(sessionServiceProvider)
      .maybeWhen(data: (svc) => svc.watchAllSessions(), orElse: () => const Stream.empty());
}

// Sessions for a specific project
@riverpod
Stream<List<ChatSession>> projectSessions(Ref ref, String projectId) {
  return ref
      .watch(sessionServiceProvider)
      .maybeWhen(data: (svc) => svc.watchSessionsByProject(projectId), orElse: () => const Stream.empty());
}

// Archived sessions
@riverpod
Stream<List<ChatSession>> archivedSessions(Ref ref) {
  return ref
      .watch(sessionServiceProvider)
      .maybeWhen(data: (svc) => svc.watchArchivedSessions(), orElse: () => const Stream.empty());
}

// ── Applied changes (in-memory, keyed by sessionId) ─────────────────────────

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

// ── Active message ID (for the status bar "Working for Xs" pill) ─────────────

@Riverpod(keepAlive: true)
class ActiveMessageIdNotifier extends _$ActiveMessageIdNotifier {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

// ── Changes panel visibility ─────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class ChangesPanelVisibleNotifier extends _$ChangesPanelVisibleNotifier {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void show() => state = true;
  void hide() => state = false;
}
