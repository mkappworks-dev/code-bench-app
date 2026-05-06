import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/ai/claude_cli_prompt_service.dart';
import '../../../services/github/github_service.dart';
import '../../../services/providers/providers_service.dart';
import '../../git/notifiers/git_actions.dart';
import '../../git/notifiers/pr_preflight_result.dart';
import 'chat_notifier.dart';
import 'create_pr_failure.dart';

part 'create_pr_actions.g.dart';

/// SECURITY: Only log `e.runtimeType` — `$e` can invoke DioException.toString()
/// which serialises the Authorization header and leaks the PAT.
@Riverpod(keepAlive: true)
class CreatePrActions extends _$CreatePrActions {
  @override
  FutureOr<void> build() {}

  CreatePrFailure _asFailure(Object e) => switch (e) {
    AuthException() => const CreatePrFailure.notAuthenticated(),
    // GitHub returns NetworkException for 401; treat as notAuthenticated so the UI shows "reconnect".
    NetworkException(:final statusCode) when statusCode == 401 => const CreatePrFailure.notAuthenticated(),
    NetworkException(:final statusCode) when statusCode == 403 => const CreatePrFailure.permissionDenied(),
    // GitHub returns 404 (not 403) when the App is not installed on the repo.
    NetworkException(:final statusCode) when statusCode == 404 => const CreatePrFailure.appNotInstalled(),
    NetworkException(:final message) => CreatePrFailure.network(message),
    _ => CreatePrFailure.unknown(e),
  };

  Future<bool> hasToken() async {
    final repo = await ref.read(githubServiceProvider.future);
    return repo.isAuthenticated();
  }

  Future<PrPreflightResult> fastPreflight(String path) async {
    final git = ref.read(gitActionsProvider.notifier);

    if (!await hasToken()) {
      return const PrPreflightResult.failed('Connect GitHub in Settings → Providers');
    }

    final currentBranch = await git.currentBranch(path);
    if (currentBranch == null) {
      return const PrPreflightResult.failed('Could not read current branch — is this a valid git repo?');
    }
    if (currentBranch == 'main' || currentBranch == 'master') {
      return const PrPreflightResult.failed("You're on the default branch — create a feature branch first.");
    }

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

    try {
      final service = await ref.read(githubServiceProvider.future);
      final existingUrl = await service.findOpenPrUrlForBranch(owner, repo, currentBranch);
      if (existingUrl != null) {
        return PrPreflightResult.failed(
          'A pull request for this branch is already open',
          actionUrl: existingUrl,
          actionLabel: 'Open',
        );
      }
    } catch (e) {
      // Best-effort — if the check fails, let the user attempt creation anyway.
      // Logged so a flapping check (rate limit, bad token) is debuggable.
      dLog('[CreatePrActions] fastPreflight existing-PR check failed: ${e.runtimeType}');
    }

    return PrPreflightResult.passed(owner: owner, repo: repo, currentBranch: currentBranch);
  }

  // Uses _listBranchesRaw (not listBranches) — a failure here must not pollute notifier state and trigger unrelated snackbars.
  Future<({String title, String body, List<String> branches})> loadContent(
    String path,
    String owner,
    String repo,
    String currentBranch,
  ) async {
    final changedFiles = await ref.read(gitActionsProvider.notifier).getBranchChangedFiles(path);

    // Start both concurrently before awaiting either.
    final contentFut = _generatePrContent(changedFiles: changedFiles, branch: currentBranch);
    final branchesFut = _listBranchesRaw(owner, repo);

    final content = await contentFut;
    final List<String> branches;
    try {
      branches = await branchesFut;
    } catch (e, st) {
      final status = e is NetworkException ? e.statusCode : null;
      dLog('[CreatePrActions] loadContent listBranches failed: ${e.runtimeType} (status=$status)');
      final failure = _asFailure(e);
      final msg = switch (failure) {
        CreatePrNotAuthenticated() => 'Your GitHub token is no longer valid — reconnect in Settings → Providers.',
        CreatePrAppNotInstalled() => "GitHub App isn't installed on $owner/$repo — install it to enable PRs.",
        CreatePrPermissionDenied() => 'GitHub token lacks repo access — check token scopes in Settings → Providers.',
        CreatePrNetwork(:final message) => 'Could not list branches for $owner/$repo — $message.',
        _ => 'Could not list branches for $owner/$repo — check your GitHub token and repo access.',
      };
      Error.throwWithStackTrace(CreatePrFailure.loadContentFailed(msg), st);
    }

    return (title: content.title, body: content.body, branches: branches);
  }

