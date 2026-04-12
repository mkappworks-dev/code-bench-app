import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/debug_logger.dart';
import '../../features/chat/notifiers/chat_notifier.dart';
import '../../services/ai/ai_service_factory.dart';
import 'commit_message_failure.dart';

part 'commit_message_actions.g.dart';

/// Generates AI-assisted text for git workflows: commit messages and PR
/// title / body. Both methods always return a usable value — the fallback
/// string — even when the AI call fails, so the commit / PR flow is never
/// blocked by a network error.
///
/// On [NetworkException], the notifier emits [AsyncError] carrying a
/// [CommitMessageFailure] so widgets can surface an inline "AI unavailable"
/// notice via [ref.listen] without needing a try/catch in widget code.
@Riverpod(keepAlive: true)
class CommitMessageActions extends _$CommitMessageActions {
  @override
  FutureOr<void> build() {}

  /// Generates a conventional commit message for [changedFiles] using the
  /// currently selected AI model. Returns `'chore: update files'` as a
  /// fallback when the AI call is unavailable.
  Future<String> generateCommitMessage(List<String> changedFiles) async {
    const fallback = 'chore: update files';
    state = const AsyncLoading();
    String message = fallback;
    state = await AsyncValue.guard(() async {
      try {
        final model = ref.read(selectedModelProvider);
        final aiSvc = await ref.read(aiServiceProvider(model.provider).future);
        if (aiSvc == null) return;
        final prompt =
            'Write a conventional commit message (subject line only, max 72 chars) '
            'summarising these file changes: ${changedFiles.isEmpty ? "general changes" : changedFiles.join(", ")}. '
            'Reply with only the commit message, no explanation.';
        final response = await aiSvc.sendMessage(history: const [], prompt: prompt, model: model);
        final text = response.content;
        if (text.isNotEmpty) {
          message = text.trim().replaceAll('"', '').split('\n').first.trim();
        }
      } on NetworkException catch (e, st) {
        dLog('[CommitMessageActions] generateCommitMessage network error: $e');
        Error.throwWithStackTrace(const CommitMessageFailure.commitMessageUnavailable(), st);
      }
    });
    return message;
  }

  /// Generates a PR title and bullet-point body for [changedFiles] on
  /// [branch] using the currently selected AI model. Returns the
  /// branch name (with hyphens replaced by spaces) as the fallback title
  /// and an empty body when the AI call is unavailable.
  Future<({String title, String body})> generatePrContent({
    required List<String> changedFiles,
    required String branch,
  }) async {
    final fallback = (title: branch.replaceAll('-', ' '), body: '');
    state = const AsyncLoading();
    var result = fallback;
    state = await AsyncValue.guard(() async {
      try {
        final model = ref.read(selectedModelProvider);
        final aiSvc = await ref.read(aiServiceProvider(model.provider).future);
        if (aiSvc == null) return;
        final prompt =
            'Generate a PR title (max 70 chars) and bullet-point body for these '
            'changes: ${changedFiles.isEmpty ? "general changes" : changedFiles.join(", ")}. '
            'Reply in this format:\nTITLE: <title>\nBODY:\n<bullets>';
        final response = await aiSvc.sendMessage(history: const [], prompt: prompt, model: model);
        final text = response.content;
        final titleMatch = RegExp(r'TITLE:\s*(.+)').firstMatch(text);
        final bodyMatch = RegExp(r'BODY:\n([\s\S]+)').firstMatch(text);
        result = (
          title: titleMatch != null ? titleMatch.group(1)!.trim() : fallback.title,
          body: bodyMatch != null ? bodyMatch.group(1)!.trim() : '',
        );
      } on NetworkException catch (e, st) {
        dLog('[CommitMessageActions] generatePrContent network error: $e');
        Error.throwWithStackTrace(const CommitMessageFailure.prContentUnavailable(), st);
      }
    });
    return result;
  }
}
