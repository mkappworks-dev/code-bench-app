import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/debug_logger.dart';
import '../../data/_core/preferences/general_preferences.dart';
import '../../features/chat/notifiers/chat_notifier.dart';
import '../../services/ai/ai_service.dart';
import '../../services/providers/providers_service.dart';
import 'commit_message_failure.dart';

part 'commit_message_actions.g.dart';

/// AI commit-message generator. Always returns a usable string — falls back to
/// `'chore: update files'` so the commit flow is never blocked by a network error.
@Riverpod(keepAlive: true)
class CommitMessageActions extends _$CommitMessageActions {
  @override
  FutureOr<void> build() {}

  Future<({String message, bool autoCommit})> prepareCommit() async {
    final sessionId = ref.read(activeSessionIdProvider);
    final changedFiles = sessionId != null
        ? ref.read(appliedChangesProvider.notifier).changesForSession(sessionId).map((c) => c.filePath).toList()
        : <String>[];
    final autoCommit = await ref.read(generalPreferencesProvider).getAutoCommit();
    final message = await generateCommitMessage(changedFiles);
    return (message: message, autoCommit: autoCommit);
  }

  Future<String> generateCommitMessage(List<String> changedFiles) async {
    const fallback = 'chore: update files';
    final model = ref.read(selectedModelProvider);
    final providers = ref.read(providersServiceProvider);
    if (!await providers.hasCredentialsFor(model.provider)) {
      // Reset any prior AsyncError so the inline "AI unavailable" notice
      // doesn't linger across calls when the user later removes credentials.
      state = const AsyncData(null);
      return fallback;
    }
    state = const AsyncLoading();
    String message = fallback;
    state = await AsyncValue.guard(() async {
      try {
        final repo = await ref.read(aiServiceProvider.future);
        final prompt =
            'Write a conventional commit message (subject line only, max 72 chars) '
            'summarising these file changes: ${changedFiles.isEmpty ? "general changes" : changedFiles.join(", ")}. '
            'Reply with only the commit message, no explanation.';
        final response = await repo.sendMessage(history: const [], prompt: prompt, model: model);
        final text = response.content;
        if (text.isNotEmpty) {
          message = text.trim().replaceAll('"', '').split('\n').first.trim();
        }
      } on NetworkException catch (e, st) {
        dLog('[CommitMessageActions] generateCommitMessage network error: $e');
        Error.throwWithStackTrace(const CommitMessageFailure.commitMessageUnavailable(), st);
      } catch (e, st) {
        dLog('[CommitMessageActions] generateCommitMessage failed: $e');
        Error.throwWithStackTrace(CommitMessageFailure.unknown(e), st);
      }
    });
    return message;
  }
}
