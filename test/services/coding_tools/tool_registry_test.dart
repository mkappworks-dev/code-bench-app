// test/services/coding_tools/tool_registry_test.dart

import 'dart:io';

import 'package:code_bench_app/data/_core/preferences/coding_tools_preferences.dart';
import 'package:code_bench_app/data/apply/repository/apply_repository_impl.dart';
import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tools_denylist_state.dart';
import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
import 'package:code_bench_app/data/coding_tools/models/tool.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_context.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_denylist_repository.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/data/filesystem/datasource/filesystem_datasource_io.dart';
import 'package:code_bench_app/data/filesystem/repository/filesystem_repository_impl.dart';
import 'package:code_bench_app/data/session/models/session_settings.dart';
import 'package:code_bench_app/services/apply/apply_service.dart';
import 'package:code_bench_app/services/coding_tools/tool_registry.dart';
import 'package:code_bench_app/services/coding_tools/tools/list_dir_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/read_file_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/str_replace_tool.dart';
import 'package:code_bench_app/services/coding_tools/tools/write_file_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyDenylistRepo implements CodingToolsDenylistRepository {
  @override
  Future<CodingToolsDenylistState> load() async => CodingToolsDenylistState.empty();
  @override
  Future<CodingToolsDenylistState> save(CodingToolsDenylistState state) async => state;
  @override
  Future<Set<String>> effective(DenylistCategory category) async => {};
  @override
  Future<void> restoreAllDefaults() async {}
}

class _FakeShellTool implements Tool {
  @override
  String get name => 'fake_shell';
  @override
  ToolCapability get capability => ToolCapability.shell;
  @override
  String get description => 'test shell tool';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  Map<String, dynamic> toOpenAiToolJson() => const {};
  @override
  Future<CodingToolResult> execute(ToolContext ctx) async => CodingToolResult.success('');
}

class _AlwaysCrashesTool implements Tool {
  @override
  String get name => 'crasher';
  @override
  ToolCapability get capability => ToolCapability.readOnly;
  @override
  String get description => 'always crashes for test purposes';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  Map<String, dynamic> toOpenAiToolJson() => const {};
  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    throw StateError('boom');
  }
}

class _ThrowingDenylistRepo implements CodingToolsDenylistRepository {
  @override
  Future<CodingToolsDenylistState> load() async => CodingToolsDenylistState.empty();
  @override
  Future<CodingToolsDenylistState> save(CodingToolsDenylistState state) async => state;
  @override
  Future<Set<String>> effective(DenylistCategory category) async {
    throw StateError('prefs unavailable');
  }

  @override
  Future<void> restoreAllDefaults() async {}
}

ToolRegistry _newRegistry({required Directory projectDir, CodingToolsDenylistRepository? denylistRepo}) {
  final applyRepo = ApplyRepositoryImpl(fs: FilesystemRepositoryImpl(FilesystemDatasourceIo()));
  final applySvc = ApplyService(repo: applyRepo);
  final codingRepo = CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());
  return ToolRegistry(
    builtIns: [
      ReadFileTool(repo: codingRepo),
      ListDirTool(repo: codingRepo),
      WriteFileTool(applyService: applySvc),
      StrReplaceTool(repo: codingRepo, applyService: applySvc),
    ],
    denylistRepo: denylistRepo ?? _EmptyDenylistRepo(),
  );
}

