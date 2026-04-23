import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/models/cli_detection.dart';

part 'cli_detection_service.g.dart';

/// Detects local CLI binaries and caches results per-binary with a TTL.
@Riverpod(keepAlive: true)
class CliDetectionService extends _$CliDetectionService {
  final Map<String, _CachedDetection> _cache = {};

  @override
  Map<String, CliDetection> build() => const {};

  Future<CliDetection> probe(String binary, {Duration ttl = const Duration(minutes: 2)}) async {
    final cached = _cache[binary];
    final now = DateTime.now();
    if (cached != null && now.difference(cached.cachedAt) < ttl) {
      return cached.detection;
    }

    final detection = await _runProbe(binary);
    _cache[binary] = _CachedDetection(detection: detection, cachedAt: now);
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
      final versionResult = await Process.run(binary, ['--version']).timeout(const Duration(seconds: 5));
      if (versionResult.exitCode != 0) {
        return const CliDetection.notInstalled();
      }
      final version = _extractVersion(versionResult.stdout.toString());
      final authStatus = await _probeAuth(binary);
      final path = await _which(binary) ?? binary;
      return CliDetection.installed(
        version: version,
        binaryPath: path,
        authStatus: authStatus,
        checkedAt: DateTime.now(),
      );
    } on ProcessException catch (e) {
      dLog('[CliDetectionService] $binary not found: ${e.message}');
      return const CliDetection.notInstalled();
    } catch (e, st) {
      dLog('[CliDetectionService] $binary probe failed: $e\n$st');
      return const CliDetection.notInstalled();
    }
  }

  Future<CliAuthStatus> _probeAuth(String binary) async {
    if (!binary.endsWith('claude')) return CliAuthStatus.unknown;
    try {
      final result = await Process.run(binary, ['auth', 'status']).timeout(const Duration(seconds: 5));
      return result.exitCode == 0 ? CliAuthStatus.authenticated : CliAuthStatus.unauthenticated;
    } catch (_) {
      return CliAuthStatus.unknown;
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
    } catch (_) {}
    return null;
  }
}

class _CachedDetection {
  _CachedDetection({required this.detection, required this.cachedAt});
  final CliDetection detection;
  final DateTime cachedAt;
}
