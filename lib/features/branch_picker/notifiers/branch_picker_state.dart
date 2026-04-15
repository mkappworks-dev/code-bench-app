import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch_picker_state.freezed.dart';

@freezed
abstract class BranchPickerState with _$BranchPickerState {
  const factory BranchPickerState({
    @Default([]) List<String> branches,

    /// Maps branch name → worktree filesystem path for every worktree
    /// OTHER than the current project. Used by the picker to show the
    /// "worktree" badge and to navigate to a worktree on tap.
    @Default({}) Map<String, String> worktreePaths,

    /// Branch names that are locked to prunable (stale) worktrees — the
    /// worktree directory no longer exists on disk. Excluded from all
    /// "From" dropdowns to avoid confusing the user.
    @Default(<String>{}) Set<String> staleBranches,
  }) = _BranchPickerState;
}
