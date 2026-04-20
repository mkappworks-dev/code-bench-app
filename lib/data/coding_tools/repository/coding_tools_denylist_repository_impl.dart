import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../_core/preferences/coding_tools_preferences.dart';
import '../models/coding_tools_denylist_state.dart';
import '../models/denylist_category.dart';
import 'coding_tools_denylist_repository.dart';

part 'coding_tools_denylist_repository_impl.g.dart';

@Riverpod(keepAlive: true)
CodingToolsDenylistRepository codingToolsDenylistRepository(Ref ref) =>
    CodingToolsDenylistRepositoryImpl(prefs: ref.read(codingToolsPreferencesProvider));

class CodingToolsDenylistRepositoryImpl implements CodingToolsDenylistRepository {
  CodingToolsDenylistRepositoryImpl({required CodingToolsPreferences prefs}) : _prefs = prefs;

  final CodingToolsPreferences _prefs;

  @override
  Future<CodingToolsDenylistState> load() => _prefs.getDenylistState();

  @override
  Future<CodingToolsDenylistState> save(CodingToolsDenylistState state) async {
    await _prefs.setDenylistState(state);
    return state;
  }

  @override
  Future<Set<String>> effective(DenylistCategory category) async {
    final state = await _prefs.getDenylistState();
    return state.effective(category);
  }

  @override
  Future<void> restoreAllDefaults() => _prefs.clearDenylistState();
}
