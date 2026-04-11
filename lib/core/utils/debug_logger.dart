import 'package:flutter/foundation.dart';

/// Debug-only logger. Stripped from release builds.
/// Usage: dLog('[Tag] message: $e\n$st');
void dLog(String message) {
  if (kDebugMode) debugPrint(message);
}
