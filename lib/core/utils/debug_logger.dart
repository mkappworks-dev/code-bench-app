import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Debug-only logger. Stripped from release builds.
/// Usage: dLog('[Tag] message: $e\n$st');
void dLog(String message) {
  if (kDebugMode) debugPrint(message);
}

/// Security logger. Persists in release builds via the platform's
/// structured logger (Console.app on macOS, logcat on Android).
/// Use for events that must remain grep-able after shipping —
/// path-traversal rejections, auth failures, sandbox violations.
void sLog(String message) {
  developer.log(message, name: 'security', level: 900);
}

final _openaiKey = RegExp(r'sk-(?:proj-)?[A-Za-z0-9\-_]{16,}');
final _anthropicKey = RegExp(r'sk-ant-[A-Za-z0-9\-_]{16,}');
final _geminiKey = RegExp(r'AIza[A-Za-z0-9\-_]{20,}');
final _ghPat = RegExp(r'(ghp|gho|ghu|ghs|ghr|github_pat)_[A-Za-z0-9_]{20,}');
final _basicAuth = RegExp(r'(https?://)([^/@\s]+)@');
final _bearer = RegExp(r'(authorization:?\s*bearer\s+)[^\s"]+', caseSensitive: false);

/// Defence-in-depth redaction — prevents API keys, PATs, and auth headers from reaching log output.
String redactSecrets(String input) {
  return input
      .replaceAll(_openaiKey, '[redacted-key]')
      .replaceAll(_anthropicKey, '[redacted-key]')
      .replaceAll(_geminiKey, '[redacted-key]')
      .replaceAll(_ghPat, '[redacted-token]')
      .replaceAllMapped(_basicAuth, (m) => '${m[1]}[redacted]@')
      .replaceAllMapped(_bearer, (m) => '${m[1]}[redacted]');
}
