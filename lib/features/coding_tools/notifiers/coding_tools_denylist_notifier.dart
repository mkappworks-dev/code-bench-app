import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/coding_tools/models/coding_tools_denylist_state.dart';
import '../../../data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';

part 'coding_tools_denylist_notifier.g.dart';

/// Loads the user's denylist divergence and rebuilds when the Actions
/// notifier invalidates this provider after a mutation.
@riverpod
class CodingToolsDenylistNotifier extends _$CodingToolsDenylistNotifier {
  @override
  Future<CodingToolsDenylistState> build() => ref.read(codingToolsDenylistRepositoryProvider).load();
}
