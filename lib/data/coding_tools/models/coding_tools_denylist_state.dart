import 'package:freezed_annotation/freezed_annotation.dart';

import 'denylist_category.dart';
import 'denylist_defaults.dart';

part 'coding_tools_denylist_state.freezed.dart';

/// User-owned divergence from the baseline, per category.
///   - [userAdded]: entries the user added on top of the baseline.
///   - [suppressedDefaults]: baseline entries the user has opted out of.
///
/// Storage persists only divergence — NOT the full effective list. This
/// keeps baseline changes in future app versions propagating automatically.
@freezed
sealed class CodingToolsDenylistState with _$CodingToolsDenylistState {
  const CodingToolsDenylistState._();

  const factory CodingToolsDenylistState({
    required Map<DenylistCategory, Set<String>> userAdded,
    required Map<DenylistCategory, Set<String>> suppressedDefaults,
  }) = _CodingToolsDenylistState;

  /// Empty state — every baseline entry active, no user additions.
  factory CodingToolsDenylistState.empty() => CodingToolsDenylistState(
    userAdded: {for (final c in DenylistCategory.values) c: const <String>{}},
    suppressedDefaults: {for (final c in DenylistCategory.values) c: const <String>{}},
  );

  /// Effective denylist for [category] — baseline minus suppressed,
  /// union user-added, lowercased.
  Set<String> effective(DenylistCategory category) {
    final base = DenylistDefaults.forCategory(category);
    final suppressed = (suppressedDefaults[category] ?? const <String>{}).map((e) => e.toLowerCase()).toSet();
    final added = userAdded[category] ?? const <String>{};
    return {
      for (final v in base)
        if (!suppressed.contains(v.toLowerCase())) v.toLowerCase(),
      for (final v in added) v.toLowerCase(),
    };
  }
}
