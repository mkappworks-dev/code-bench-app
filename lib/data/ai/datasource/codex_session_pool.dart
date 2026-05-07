import 'dart:async';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';
import 'binary_resolver_process.dart';
import 'codex_session.dart';
import 'process_launcher.dart';

/// Factory typedef matching `CodexSession.new` so tests can inject a stub
/// implementation without driving the real process plumbing.
typedef CodexSessionFactory =
    CodexSession Function({
      required String sessionId,
      required String workingDirectory,
      required String exePath,
      required Map<String, String> env,
      ProcessLauncher? processLauncher,
    });

/// Resolves the Codex binary's absolute path. Tests inject a closure that
/// returns a fixed path; production wires through `resolveBinary`.
typedef ExePathResolver = Future<String> Function();

/// Owns a per-`sessionId` map of live `CodexSession`s. Lazy idle eviction
/// runs at the top of every [sessionFor] call so abandoned chats reclaim
/// memory without a `Timer.periodic` to manage.
class CodexSessionPool {
  CodexSessionPool({
    required this.binaryPath,
    this.idleTimeout = const Duration(minutes: 10),
    ProcessLauncher? processLauncher,
    CodexSessionFactory? sessionFactory,
    ExePathResolver? exePathResolver,
  }) : _processLauncher = processLauncher ?? defaultProcessLauncher,
       _sessionFactory = sessionFactory ?? CodexSession.new,
       _exePathResolver = exePathResolver;

  final String binaryPath;
  final Duration idleTimeout;
  final ProcessLauncher _processLauncher;
  final CodexSessionFactory _sessionFactory;
  final ExePathResolver? _exePathResolver;

  final Map<String, CodexSession> _sessions = {};
  // Resolved independently of CodexCliDatasourceProcess.detect()'s cache; each layer probes once and reuses its own field.
  String? _resolvedPath;
  String? _shellPath;
  bool _disposed = false;

  Future<CodexSession> sessionFor(String sessionId, String workingDirectory) async {
    if (_disposed) throw StateError('CodexSessionPool disposed');
    _evictIdle();
    final existing = _sessions[sessionId];
    if (existing != null && existing.workingDirectory == workingDirectory) {
      return existing;
    }
    if (existing != null) {
      // Same chat moved between projects — rare; tear down and rebuild.
      _sessions.remove(sessionId);
      await existing.dispose();
    }
    final session = _sessionFactory(
      sessionId: sessionId,
      workingDirectory: workingDirectory,
      exePath: await _resolveExePath(),
      env: _buildMinimalEnv(),
      processLauncher: _processLauncher,
    );
    _sessions[sessionId] = session;
    return session;
  }

  void cancel(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) {
      // Likely evicted between Stop click and arrival; without this log a Stop that hits an already-gone session is invisible.
      dLog('[CodexSessionPool] cancel for unknown session $sessionId — no-op (likely evicted)');
      return;
    }
    session.cancel();
  }

  void respondToPermissionRequest(String sessionId, String requestId, {required bool approved}) {
    final session = _sessions[sessionId];
    if (session == null) {
      // A dropped permission response leaves the user's dialog hanging silently — log so it surfaces in triage.
      dLog('[CodexSessionPool] permission response for unknown session $sessionId — no-op (likely evicted)');
      return;
    }
    session.respondToPermissionRequest(requestId, approved: approved);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final all = _sessions.values.toList();
    _sessions.clear();
    await Future.wait(all.map((s) => s.dispose()));
  }

  void _evictIdle() {
    final now = DateTime.now();
    final stale = <MapEntry<String, CodexSession>>[];
    for (final entry in _sessions.entries) {
      if (entry.value.isInFlight) continue;
      // Skip sessions awaiting user permission — eviction would silently abandon the dialog.
      if (entry.value.hasPendingApprovals) continue;
      if (now.difference(entry.value.lastActiveAt) > idleTimeout) {
        stale.add(entry);
      }
    }
    for (final entry in stale) {
      _sessions.remove(entry.key);
      unawaited(
        entry.value.dispose().catchError(
          (Object e) => dLog('[CodexSessionPool] dispose during eviction failed for ${entry.key}: $e'),
        ),
      );
      dLog('[CodexSessionPool] evicted idle session ${entry.key}');
    }
  }

  Future<String> _resolveExePath() async {
    final injected = _exePathResolver;
    if (injected != null) return injected();
    if (_resolvedPath != null) return _resolvedPath!;
    final r = await resolveBinary(binaryPath);
    switch (r) {
      case BinaryFound(:final path, :final shellPath):
        _resolvedPath = path;
        _shellPath = shellPath;
        return path;
      case BinaryNotFound():
        throw Exception('Codex CLI is not installed or not on PATH');
      case BinaryProbeFailed(:final reason):
        throw Exception('Could not probe Codex CLI: $reason');
    }
  }

  Map<String, String> _buildMinimalEnv() {
    final parentEnv = Platform.environment;
    return <String, String>{
      if (parentEnv['HOME'] != null) 'HOME': parentEnv['HOME']!,
      'PATH': _shellPath ?? parentEnv['PATH'] ?? '/usr/bin:/bin:/usr/sbin:/sbin',
      if (parentEnv['USER'] != null) 'USER': parentEnv['USER']!,
      if (parentEnv['LANG'] != null) 'LANG': parentEnv['LANG']!,
      if (parentEnv['TMPDIR'] != null) 'TMPDIR': parentEnv['TMPDIR']!,
      if (parentEnv['SHELL'] != null) 'SHELL': parentEnv['SHELL']!,
      if (parentEnv['CODEX_HOME'] != null) 'CODEX_HOME': parentEnv['CODEX_HOME']!,
    };
  }
}
