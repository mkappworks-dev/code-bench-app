import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/coding_tools/models/coding_tools_denylist_state.dart';
import '../../data/coding_tools/models/denylist_category.dart';
import '../../data/coding_tools/models/denylist_defaults.dart';
import '../../data/coding_tools/repository/coding_tools_denylist_repository.dart';
import '../../data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';
import '../../data/coding_tools/coding_tools_exceptions.dart';

export '../../data/coding_tools/models/coding_tools_denylist_state.dart';
export '../../data/coding_tools/coding_tools_exceptions.dart';

part 'coding_tools_denylist_service.g.dart';

@Riverpod(keepAlive: true)
CodingToolsDenylistService codingToolsDenylistService(Ref ref) =>
    CodingToolsDenylistService(repo: ref.read(codingToolsDenylistRepositoryProvider));

/// Business logic for reading and mutating the user's denylist divergence.
///
/// Notifiers call this service; the repository is kept out of the feature layer.
class CodingToolsDenylistService {
  CodingToolsDenylistService({required CodingToolsDenylistRepository repo}) : _repo = repo;

  final CodingToolsDenylistRepository _repo;

  /// Returns the current persisted state.
  Future<CodingToolsDenylistState> load() => _repo.load();

  /// Adds [value] to the user-added set for [category].
  ///
  /// Throws [CodingToolsInvalidEntryException] when [value] is blank.
  /// Throws [CodingToolsDuplicateEntryException] when already present.
  Future<void> addUserEntry(DenylistCategory category, String value) async {
    final normalised = value.trim().toLowerCase();
    if (normalised.isEmpty) throw const CodingToolsInvalidEntryException();
    final current = await _repo.load();
    final added = {...(current.userAdded[category] ?? const <String>{})};
    final baseline = DenylistDefaults.forCategory(category);
    if (added.contains(normalised) || baseline.contains(normalised)) {
      throw const CodingToolsDuplicateEntryException();
    }
    added.add(normalised);
    await _repo.save(current.copyWith(userAdded: {...current.userAdded, category: added}));
  }

  /// Removes [value] from the user-added set for [category].
  Future<void> removeUserEntry(DenylistCategory category, String value) async {
    final normalised = value.trim().toLowerCase();
    final current = await _repo.load();
    final added = {...(current.userAdded[category] ?? const <String>{})}..remove(normalised);
    await _repo.save(current.copyWith(userAdded: {...current.userAdded, category: added}));
  }

  /// Adds [value] to the suppressed-defaults set for [category].
  Future<void> suppressBaseline(DenylistCategory category, String value) async {
    final normalised = value.trim().toLowerCase();
    final current = await _repo.load();
    final suppressed = {...(current.suppressedDefaults[category] ?? const <String>{})}..add(normalised);
    await _repo.save(current.copyWith(suppressedDefaults: {...current.suppressedDefaults, category: suppressed}));
  }

  /// Removes [value] from the suppressed-defaults set for [category].
  Future<void> restoreBaseline(DenylistCategory category, String value) async {
    final normalised = value.trim().toLowerCase();
    final current = await _repo.load();
    final suppressed = {...(current.suppressedDefaults[category] ?? const <String>{})}..remove(normalised);
    await _repo.save(current.copyWith(suppressedDefaults: {...current.suppressedDefaults, category: suppressed}));
  }

  /// Clears userAdded and suppressedDefaults for a single [category].
  Future<void> restoreCategory(DenylistCategory category) async {
    final current = await _repo.load();
    await _repo.save(
      current.copyWith(
        userAdded: {...current.userAdded, category: <String>{}},
        suppressedDefaults: {...current.suppressedDefaults, category: <String>{}},
      ),
    );
  }

  /// Clears all user divergence across every category.
  Future<void> restoreAll() => _repo.restoreAllDefaults();
}
