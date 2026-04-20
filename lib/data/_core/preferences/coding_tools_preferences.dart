import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../coding_tools/models/coding_tools_denylist_state.dart';
import '../../coding_tools/models/denylist_category.dart';

part 'coding_tools_preferences.g.dart';

@Riverpod(keepAlive: true)
CodingToolsPreferences codingToolsPreferences(Ref ref) => CodingToolsPreferences();

class CodingToolsPreferences {
  static const _kDenylistState = 'coding_tools_denylist_state_v1';

  Future<CodingToolsDenylistState> getDenylistState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDenylistState);
    if (raw == null || raw.isEmpty) return CodingToolsDenylistState.empty();
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return _deserialize(decoded);
    } on FormatException {
      return CodingToolsDenylistState.empty();
    }
  }

  Future<void> setDenylistState(CodingToolsDenylistState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDenylistState, jsonEncode(_serialize(state)));
  }

  Future<void> clearDenylistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDenylistState);
  }

  // --- Serialization ---

  Map<String, dynamic> _serialize(CodingToolsDenylistState s) => {
    'userAdded': {for (final e in s.userAdded.entries) e.key.name: e.value.toList()},
    'suppressedDefaults': {for (final e in s.suppressedDefaults.entries) e.key.name: e.value.toList()},
  };

  CodingToolsDenylistState _deserialize(Map<String, dynamic> json) {
    Map<DenylistCategory, Set<String>> parseMap(Object? raw) {
      final out = <DenylistCategory, Set<String>>{for (final c in DenylistCategory.values) c: <String>{}};
      if (raw is! Map) return out;
      for (final entry in raw.entries) {
        final cat = DenylistCategory.values.firstWhere(
          (c) => c.name == entry.key,
          orElse: () => DenylistCategory.filename,
        );
        final list = entry.value;
        if (list is! List) continue;
        out[cat] = {
          for (final v in list)
            if (v is String && v.isNotEmpty) v,
        };
      }
      return out;
    }

    return CodingToolsDenylistState(
      userAdded: parseMap(json['userAdded']),
      suppressedDefaults: parseMap(json['suppressedDefaults']),
    );
  }
}
