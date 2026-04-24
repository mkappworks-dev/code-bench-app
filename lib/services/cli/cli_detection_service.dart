import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/models/cli_detection.dart';

part 'cli_detection_service.g.dart';

/// Detects local CLI binaries and caches results per-binary with a TTL.
///
/// Authentication status is intentionally NOT probed: Claude Code has no
/// stable `auth status` subcommand, and probing via a real request would
/// burn credits. Installed → [CliAuthStatus.unknown] always; the user
/// discovers auth state when they send a message and either succeeds or
/// gets a typed failure.
@Riverpod(keepAlive: true)
class CliDetectionService extends _$CliDetectionService {
  final Map<String, _CachedDetection> _cache = {};

  @override
  Map<String, CliDetection> build() => const {};

  Future<CliDetection> probe(String binary, {Duration ttl = const Duration(minutes: 2)}) async {
    final cached = _cache[binary];
    final now = DateTime.now();
    if (cached != null && now.difference(cached.cachedAt) < ttl) {
      // Invalidate the cache early if the resolved binary was replaced
      // on disk (e.g. a `brew upgrade` or an attacker substituting a
      // look-alike). Comparing mtime is cheap and avoids a stale
      // "v1.0.0 authenticated" result for up to 2 minutes.
      if (cached.binaryMtime != null && cached.resolvedPath != null) {
        try {
          final currentMtime = File(cached.resolvedPath!).statSync().modified;
          if (currentMtime == cached.binaryMtime) return cached.detection;
          dLog('[CliDetectionService] $binary mtime changed; refreshing probe');
        } on FileSystemException {
          // Binary disappeared between cache hit and stat — fall through
          // to re-probe rather than serve a stale hit.
        }
      } else {
        return cached.detection;
      }
    }

    final detection = await _runProbe(binary);
    DateTime? mtime;
    String? path;
    if (detection is CliInstalled) {
      path = detection.binaryPath;
      try {
        mtime = File(path).statSync().modified;
      } on FileSystemException {
        // Best-effort; if we can't stat, we just skip mtime-based eviction.
      }
    }
    _cache[binary] = _CachedDetection(detection: detection, cachedAt: now, resolvedPath: path, binaryMtime: mtime);
    state = {...state, binary: detection};
    return detection;
  }

  void invalidate(String binary) {
    _cache.remove(binary);
    final next = {...state}..remove(binary);
    state = next;
  }

  Future<CliDetection> _runProbe(String binary) async {
    try {
      final path = await _which(binary) ?? binary;
      final versionResult = await Process.run(path, ['--version']).timeout(const Duration(seconds: 5));
      if (versionResult.exitCode != 0) {
        return const CliDetection.notInstalled();
      }
      return CliDetection.installed(
        version: _extractVersion(versionResult.stdout.toString()),
        binaryPath: path,
        // Auth state is unknowable without burning a real request; see
        // the class-level doc comment.
        authStatus: CliAuthStatus.unknown,
        checkedAt: DateTime.now(),
      );
    } on ProcessException catch (e) {
      dLog('[CliDetectionService] $binary not found: ${e.message}');
      return const CliDetection.notInstalled();
    } on TimeoutException catch (e) {
      dLog('[CliDetectionService] $binary probe timed out: $e');
      return const CliDetection.notInstalled();
    } on FileSystemException catch (e) {
      dLog('[CliDetectionService] $binary probe filesystem error: $e');
      return const CliDetection.notInstalled();
    }
  }

  String _extractVersion(String output) {
    final match = RegExp(r'(\d+\.\d+(?:\.\d+)?)').firstMatch(output);
    return match?.group(1) ?? 'unknown';
  }

  Future<String?> _which(String binary) async {
    try {
      final result = await Process.run('which', [binary]).timeout(const Duration(seconds: 2));
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } on ProcessException catch (e) {
      dLog('[CliDetectionService] which($binary) failed: ${e.message}');
    } on TimeoutException {
      dLog('[CliDetectionService] which($binary) timed out');
    }
    return null;
  }
}

class _CachedDetection {
  _CachedDetection({required this.detection, required this.cachedAt, this.resolvedPath, this.binaryMtime});
  final CliDetection detection;
  final DateTime cachedAt;
  final String? resolvedPath;
  final DateTime? binaryMtime;
}
