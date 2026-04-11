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
