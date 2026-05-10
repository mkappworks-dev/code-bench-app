import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/debug_logger.dart';

class ClaudeSessionPreferences {
  static const _kKey = 'claude_cli_known_sessions_v1';

  Future<Set<String>> getKnownSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kKey);
      return list != null ? Set<String>.from(list) : {};
    } catch (e) {
      dLog('[ClaudeSessionPreferences] load failed: ${e.runtimeType}');
      return {};
    }
  }

  Future<void> addKnownSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_kKey) ?? [];
      if (!existing.contains(sessionId)) {
        existing.add(sessionId);
        await prefs.setStringList(_kKey, existing);
      }
    } catch (e) {
      dLog('[ClaudeSessionPreferences] save failed: ${e.runtimeType}');
    }
  }
}
