import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:code_bench_app/data/ai/datasource/claude_cli_datasource_process.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoOpIOSink implements IOSink {
  @override
  Encoding get encoding => const Utf8Codec();
  @override
  set encoding(Encoding value) {}
  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> flush() async {}
  @override
  Future<void> get done => Future.value();
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = '']) {}
}

class _FakeProcess implements Process {
  _FakeProcess({required this.tag})
    : _stdoutCtrl = StreamController<List<int>>(),
      _stderrCtrl = StreamController<List<int>>(),
      _exitCompleter = Completer<int>();

  final String tag;
  final StreamController<List<int>> _stdoutCtrl;
  final StreamController<List<int>> _stderrCtrl;
  final Completer<int> _exitCompleter;
  bool killed = false;
  ProcessSignal? killSignal;

  @override
  Stream<List<int>> get stdout => _stdoutCtrl.stream;
  @override
  Stream<List<int>> get stderr => _stderrCtrl.stream;
  @override
  IOSink get stdin => _NoOpIOSink();
  @override
  Future<int> get exitCode => _exitCompleter.future;
  @override
  int get pid => tag.hashCode & 0x7fffffff;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    killSignal = signal;
    if (!_exitCompleter.isCompleted) _exitCompleter.complete(143);
    _stdoutCtrl.close();
    _stderrCtrl.close();
    return true;
  }
}

// Valid RFC-4122 v4 UUIDs accepted by uuidV4Regex.
const _sessionA = '11111111-2222-4333-8444-555555555555';
const _sessionB = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';

// A pre-resolved path that bypasses resolveBinary; the value is passed
// to _processLauncher, which is a fake in these tests — the path need not
// exist on disk.
const _fakeBinaryPath = '/usr/local/bin/claude';

void main() {
  group('ClaudeCliDatasourceProcess.cancel routes per sessionId', () {
    test('cancelling session A kills only A; B keeps streaming', () async {
      final processA = _FakeProcess(tag: 'A');
      final processB = _FakeProcess(tag: 'B');
      var callCount = 0;

      Future<Process> launcher(
        String exe,
        List<String> args, {
        String? workingDirectory,
        Map<String, String>? environment,
        bool includeParentEnvironment = true,
        bool runInShell = false,
      }) async {
        callCount++;
        return callCount == 1 ? processA : processB;
      }

      final ds = ClaudeCliDatasourceProcess(
        binaryPath: 'claude',
        processLauncher: launcher,
        resolvedPath: _fakeBinaryPath,
      );

      // Subscribe to both streams concurrently. The fake processes keep stdout
      // open, so the subscriptions stay active until kill() or close().
      final subA = ds.sendAndStream(prompt: 'hello', sessionId: _sessionA, workingDirectory: '/tmp').listen((_) {});
      final subB = ds.sendAndStream(prompt: 'hello', sessionId: _sessionB, workingDirectory: '/tmp').listen((_) {});

      // Yield so both launcher futures are awaited and _processes[sessionId]
      // is populated before we call cancel.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      ds.cancel(_sessionA);

      expect(processA.killed, isTrue, reason: 'cancelling session A should kill its process');
      expect(processB.killed, isFalse, reason: 'cancelling session A must NOT kill session B\'s process');

      // Cleanup: terminate B and cancel subscriptions to avoid pending-timer warnings.
      processB.kill();
      await subA.cancel();
      await subB.cancel();
    });

    test('cancelling an unknown sessionId is a no-op', () {
      final ds = ClaudeCliDatasourceProcess(
        binaryPath: 'claude',
        processLauncher:
            (_, args, {workingDirectory, environment, includeParentEnvironment = true, runInShell = false}) =>
                Future.value(_FakeProcess(tag: 'never-spawned')),
        resolvedPath: _fakeBinaryPath,
      );

      expect(() => ds.cancel('not-a-real-session'), returnsNormally);
    });
  });
}
