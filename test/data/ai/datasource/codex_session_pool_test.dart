import 'package:code_bench_app/data/ai/datasource/codex_session.dart';
import 'package:code_bench_app/data/ai/datasource/codex_session_pool.dart';
import 'package:code_bench_app/data/ai/datasource/process_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCodexSession extends Fake implements CodexSession {
  _FakeCodexSession({required this.sessionId, required this.workingDirectory, DateTime? lastActiveAt})
    : _lastActiveAt = lastActiveAt ?? DateTime.now();

  @override
  final String sessionId;

  @override
  final String workingDirectory;

  DateTime _lastActiveAt;

  @override
  DateTime get lastActiveAt => _lastActiveAt;
  set lastActiveAt(DateTime value) => _lastActiveAt = value;

  @override
  bool isInFlight = false;

  @override
  bool hasPendingApprovals = false;

  bool disposed = false;
  bool cancelled = false;
  String? lastApprovalRequestId;
  bool? lastApproved;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  void cancel() {
    cancelled = true;
  }

  @override
  void respondToPermissionRequest(String requestId, {required bool approved}) {
    lastApprovalRequestId = requestId;
    lastApproved = approved;
  }
}

CodexSessionPool _poolWithFakeFactory(
  Map<String, _FakeCodexSession> registry, {
  Duration idleTimeout = const Duration(minutes: 10),
}) {
  return CodexSessionPool(
    binaryPath: 'codex',
    idleTimeout: idleTimeout,
    sessionFactory:
        ({
          required sessionId,
          required workingDirectory,
          required exePath,
          required env,
          ProcessLauncher? processLauncher,
        }) {
          final fake = _FakeCodexSession(sessionId: sessionId, workingDirectory: workingDirectory);
          registry[sessionId] = fake;
          return fake;
        },
    exePathResolver: () async => '/fake/codex',
  );
}

void main() {
  group('CodexSessionPool.sessionFor', () {
    test('returns the same instance for the same (sessionId, workingDirectory)', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      final a = await pool.sessionFor('session-1', '/proj/a');
      final b = await pool.sessionFor('session-1', '/proj/a');

      expect(identical(a, b), isTrue);
      expect(registry.length, 1);
    });

    test('disposes the existing session when workingDirectory changes for the same sessionId', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      final original = await pool.sessionFor('session-1', '/proj/a') as _FakeCodexSession;
      final replacement = await pool.sessionFor('session-1', '/proj/b') as _FakeCodexSession;

      expect(original.disposed, isTrue);
      expect(identical(original, replacement), isFalse);
      expect(replacement.workingDirectory, '/proj/b');
    });

    test('keeps independent sessions for different sessionIds', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      final a = await pool.sessionFor('session-1', '/proj/a') as _FakeCodexSession;
      final b = await pool.sessionFor('session-2', '/proj/b') as _FakeCodexSession;

      expect(identical(a, b), isFalse);
      expect(a.disposed, isFalse);
      expect(b.disposed, isFalse);
    });
  });

  group('CodexSessionPool eviction', () {
    test('evicts sessions idle longer than idleTimeout', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry, idleTimeout: const Duration(milliseconds: 1));

      final stale = await pool.sessionFor('stale', '/p') as _FakeCodexSession;
      stale.lastActiveAt = DateTime.now().subtract(const Duration(minutes: 1));

      // Trigger lazy eviction by asking for a different session.
      await pool.sessionFor('fresh', '/p');

      expect(stale.disposed, isTrue);
    });

    test('does NOT evict an in-flight session even when lastActiveAt is old', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry, idleTimeout: const Duration(milliseconds: 1));

      final inFlight = await pool.sessionFor('long-turn', '/p') as _FakeCodexSession;
      inFlight.lastActiveAt = DateTime.now().subtract(const Duration(minutes: 1));
      inFlight.isInFlight = true;

      await pool.sessionFor('other', '/p');

      expect(inFlight.disposed, isFalse);
    });
  });

  group('CodexSessionPool.cancel', () {
    test('cancels the matching session and leaves others alone', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      await pool.sessionFor('a', '/p');
      await pool.sessionFor('b', '/p');

      pool.cancel('a');

      expect(registry['a']!.cancelled, isTrue);
      expect(registry['b']!.cancelled, isFalse);
    });

    test('is a no-op for an unknown sessionId', () {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      expect(() => pool.cancel('nope'), returnsNormally);
    });
  });

  group('CodexSessionPool.respondToPermissionRequest', () {
    test('routes approval to the matching session', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      await pool.sessionFor('a', '/p');
      pool.respondToPermissionRequest('a', 'req-1', approved: true);

      expect(registry['a']!.lastApprovalRequestId, 'req-1');
      expect(registry['a']!.lastApproved, isTrue);
    });
  });

  group('CodexSessionPool.dispose', () {
    test('disposes every live session', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      await pool.sessionFor('a', '/p');
      await pool.sessionFor('b', '/p');

      await pool.dispose();

      expect(registry['a']!.disposed, isTrue);
      expect(registry['b']!.disposed, isTrue);
    });

    test('sessionFor throws StateError after dispose', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      await pool.dispose();

      expect(() => pool.sessionFor('a', '/p'), throwsA(isA<StateError>()));
    });

    test('dispose is idempotent', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry);

      await pool.sessionFor('a', '/p');
      await pool.dispose();
      // Second call must not double-dispose nor throw.
      await pool.dispose();
    });
  });

  group('CodexSessionPool eviction (pending approvals)', () {
    test('does NOT evict a session that still has pending approvals', () async {
      final registry = <String, _FakeCodexSession>{};
      final pool = _poolWithFakeFactory(registry, idleTimeout: const Duration(milliseconds: 1));

      final waiting = await pool.sessionFor('approvals', '/p') as _FakeCodexSession;
      waiting.lastActiveAt = DateTime.now().subtract(const Duration(minutes: 1));
      waiting.hasPendingApprovals = true;

      await pool.sessionFor('other', '/p');

      expect(waiting.disposed, isFalse);
    });
  });
}
