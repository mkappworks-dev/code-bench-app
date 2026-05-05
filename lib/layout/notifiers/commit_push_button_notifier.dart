import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../services/git/git_service.dart';
import '../../services/github/github_service.dart';
import 'git_live_state_notifier.dart';
import 'git_remotes_notifier.dart';

part 'commit_push_button_notifier.freezed.dart';
part 'commit_push_button_notifier.g.dart';

/// All display state needed by [CommitPushButton] in a single reactive read.
@freezed
abstract class CommitPushButtonState with _$CommitPushButtonState {
  const factory CommitPushButtonState({
    required bool canCommit,
    required bool canPush,
    required bool canPull,
    required bool canPr,
    required bool canDropdown,
    required bool hasUnknownProbe,
    required String badgeLabel,
    required List<GitRemote> remotes,
    required String selectedRemote,
  }) = _CommitPushButtonState;
}

@riverpod
Future<String?> existingOpenPrUrl(Ref ref, String path) async {
  final liveState = ref.watch(gitLiveStateProvider(path)).value;
  final branch = liveState?.branch;
  if (branch == null || liveState?.isOnDefaultBranch == true) return null;

  final remotesData = ref.watch(gitRemotesProvider(path)).value;
  final originUrl = remotesData?.remotes.where((r) => r.name == 'origin').firstOrNull?.url;
  if (originUrl == null) return null;

  final repoMatch = RegExp(r'github\.com[:/]([^/]+)/([^/\.]+)').firstMatch(originUrl);
  if (repoMatch == null) return null;
  final owner = repoMatch.group(1)!;
  final repo = repoMatch.group(2)!;

  try {
    // ref.watch (not ref.read) — must rebuild when githubServiceProvider is invalidated on sign-in/out.
    final service = await ref.watch(githubServiceProvider.future);
    return await service.findOpenPrUrlForBranch(owner, repo, branch);
  } catch (e) {
    // Logged so a flapping check (rate limit, bad token) leaves a breadcrumb instead of silently re-enabling "Create PR".
    dLog('[existingOpenPrUrl] PR check failed: ${e.runtimeType}');
    return null;
  }
}

/// Derives all [CommitPushButton] display flags from live git state,
/// behind-count, and the loaded remote list for [path].
@riverpod
CommitPushButtonState commitPushButtonState(Ref ref, String path) {
  final liveState = ref.watch(gitLiveStateProvider(path)).value;
  final behind = ref.watch(behindCountProvider(path)).value;
  final remotesData = ref.watch(gitRemotesProvider(path)).value;
  final existingPrUrl = ref.watch(existingOpenPrUrlProvider(path)).value;

  final canCommit = liveState?.hasUncommitted == true;
  final canPush = (liveState?.aheadCount ?? 0) > 0;
  final canPull = (behind ?? 0) > 0;
  final canPr = liveState?.branch != null && !(liveState?.isOnDefaultBranch ?? true) && existingPrUrl == null;
  final remotes = remotesData?.remotes ?? const [];
  final canDropdown = canPush || canPull || canPr || remotes.isNotEmpty;

  // null hasUncommitted/aheadCount means the git probe failed — show ! so a disabled Commit isn't mistaken for a clean repo.
  final bool hasUnknownProbe =
      liveState?.isGit == true && (liveState?.hasUncommitted == null || liveState?.aheadCount == null);

  final String badgeLabel;
  if (hasUnknownProbe) {
    badgeLabel = ' !';
  } else if (behind == null) {
    badgeLabel = ' ↓?';
  } else if (behind > 0) {
    badgeLabel = ' ↓$behind';
  } else {
    badgeLabel = '';
  }

  return CommitPushButtonState(
    canCommit: canCommit,
    canPush: canPush,
    canPull: canPull,
    canPr: canPr,
    canDropdown: canDropdown,
    hasUnknownProbe: hasUnknownProbe,
    badgeLabel: badgeLabel,
    remotes: remotes,
    selectedRemote: remotesData?.selectedRemote ?? 'origin',
  );
}
