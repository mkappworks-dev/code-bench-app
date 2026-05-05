import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/git/models/git_live_state.dart';
import '../../services/git/git_service.dart';

export '../../data/git/models/git_live_state.dart';

part 'git_live_state_notifier.g.dart';

/// Per-project live git state (branch, dirty status, push count).
/// Consumed by both shell notifiers and sidebar widgets.
@riverpod
Future<GitLiveState> gitLiveState(Ref ref, String projectPath) =>
    ref.watch(gitServiceProvider).fetchLiveState(projectPath);

/// Polls remote behind-count every 5 minutes.
@riverpod
Future<int?> behindCount(Ref ref, String projectPath) async {
  final timer = Timer.periodic(const Duration(minutes: 5), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.watch(gitServiceProvider).behindCount(projectPath);
}
