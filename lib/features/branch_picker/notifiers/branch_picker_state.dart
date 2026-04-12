import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch_picker_state.freezed.dart';

@freezed
abstract class BranchPickerState with _$BranchPickerState {
  const factory BranchPickerState({@Default([]) List<String> branches, @Default({}) Set<String> worktreeBranches}) =
      _BranchPickerState;
}
