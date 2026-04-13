import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/git/git_service.dart';

part 'git_remotes_notifier.freezed.dart';
part 'git_remotes_notifier.g.dart';

@freezed
abstract class GitRemotesState with _$GitRemotesState {
  const factory GitRemotesState({required List<GitRemote> remotes, required String selectedRemote}) = _GitRemotesState;
}

/// Loads the configured git remotes for [path] once on mount and tracks
/// which remote the user has selected for the next Push.
///
/// Family: one provider instance per project path — disposes when the
/// widget tree stops watching it.
@riverpod
class GitRemotesNotifier extends _$GitRemotesNotifier {
  @override
  Future<GitRemotesState> build(String path) async {
    final gitService = ref.watch(gitServiceProvider(path));
    final remotes = await gitService.listRemotes();
    // Default to `origin` if present; otherwise fall back to the first
    // remote so `push` always has a valid target on first render.
    final selected = (remotes.isNotEmpty && !remotes.any((r) => r.name == 'origin')) ? remotes.first.name : 'origin';
    return GitRemotesState(remotes: remotes, selectedRemote: selected);
  }

  void selectRemote(String name) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedRemote: name));
  }
}
