import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/debug_logger.dart';
import '../../data/_core/preferences/general_preferences.dart';
import '../../features/chat/notifiers/chat_notifier.dart';
import '../../features/chat/notifiers/create_pr_actions.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import 'commit_message_failure.dart';
import 'git_actions.dart';
import 'pr_preflight_result.dart';

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

  /// Reads the active session's changed files and the autoCommit preference,
  /// then generates a commit message. Callers receive both values so they can
  /// decide whether to show the commit dialog or commit automatically.
  Future<({String message, bool autoCommit})> prepareCommit() async {
    final sessionId = ref.read(activeSessionIdProvider);
    final changedFiles = sessionId != null
        ? ref.read(appliedChangesProvider.notifier).changesForSession(sessionId).map((c) => c.filePath).toList()
        : <String>[];
    final autoCommit = await ref.read(generalPreferencesProvider).getAutoCommit();
    final message = await generateCommitMessage(changedFiles);
    return (message: message, autoCommit: autoCommit);
  }

  /// Runs the full PR creation preflight for [path]: checks token, validates
  /// branch, generates AI title/body, resolves owner/repo from the origin
  /// remote, and lists branches. Returns [PrPreflightReady] with everything
  /// the dialog needs, or [PrPreflightFailed] with a user-facing message.
  Future<PrPreflightResult> preparePr(String path) async {
    final git = ref.read(gitActionsProvider.notifier);
    final prActions = ref.read(createPrActionsProvider.notifier);

    if (!await prActions.hasToken()) {
      return const PrPreflightResult.failed('Connect GitHub in Settings → Providers');
    }

    final currentBranch = await git.currentBranch(path);
    if (currentBranch == null) {
      return const PrPreflightResult.failed('Could not read current branch — is this a valid git repo?');
    }
    if (currentBranch == 'main' || currentBranch == 'master') {
      return const PrPreflightResult.failed("You're on the default branch — create a feature branch first.");
    }

    final sessionId = ref.read(activeSessionIdProvider);
    final changedFiles = sessionId != null
        ? ref.read(appliedChangesProvider.notifier).changesForSession(sessionId).map((c) => c.filePath).toList()
        : <String>[];
    final (:title, :body) = await generatePrContent(changedFiles: changedFiles, branch: currentBranch);

    final remoteUrl = await git.getOriginUrl(path);
    if (remoteUrl == null) {
      return const PrPreflightResult.failed("No `origin` remote configured — run `git remote add origin <url>` first.");
    }
    final repoMatch = RegExp(r'github\.com[:/]([^/]+)/([^/\.]+)').firstMatch(remoteUrl);
    if (repoMatch == null) {
      return const PrPreflightResult.failed('Could not detect GitHub owner/repo from remote');
    }
    final owner = repoMatch.group(1)!;
    final repo = repoMatch.group(2)!;

    final branches = await prActions.listBranches(owner, repo);
    if (branches == null) {
      return PrPreflightResult.failed(
        'Could not list branches for $owner/$repo — check your GitHub token and repo access.',
      );
    }

    return PrPreflightResult.ready(
      title: title,
      body: body,
      branches: branches,
      owner: owner,
      repo: repo,
      currentBranch: currentBranch,
    );
  }

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
        final repo = await ref.read(aiRepositoryProvider.future);
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
        final repo = await ref.read(aiRepositoryProvider.future);
        final prompt =
            'Generate a PR title (max 70 chars) and bullet-point body for these '
            'changes: ${changedFiles.isEmpty ? "general changes" : changedFiles.join(", ")}. '
            'Reply in this format:\nTITLE: <title>\nBODY:\n<bullets>';
        final response = await repo.sendMessage(history: const [], prompt: prompt, model: model);
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
      } catch (e, st) {
        dLog('[CommitMessageActions] generatePrContent failed: $e');
        Error.throwWithStackTrace(CommitMessageFailure.unknown(e), st);
      }
    });
    return result;
  }
}
