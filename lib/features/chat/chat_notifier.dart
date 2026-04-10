import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/ai_model.dart';
import '../../data/models/applied_change.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';
import '../../services/session/session_service.dart';

part 'chat_notifier.g.dart';

// System prompt per session (in-memory only, keyed by sessionId)
@Riverpod(keepAlive: true)
class SessionSystemPrompt extends _$SessionSystemPrompt {
  @override
  Map<String, String> build() => {};

  void setPrompt(String sessionId, String prompt) {
    state = {...state, sessionId: prompt};
  }

  String? getPrompt(String sessionId) => state[sessionId];
}

// Currently active session ID
@Riverpod(keepAlive: true)
class ActiveSessionId extends _$ActiveSessionId {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

// Currently selected model
@Riverpod(keepAlive: true)
class SelectedModel extends _$SelectedModel {
  @override
  AIModel build() => AIModels.claude35Sonnet;

  void select(AIModel model) => state = model;
}

// Messages for the current session
@riverpod
class ChatMessages extends _$ChatMessages {
  @override
  Future<List<ChatMessage>> build(String sessionId) async {
    final service = ref.watch(sessionServiceProvider);
    return service.loadHistory(sessionId);
  }

  Future<void> sendMessage(String input, {String? systemPrompt}) async {
    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) return;

    final model = ref.read(selectedModelProvider);
    final service = ref.read(sessionServiceProvider);

    // Optimistically add user message
    final currentMessages = state.valueOrNull ?? [];
    state = AsyncData([...currentMessages]);

    await for (final msg in service.sendAndStream(
      sessionId: sessionId,
      userInput: input,
      model: model,
      systemPrompt: systemPrompt,
    )) {
      final current = state.valueOrNull ?? [];
      final idx = current.indexWhere((m) => m.id == msg.id);
      if (idx >= 0) {
        final updated = List<ChatMessage>.from(current);
        updated[idx] = msg;
        state = AsyncData(updated);
      } else {
        state = AsyncData([...current, msg]);
      }
    }
  }

  Future<void> loadMore(String sessionId, int offset) async {
    final service = ref.read(sessionServiceProvider);
    final older = await service.loadHistory(
      sessionId,
      limit: 50,
      offset: offset,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData([...older, ...current]);
  }
}

// Sessions list
@riverpod
Stream<List<ChatSession>> chatSessions(Ref ref) {
  final service = ref.watch(sessionServiceProvider);
  return service.watchAllSessions();
}

// Sessions for a specific project
@riverpod
Stream<List<ChatSession>> projectSessions(Ref ref, String projectId) {
  final service = ref.watch(sessionServiceProvider);
  return service.watchSessionsByProject(projectId);
}

// Archived sessions
@riverpod
Stream<List<ChatSession>> archivedSessions(Ref ref) {
  return ref.watch(sessionServiceProvider).watchArchivedSessions();
}

// ── Applied changes (in-memory, keyed by sessionId) ─────────────────────────

@Riverpod(keepAlive: true)
class AppliedChanges extends _$AppliedChanges {
  @override
  Map<String, List<AppliedChange>> build() => {};

  void apply(AppliedChange change) {
    final list = <AppliedChange>[...(state[change.sessionId] ?? []), change];
    state = {...state, change.sessionId: list};
  }

  void revert(String id) {
    final next = {
      for (final entry in state.entries) entry.key: entry.value.where((c) => c.id != id).toList(),
    };
    state = Map.fromEntries(next.entries.where((e) => e.value.isNotEmpty));
  }

  List<AppliedChange> changesForSession(String sessionId) => state[sessionId] ?? [];
}

// ── Changes panel visibility ─────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class ChangesPanelVisible extends _$ChangesPanelVisible {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void show() => state = true;
  void hide() => state = false;
}
