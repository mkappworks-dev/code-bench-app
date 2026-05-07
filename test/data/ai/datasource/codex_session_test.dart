import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:code_bench_app/data/ai/datasource/codex_session.dart';
import 'package:code_bench_app/data/ai/datasource/process_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeIOSink implements IOSink {
  final List<String> writes = [];

  @override
  void writeln([Object? obj = '']) => writes.add(obj.toString());

  @override
  Future<void> close() async {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> get done => Future.value();

  // Methods we don't exercise — fail loudly if called so tests catch drift.
  @override
  Encoding get encoding => utf8;
  @override
  set encoding(Encoding value) => throw UnimplementedError();
  @override
  void add(List<int> data) => throw UnimplementedError();
  @override
  void addError(Object error, [StackTrace? stackTrace]) => throw UnimplementedError();
  @override
  Future<void> addStream(Stream<List<int>> stream) => throw UnimplementedError();
  @override
  void write(Object? obj) => throw UnimplementedError();
  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) => throw UnimplementedError();
  @override
  void writeCharCode(int charCode) => throw UnimplementedError();
}

class _FakeProcess implements Process {
  _FakeProcess()
    : _stdoutCtrl = StreamController<List<int>>(),
      _stderrCtrl = StreamController<List<int>>(),
      _exitCompleter = Completer<int>();

  final StreamController<List<int>> _stdoutCtrl;
  final StreamController<List<int>> _stderrCtrl;
  final _FakeIOSink _stdin = _FakeIOSink();
  final Completer<int> _exitCompleter;
  bool killed = false;

  @override
  Stream<List<int>> get stdout => _stdoutCtrl.stream;
  @override
  Stream<List<int>> get stderr => _stderrCtrl.stream;
  @override
  IOSink get stdin => _stdin;
  @override
  Future<int> get exitCode => _exitCompleter.future;
  @override
  int get pid => 12345;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    if (!_exitCompleter.isCompleted) _exitCompleter.complete(0);
    return true;
  }

  void emitStdoutLine(String line) => _stdoutCtrl.add(utf8.encode('$line\n'));

  Future<void> exit(int code) async {
    if (!_exitCompleter.isCompleted) _exitCompleter.complete(code);
    await _stdoutCtrl.close();
    await _stderrCtrl.close();
  }
}

ProcessLauncher _launcherReturning(_FakeProcess process) {
  return (
    String exe,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
  }) async {
    return process;
  };
}

CodexSession _makeSession({
  String sessionId = '11111111-1111-4111-8111-111111111111',
  String workingDirectory = '/tmp',
  required ProcessLauncher launcher,
}) {
  return CodexSession(
    sessionId: sessionId,
    workingDirectory: workingDirectory,
    exePath: '/fake/codex',
    env: const {},
    processLauncher: launcher,
  );
}

void main() {
  group('CodexSession', () {
    test('isInFlight is false before any sendAndStream call', () {
      final session = _makeSession(launcher: _launcherReturning(_FakeProcess()));
      expect(session.isInFlight, isFalse);
    });

    test('lastActiveAt is set at construction time', () {
      final before = DateTime.now();
      final session = _makeSession(launcher: _launcherReturning(_FakeProcess()));
      final after = DateTime.now();
      expect(session.lastActiveAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(session.lastActiveAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('dispose is safe to call before any process is spawned', () async {
      final session = _makeSession(launcher: _launcherReturning(_FakeProcess()));
      await expectLater(session.dispose(), completes);
    });
  });
}
