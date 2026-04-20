import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/coding_tools/coding_tools_denylist_service.dart';

part 'coding_tools_denylist_notifier.g.dart';

/// Loads the user's denylist divergence and rebuilds when the Actions
/// notifier invalidates this provider after a mutation.
@riverpod
class CodingToolsDenylistNotifier extends _$CodingToolsDenylistNotifier {
  @override
  Future<CodingToolsDenylistState> build() => ref.read(codingToolsDenylistServiceProvider).load();
}
