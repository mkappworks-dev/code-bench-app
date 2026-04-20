import 'dart:async';

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/session/models/session_settings.dart';
import '../../../data/shared/ai_model.dart';
import '../../../services/session/session_service.dart';
import 'chat_notifier.dart';
import 'available_models_notifier.dart';
import 'session_settings_failure.dart';

part 'session_settings_actions.g.dart';

/// Coordinator notifier that loads and persists the five per-session chat
/// settings (model, system prompt, mode, effort, permission).
///
/// Reacts to [activeSessionIdProvider] changes and pushes the stored values
/// into their respective reactive notifiers so [ChatInputBar] always reflects
/// the active session's settings.
@Riverpod(keepAlive: true)
class SessionSettingsActions extends _$SessionSettingsActions {
  @override
  FutureOr<void> build() {
    // Load for the session that is already active when this notifier first
    // initialises (e.g. on app restart with a restored session).
    final currentId = ref.read(activeSessionIdProvider);
    if (currentId != null) unawaited(_loadForSession(currentId));

    // React to every subsequent session switch.
    ref.listen(activeSessionIdProvider, (_, sessionId) {
      if (sessionId != null) unawaited(_loadForSession(sessionId));
    });
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _loadForSession(String sessionId) async {
    final svc = await ref.read(sessionServiceProvider.future);
    final session = await svc.getSession(sessionId);
    if (session == null) return;

    final model = _resolveModel(session.modelId);
    ref.read(selectedModelProvider.notifier).select(model);

    ref.read(sessionSystemPromptProvider.notifier).setPrompt(sessionId, session.systemPrompt ?? '');

    ref
        .read(sessionModeProvider.notifier)
        .set(ChatMode.values.firstWhereOrNull((m) => m.name == session.mode) ?? ChatMode.chat);
    ref
        .read(sessionEffortProvider.notifier)
        .set(ChatEffort.values.firstWhereOrNull((e) => e.name == session.effort) ?? ChatEffort.high);
    ref
        .read(sessionPermissionProvider.notifier)
        .set(ChatPermission.values.firstWhereOrNull((p) => p.name == session.permission) ?? ChatPermission.fullAccess);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> updateModel(String sessionId, AIModel model) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        ref.read(selectedModelProvider.notifier).select(model);
        final svc = await ref.read(sessionServiceProvider.future);
        await svc.patchSessionSettings(sessionId, modelId: model.modelId);
      } catch (e, st) {
        dLog('[SessionSettingsActions] updateModel failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> updateSystemPrompt(String sessionId, String prompt) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        ref.read(sessionSystemPromptProvider.notifier).setPrompt(sessionId, prompt);
        final svc = await ref.read(sessionServiceProvider.future);
        await svc.patchSessionSettings(sessionId, systemPrompt: prompt);
      } catch (e, st) {
        dLog('[SessionSettingsActions] updateSystemPrompt failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> updateMode(String sessionId, ChatMode mode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        ref.read(sessionModeProvider.notifier).set(mode);
        final svc = await ref.read(sessionServiceProvider.future);
        await svc.patchSessionSettings(sessionId, mode: mode.name);
      } catch (e, st) {
        dLog('[SessionSettingsActions] updateMode failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> updateEffort(String sessionId, ChatEffort effort) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        ref.read(sessionEffortProvider.notifier).set(effort);
        final svc = await ref.read(sessionServiceProvider.future);
        await svc.patchSessionSettings(sessionId, effort: effort.name);
      } catch (e, st) {
        dLog('[SessionSettingsActions] updateEffort failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  Future<void> updatePermission(String sessionId, ChatPermission permission) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        ref.read(sessionPermissionProvider.notifier).set(permission);
        final svc = await ref.read(sessionServiceProvider.future);
        await svc.patchSessionSettings(sessionId, permission: permission.name);
      } catch (e, st) {
        dLog('[SessionSettingsActions] updatePermission failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }

  AIModel _resolveModel(String modelId) {
    if (modelId.isEmpty) return ref.read(selectedModelProvider);
    return AIModels.fromId(modelId) ??
        ref.read(availableModelsProvider).value?.firstWhereOrNull((m) => m.modelId == modelId) ??
        ref.read(selectedModelProvider);
  }

  SessionSettingsFailure _asFailure(Object e) => SessionSettingsFailure.unknown(e);
}