  Future<List<String>> _listBranchesRaw(String owner, String repo) async {
    final repository = await ref.read(githubServiceProvider.future);
    return repository.listBranches(owner, repo);
  }

  Future<List<String>?> listBranches(String owner, String repo) async {
    state = const AsyncLoading();
    List<String>? result;
    state = await AsyncValue.guard(() async {
      try {
        result = await _listBranchesRaw(owner, repo);
      } catch (e, st) {
        final status = e is NetworkException ? e.statusCode : null;
        dLog('[CreatePrActions] listBranches failed: ${e.runtimeType} (status=$status)');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return result;
  }

  Future<String?> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    required bool draft,
  }) async {
    state = const AsyncLoading();
    String? result;
    state = await AsyncValue.guard(() async {
      try {
        final repository = await ref.read(githubServiceProvider.future);
        result = await repository.createPullRequest(
          owner: owner,
          repo: repo,
          title: title,
          body: body,
          head: head,
          base: base,
          draft: draft,
        );
      } catch (e, st) {
        final status = e is NetworkException ? e.statusCode : null;
        dLog('[CreatePrActions] createPullRequest failed: ${e.runtimeType} (status=$status)');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
    return result;
  }

  // Best-effort — returns branch-name fallback on any error; never sets AsyncError so the failure stays silent.
  Future<({String title, String body})> _generatePrContent({
    required List<String> changedFiles,
    required String branch,
  }) async {
    final fallback = (title: branch.replaceAll('-', ' '), body: '');
    final model = ref.read(selectedModelProvider);
    final providers = ref.read(providersServiceProvider);
    final prompt = _buildPrPrompt(changedFiles);

    if (await providers.hasCredentialsFor(model.provider)) {
      try {
        final repo = await ref.read(aiServiceProvider.future);
        final response = await repo.sendMessage(history: const [], prompt: prompt, model: model);
        return _parsePrResponse(response.content, fallback: fallback);
      } catch (e) {
        dLog('[CreatePrActions] generatePrContent (http) failed: ${e.runtimeType}');
        return fallback;
      }
    }

    if (model.provider == AIProvider.anthropic) {
      final transport = await providers.readAnthropicTransport();
      if (transport == 'cli') {
        try {
          final svc = ref.read(claudeCliPromptServiceProvider);
          final text = await svc.generate(prompt);
          if (text != null) return _parsePrResponse(text, fallback: fallback);
        } catch (e) {
          dLog('[CreatePrActions] generatePrContent (cli) failed: ${e.runtimeType}');
        }
      }
    }

    return fallback;
  }

  String _buildPrPrompt(List<String> changedFiles) =>
      'Generate a PR title and bullet-point body for these '
      'changes: ${changedFiles.isEmpty ? "general changes" : changedFiles.join(", ")}. '
      'The TITLE must follow Conventional Commits — <type>(<optional scope>): <subject> — '
      'where type is one of feat, fix, chore, docs, refactor, test, perf, build, ci, style. '
      'Keep the title to 70 chars or fewer, lowercase subject, no trailing period. '
      'Reply in this exact format:\nTITLE: <title>\nBODY:\n<bullets>';

  ({String title, String body}) _parsePrResponse(String text, {required ({String title, String body}) fallback}) {
    final titleMatch = RegExp(r'TITLE:\s*(.+)').firstMatch(text);
    final bodyMatch = RegExp(r'BODY:\n([\s\S]+)').firstMatch(text);
    return (
      title: titleMatch != null ? titleMatch.group(1)!.trim() : fallback.title,
      body: bodyMatch != null ? bodyMatch.group(1)!.trim() : '',
    );
  }
}
