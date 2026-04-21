// test/data/coding_tools/models/tool_context_test.dart

import 'dart:io';

import 'package:code_bench_app/data/coding_tools/models/effective_denylist.dart';
import 'package:code_bench_app/data/coding_tools/models/path_result.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_context.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

EffectiveDenylist _empty() =>
    (segments: const <String>{}, filenames: const <String>{}, extensions: const <String>{}, prefixes: const <String>{});

ToolContext _ctx({required String projectPath, Map<String, dynamic> args = const {}, EffectiveDenylist? denylist}) =>
    ToolContext(projectPath: projectPath, sessionId: 's', messageId: 'm', args: args, denylist: denylist ?? _empty());

void main() {
  late Directory projectDir;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('tool_ctx_');
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  group('safePath — arg validation', () {
    test('missing arg returns PathErr with "requires a non-empty" message', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {});
      final r = ctx.safePath('path', verb: 'Read');
      expect(r, isA<PathErr>());
      final err = (r as PathErr).result;
      expect(err, isA<CodingToolResultError>());
      expect((err as CodingToolResultError).message, contains('requires a non-empty "path"'));
    });

    test('non-string arg returns PathErr', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': 42});
      expect(ctx.safePath('path', verb: 'Read'), isA<PathErr>());
    });

    test('empty-string arg returns PathErr', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': ''});
      expect(ctx.safePath('path', verb: 'Read'), isA<PathErr>());
    });
  });

  group('safePath — happy path', () {
    test('returns PathOk with absolute path and sanitized displayRaw', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': 'a.txt'});
      final r = ctx.safePath('path', verb: 'Read');
      expect(r, isA<PathOk>());
      final ok = r as PathOk;
      expect(ok.abs, p.normalize(p.join(projectDir.path, 'a.txt')));
      expect(ok.displayRaw, 'a.txt');
    });

    test('accepts absolute path inside the project', () {
      final inside = p.join(projectDir.path, 'sub', 'x.txt');
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': inside});
      expect(ctx.safePath('path', verb: 'Read'), isA<PathOk>());
    });
  });

  group('safePath — project-boundary', () {
    test('rejects relative path that escapes the project', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': '../../etc/passwd'});
      final r = ctx.safePath('path', verb: 'Read');
      expect(r, isA<PathErr>());
      final msg = ((r as PathErr).result as CodingToolResultError).message;
      expect(msg, contains('outside the project root'));
      expect(msg, contains('"../../etc/passwd"'));
    });

    test('rejects absolute path outside the project', () {
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': '/etc/passwd'});
      expect(ctx.safePath('path', verb: 'Read'), isA<PathErr>());
    });
  });

  group('safePath — denylist', () {
    test('rejects filename match with "sensitive file" suffix by default', () {
      final d = (
        segments: const <String>{},
        filenames: const <String>{'credentials'},
        extensions: const <String>{},
        prefixes: const <String>{},
      );
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': 'credentials'}, denylist: d);
      final r = ctx.safePath('path', verb: 'Read');
      expect(r, isA<PathErr>());
      final msg = ((r as PathErr).result as CodingToolResultError).message;
      expect(msg, contains('Reading "credentials" is blocked for safety (sensitive file).'));
    });

    test('rejects segment match and uses custom noun', () {
      final d = (
        segments: const <String>{'.git'},
        filenames: const <String>{},
        extensions: const <String>{},
        prefixes: const <String>{},
      );
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': '.git/config'}, denylist: d);
      final r = ctx.safePath('path', verb: 'List', noun: 'directory');
      expect(r, isA<PathErr>());
      final msg = ((r as PathErr).result as CodingToolResultError).message;
      expect(msg, contains('Listing ".git/config" is blocked for safety (sensitive directory).'));
    });

    test('rejects extension match', () {
      final d = (
        segments: const <String>{},
        filenames: const <String>{},
        extensions: const <String>{'.pem'},
        prefixes: const <String>{},
      );
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': 'keys/server.pem'}, denylist: d);
      expect(ctx.safePath('path', verb: 'Read'), isA<PathErr>());
    });

    test('rejects filename-prefix match', () {
      final d = (
        segments: const <String>{},
        filenames: const <String>{},
        extensions: const <String>{},
        prefixes: const <String>{'.env.'},
      );
      final ctx = _ctx(projectPath: projectDir.path, args: {'path': '.env.production'}, denylist: d);
      expect(ctx.safePath('path', verb: 'Read'), isA<PathErr>());
    });
  });

  group('sanitizeForError', () {
    test('strips control characters', () {
      final ctx = _ctx(projectPath: projectDir.path);
      expect(ctx.sanitizeForError('a\nb\tc\x07d'), 'a b c d');
    });

    test('truncates to max with ellipsis', () {
      final ctx = _ctx(projectPath: projectDir.path);
      final long = 'x' * 200;
      final result = ctx.sanitizeForError(long, max: 10);
      expect(result, 'xxxxxxxxxx…');
    });

    test('passes short strings through unchanged', () {
      final ctx = _ctx(projectPath: projectDir.path);
      expect(ctx.sanitizeForError('normal text'), 'normal text');
    });
  });
}
