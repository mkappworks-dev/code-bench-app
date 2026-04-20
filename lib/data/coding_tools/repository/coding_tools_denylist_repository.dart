import '../models/coding_tools_denylist_state.dart';
import '../models/denylist_category.dart';

abstract interface class CodingToolsDenylistRepository {
  /// Loaded state (user divergence only — baseline lives in DenylistDefaults).
  Future<CodingToolsDenylistState> load();

  /// Persists [state] and returns it unchanged for chaining.
  Future<CodingToolsDenylistState> save(CodingToolsDenylistState state);

  /// Convenience — effective lowercased set for [category], baseline minus
  /// suppressed union user-added. Cached read is fine at service call sites.
  Future<Set<String>> effective(DenylistCategory category);

  /// Clears all user divergence → state == empty().
  Future<void> restoreAllDefaults();
}
