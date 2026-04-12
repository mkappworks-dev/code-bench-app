import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/git/git_live_state_provider.dart';
import '../../services/git/git_service.dart' show GitRemote;
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

/// Derives all [CommitPushButton] display flags from live git state,
/// behind-count, and the loaded remote list for [path].
@riverpod
CommitPushButtonState commitPushButtonState(Ref ref, String path) {
  final liveState = ref.watch(gitLiveStateProvider(path)).value;
  final behind = ref.watch(behindCountProvider(path)).value;
  final remotesData = ref.watch(gitRemotesProvider(path)).value;

  final canCommit = liveState?.hasUncommitted == true;
  final canPush = (liveState?.aheadCount ?? 0) > 0;
  final canPull = (behind ?? 0) > 0;
  final canPr = liveState?.branch != null && !(liveState?.isOnDefaultBranch ?? true);
  final remotes = remotesData?.remotes ?? const [];
  final canDropdown = canPush || canPull || canPr || remotes.isNotEmpty;

  // `hasUncommitted == null` or `aheadCount == null` means the git probe
  // failed — show `!` badge so a disabled Commit is never mistaken for
  // a clean repo.
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