void main() {
  late Directory projectDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    projectDir = await Directory.systemTemp.createTemp('tool_reg_');
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  group('byName / byCapability', () {
    test('byName returns the registered tool', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.byName('read_file')?.name, 'read_file');
      expect(r.byName('nonexistent'), isNull);
    });

    test('byCapability filters correctly', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.byCapability(ToolCapability.readOnly).map((t) => t.name).toSet(), {'read_file', 'list_dir'});
      expect(r.byCapability(ToolCapability.mutatingFiles).map((t) => t.name).toSet(), {'write_file', 'str_replace'});
      expect(r.byCapability(ToolCapability.shell), isEmpty);
      expect(r.byCapability(ToolCapability.network), isEmpty);
    });
  });

  group('visibleTools', () {
    test('readOnly returns only readOnly-capability tools', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.visibleTools(ChatPermission.readOnly).map((t) => t.name).toList(), ['read_file', 'list_dir']);
    });

    test('askBefore returns all tools', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.visibleTools(ChatPermission.askBefore).length, 4);
    });

    test('fullAccess returns all tools', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.visibleTools(ChatPermission.fullAccess).length, 4);
    });
  });

  group('requiresPrompt', () {
    test('askBefore + readOnly = false', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.requiresPrompt(r.byName('read_file')!, ChatPermission.askBefore), isFalse);
    });

    test('askBefore + mutatingFiles = true', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(r.requiresPrompt(r.byName('write_file')!, ChatPermission.askBefore), isTrue);
      expect(r.requiresPrompt(r.byName('str_replace')!, ChatPermission.askBefore), isTrue);
    });

    test('fullAccess never prompts', () {
      final r = _newRegistry(projectDir: projectDir);
      for (final t in r.tools) {
        expect(r.requiresPrompt(t, ChatPermission.fullAccess), isFalse);
      }
    });

    test('readOnly permission never prompts', () {
      final r = _newRegistry(projectDir: projectDir);
      for (final t in r.tools) {
        expect(r.requiresPrompt(t, ChatPermission.readOnly), isFalse);
      }
    });

    test('shell-capability tool always requires prompt under every ChatPermission', () {
      final r = _newRegistry(projectDir: projectDir);
      r.register(_FakeShellTool());
      final t = r.byName('fake_shell')!;
      for (final p in ChatPermission.values) {
        expect(r.requiresPrompt(t, p), isTrue, reason: 'expected prompt for $p');
      }
    });
  });

  group('register / unregister', () {
    test('register adds tool at the end', () {
      final r = _newRegistry(projectDir: projectDir);
      final before = r.tools.length;
      r.register(_AlwaysCrashesTool());
      expect(r.tools.length, before + 1);
      expect(r.tools.last.name, 'crasher');
    });

    test('register throws on name collision', () {
      final r = _newRegistry(projectDir: projectDir);
      expect(
        () => r.register(ReadFileTool(repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()))),
        throwsStateError,
      );
    });

    test('unregister removes the tool', () {
      final r = _newRegistry(projectDir: projectDir);
      r.register(_AlwaysCrashesTool());
      r.unregister('crasher');
      expect(r.byName('crasher'), isNull);
    });
  });

  group('execute', () {
    test('dispatches to the named tool', () async {
      File(p.join(projectDir.path, 'a.txt')).writeAsStringSync('hi');
      final r = _newRegistry(projectDir: projectDir);
      final result = await r.execute(
        name: 'read_file',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: {'path': 'a.txt'},
      );
      expect(result, isA<CodingToolResultSuccess>());
      expect((result as CodingToolResultSuccess).output, 'hi');
    });

    test('returns "Unknown tool" for unknown names', () async {
      final r = _newRegistry(projectDir: projectDir);
      final result = await r.execute(
        name: 'nope',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: const {},
      );
      expect(result, isA<CodingToolResultError>());
      expect((result as CodingToolResultError).message, contains('Unknown tool "nope"'));
    });

    test('catches tool crashes and returns error result', () async {
      final r = _newRegistry(projectDir: projectDir);
      r.register(_AlwaysCrashesTool());
      final result = await r.execute(
        name: 'crasher',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: const {},
      );
      expect(result, isA<CodingToolResultError>());
      final msg = (result as CodingToolResultError).message;
      expect(msg, isNot(contains('StateError')));
      expect(msg, contains('encountered an internal error'));
    });
  });

  group('execute — denylist load failure', () {
    test('returns error result instead of throwing', () async {
      final codingRepo = CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());
      final registry = ToolRegistry(
        builtIns: [ReadFileTool(repo: codingRepo)],
        denylistRepo: _ThrowingDenylistRepo(),
      );
      final result = await registry.execute(
        name: 'read_file',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: {'path': 'a.txt'},
      );
      expect(result, isA<CodingToolResultError>());
      final msg = (result as CodingToolResultError).message;
      expect(msg, contains('read_file'));
      expect(msg, isNot(contains('StateError')));
    });
  });

  group('configurable denylist', () {
    test('user-added filename refused on read_file', () async {
      final prefs = CodingToolsPreferences();
      final denylistRepo = CodingToolsDenylistRepositoryImpl(prefs: prefs);
      await denylistRepo.save(
        (await denylistRepo.load()).copyWith(
          userAdded: {
            DenylistCategory.filename: {'custom_secret'},
            for (final c in DenylistCategory.values)
              if (c != DenylistCategory.filename) c: <String>{},
          },
        ),
      );
      final r = _newRegistry(projectDir: projectDir, denylistRepo: denylistRepo);
      File(p.join(projectDir.path, 'custom_secret')).writeAsStringSync('sensitive');
      final result = await r.execute(
        name: 'read_file',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: {'path': 'custom_secret'},
      );
      expect(result, isA<CodingToolResultError>());
      expect((result as CodingToolResultError).message, contains('blocked for safety'));
    });

    test('suppressed baseline filename allowed on read_file', () async {
      final prefs = CodingToolsPreferences();
      final denylistRepo = CodingToolsDenylistRepositoryImpl(prefs: prefs);
      await denylistRepo.save(
        (await denylistRepo.load()).copyWith(
          suppressedDefaults: {
            DenylistCategory.filename: {'credentials'},
            for (final c in DenylistCategory.values)
              if (c != DenylistCategory.filename) c: <String>{},
          },
        ),
      );
      final r = _newRegistry(projectDir: projectDir, denylistRepo: denylistRepo);
      File(p.join(projectDir.path, 'credentials')).writeAsStringSync('not-actually-secret');
      final result = await r.execute(
        name: 'read_file',
        projectPath: projectDir.path,
        sessionId: 's',
        messageId: 'm',
        args: {'path': 'credentials'},
      );
      expect(result, isA<CodingToolResultSuccess>());
    });
  });
}
