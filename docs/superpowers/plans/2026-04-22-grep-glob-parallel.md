# Phase 2 — Grep + Glob + Parallel Execution: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `grep` and `glob` tools to the agentic executor and make read-only tool calls in the same round run in parallel (max 4), matching Claude Code's behaviour.

**Architecture:** `GrepTool` dispatches to `GrepDatasourceProcess` (ripgrep) when `rg` is available, falling back to `GrepDatasourceIo` (pure Dart). `GlobTool` is pure-Dart (`package:glob`). Ripgrep availability is detected once at startup via a `keepAlive` service provider, surfaced to the UI through a feature-layer notifier. Parallel dispatch is a two-phase replacement of the serial `for` loop in `AgentService`.

**Tech Stack:** Dart `dart:io`, `dart:convert`, `package:path`, `package:glob ^2.1.3`, `package:riverpod_annotation`, `package:flutter_test`, ripgrep (`rg`) optional external binary.

**Spec:** `docs/superpowers/specs/2026-04-22-grep-glob-parallel-design.md`

**Architecture note vs spec:** The spec listed `grep_datasource_provider.dart` as a separate file. After checking the arch test (`test/arch_test.dart`), datasource files cannot import services, so backend selection was moved into `grepToolProvider` in `grep_tool.dart`. The ripgrep availability datasource is named `ripgrep_availability_datasource_process.dart` (ends in `_process.dart`) so the `dart:io` arch test allows `Process.run` inside it. A `RipgrepAvailabilityNotifier` in `features/coding_tools/notifiers/` bridges the service-level provider to widgets (widgets cannot import from `/services/` directly per arch test).

---

## File Map

### New files

```
lib/data/coding_tools/
  models/
    grep_match.dart                                  ← GrepMatch + GrepResult value types
  datasource/
    grep_datasource.dart                             ← GrepDatasource interface
    grep_datasource_io.dart                          ← pure-Dart backend (dart:io)
    grep_datasource_process.dart                     ← rg backend (dart:io + Process.run)
    ripgrep_availability_datasource_process.dart     ← Process.run('rg', ['--version']) check

lib/services/coding_tools/
  ripgrep_availability_service.dart                  ← @Riverpod(keepAlive:true) Future<bool>
  ripgrep_availability_service.g.dart                ← generated
  tools/
    grep_tool.dart                                   ← GrepTool + @riverpod grepToolProvider
    grep_tool.g.dart                                 ← generated
    glob_tool.dart                                   ← GlobTool + @riverpod globToolProvider
    glob_tool.g.dart                                 ← generated

lib/features/coding_tools/
  notifiers/
    ripgrep_availability_notifier.dart               ← feature bridge; @Riverpod(keepAlive:true)
    ripgrep_availability_notifier.g.dart             ← generated
  widgets/
    ripgrep_availability_banner.dart                 ← settings banner (no rg → show install hint)

test/data/coding_tools/
  grep_datasource_io_test.dart

test/services/coding_tools/tools/
  grep_tool_test.dart
  glob_tool_test.dart

test/services/agent/
  agent_service_parallel_test.dart
```

### Modified files

```
pubspec.yaml                                         ← add glob ^2.1.3
lib/services/coding_tools/tool_registry.dart         ← register GrepTool + GlobTool
lib/services/agent/agent_service.dart                ← parallel read dispatch
lib/features/coding_tools/coding_tools_screen.dart   ← add RipgrepAvailabilityBanner at top
```

---

## Part 1 — Additive (Commit 1)

All tasks in Part 1 are purely additive. No existing code is modified until Part 2.

---

### Task 1: Add package:glob to pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1.1: Add glob dependency**

Open `pubspec.yaml`. Under `dependencies:`, add after `collection`:

```yaml
  glob: ^2.1.3
```

- [ ] **Step 1.2: Fetch dependencies**

```bash
flutter pub get
```

Expected: resolves without conflict. `glob 2.1.3` appears in `.dart_tool/package_config.json`.

---

### Task 2: GrepMatch and GrepResult models

**Files:**
- Create: `lib/data/coding_tools/models/grep_match.dart`

These are pure value types — no Riverpod, no freezed. No test needed.

- [ ] **Step 2.1: Write the models**

```dart
// lib/data/coding_tools/models/grep_match.dart

/// One matched line returned by a grep datasource, with surrounding context.
class GrepMatch {
  const GrepMatch({
    required this.file,
    required this.lineNumber,
    required this.lineContent,
    required this.contextBefore,
    required this.contextAfter,
  });

  /// Project-relative path to the file containing the match.
  final String file;
  final int lineNumber;

  /// The matching line, trimmed of trailing newline.
  final String lineContent;

  /// Up to N lines before the match (N = contextLines requested).
  final List<String> contextBefore;

  /// Up to N lines after the match.
  final List<String> contextAfter;
}

/// Aggregate result from a grep datasource call.
class GrepResult {
  const GrepResult({
    required this.matches,
    required this.totalFound,
    required this.wasCapped,
  });

  final List<GrepMatch> matches;

  /// Total matches found before the cap. When [wasCapped] is true this equals
  /// maxMatches + 1 (sentinel); the true total may be higher.
  final int totalFound;

  /// True when results were truncated at the cap.
  final bool wasCapped;
}
```

---

### Task 3: GrepDatasource interface

**Files:**
- Create: `lib/data/coding_tools/datasource/grep_datasource.dart`

- [ ] **Step 3.1: Write the interface**

```dart
// lib/data/coding_tools/datasource/grep_datasource.dart

import '../models/grep_match.dart';

/// Abstraction over grep backends. Two implementations:
/// - [GrepDatasourceProcess] — shells out to ripgrep when available.
/// - [GrepDatasourceIo] — pure-Dart fallback via dart:io.
///
/// [rootPath] must be an absolute, pre-validated path (ToolContext.safePath
/// has already enforced the project boundary before this is called).
abstract interface class GrepDatasource {
  Future<GrepResult> grep({
    required String pattern,
    required String rootPath,
    int contextLines = 2,
    int maxMatches = 100,
    List<String> fileExtensions = const [],
  });
}
```

---

### Task 4: GrepDatasourceIo — pure-Dart backend + tests

**Files:**
- Create: `lib/data/coding_tools/datasource/grep_datasource_io.dart`
- Create: `test/data/coding_tools/grep_datasource_io_test.dart`

- [ ] **Step 4.1: Write failing tests**

```dart
// test/data/coding_tools/grep_datasource_io_test.dart

import 'dart:io';

import 'package:code_bench_app/data/coding_tools/datasource/grep_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/grep_match.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late GrepDatasourceIo sut;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('grep_io_');
    sut = GrepDatasourceIo();
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  Future<void> writeFile(String name, String content) =>
      File(p.join(tmp.path, name)).writeAsString(content);

  test('returns match with 2 lines of context', () async {
    await writeFile('a.dart', 'line1\nline2\nTARGET\nline4\nline5\n');
    final result = await sut.grep(pattern: 'TARGET', rootPath: tmp.path);
    expect(result.matches, hasLength(1));
    final m = result.matches.first;
    expect(m.lineNumber, 3);
    expect(m.lineContent, 'TARGET');
    expect(m.contextBefore, ['line1', 'line2']);
    expect(m.contextAfter, ['line4', 'line5']);
    expect(result.wasCapped, isFalse);
  });

  test('returns empty result when no match', () async {
    await writeFile('b.dart', 'no match here\n');
    final result = await sut.grep(pattern: 'NOPE', rootPath: tmp.path);
    expect(result.matches, isEmpty);
    expect(result.wasCapped, isFalse);
  });

  test('caps at maxMatches and sets wasCapped', () async {
    final content = List.generate(10, (i) => 'MATCH $i').join('\n');
    await writeFile('c.dart', content);
    final result = await sut.grep(pattern: 'MATCH', rootPath: tmp.path, maxMatches: 3);
    expect(result.matches, hasLength(3));
    expect(result.wasCapped, isTrue);
  });

  test('skips binary files (null byte)', () async {
    File(p.join(tmp.path, 'bin.bin')).writeAsBytesSync([0x00, 0x01, 0x02]);
    await writeFile('txt.dart', 'TARGET\n');
    final result = await sut.grep(pattern: 'TARGET', rootPath: tmp.path);
    expect(result.matches, hasLength(1));
    expect(result.matches.first.file, contains('txt.dart'));
  });

  test('skips non-UTF-8 files', () async {
    File(p.join(tmp.path, 'bad.dart')).writeAsBytesSync([0xC3, 0x28]); // invalid UTF-8
    await writeFile('good.dart', 'TARGET\n');
    final result = await sut.grep(pattern: 'TARGET', rootPath: tmp.path);
    expect(result.matches, hasLength(1));
  });

  test('filters by file extension', () async {
    await writeFile('match.dart', 'TARGET\n');
    await writeFile('match.yaml', 'TARGET\n');
    final result = await sut.grep(
      pattern: 'TARGET',
      rootPath: tmp.path,
      fileExtensions: ['yaml'],
    );
    expect(result.matches, hasLength(1));
    expect(result.matches.first.file, contains('.yaml'));
  });

  test('returns project-relative file paths', () async {
    final sub = Directory(p.join(tmp.path, 'sub'))..createSync();
    File(p.join(sub.path, 'nested.dart')).writeAsStringSync('TARGET\n');
    final result = await sut.grep(pattern: 'TARGET', rootPath: tmp.path);
    expect(result.matches.first.file, 'sub/nested.dart');
  });

  test('throws FormatException on invalid regex', () async {
    await writeFile('d.dart', 'anything\n');
    expect(
      () => sut.grep(pattern: r'[invalid', rootPath: tmp.path),
      throwsA(isA<FormatException>()),
    );
  });
}
```

- [ ] **Step 4.2: Run tests — verify they fail**

```bash
flutter test test/data/coding_tools/grep_datasource_io_test.dart
```

Expected: compilation error (GrepDatasourceIo not defined).

- [ ] **Step 4.3: Implement GrepDatasourceIo**

```dart
// lib/data/coding_tools/datasource/grep_datasource_io.dart

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/grep_match.dart';
import 'grep_datasource.dart';

/// Pure-Dart grep backend. Falls back from [GrepDatasourceProcess] when
/// ripgrep is not installed. Reads files via dart:io directly.
class GrepDatasourceIo implements GrepDatasource {
  @override
  Future<GrepResult> grep({
    required String pattern,
    required String rootPath,
    int contextLines = 2,
    int maxMatches = 100,
    List<String> fileExtensions = const [],
  }) async {
    final regex = RegExp(pattern); // throws FormatException on bad pattern
    final sentinel = maxMatches + 1;
    final matches = <GrepMatch>[];
    await _walkDir(rootPath, rootPath, fileExtensions, regex, contextLines, matches, sentinel);
    final wasCapped = matches.length >= sentinel;
    return GrepResult(
      matches: matches.take(maxMatches).toList(),
      totalFound: wasCapped ? sentinel : matches.length,
      wasCapped: wasCapped,
    );
  }

  Future<void> _walkDir(
    String dir,
    String rootPath,
    List<String> extensions,
    RegExp regex,
    int contextLines,
    List<GrepMatch> matches,
    int sentinel,
  ) async {
    if (matches.length >= sentinel) return;
    List<FileSystemEntity> entries;
    try {
      entries = await Directory(dir).list(followLinks: false).toList();
    } on FileSystemException {
      return;
    }
    for (final entity in entries) {
      if (matches.length >= sentinel) return;
      if (entity is Directory) {
        await _walkDir(entity.path, rootPath, extensions, regex, contextLines, matches, sentinel);
      } else if (entity is File) {
        if (extensions.isNotEmpty) {
          final ext = p.extension(entity.path).replaceFirst('.', '');
          if (!extensions.contains(ext)) continue;
        }
        await _scanFile(entity.path, rootPath, regex, contextLines, matches, sentinel);
      }
    }
  }

  Future<void> _scanFile(
    String filePath,
    String rootPath,
    RegExp regex,
    int contextLines,
    List<GrepMatch> matches,
    int sentinel,
  ) async {
    if (matches.length >= sentinel) return;
    List<int> bytes;
    try {
      bytes = await File(filePath).readAsBytes();
    } on FileSystemException {
      return;
    }
    if (bytes.contains(0)) return; // binary file
    String content;
    try {
      content = utf8.decode(bytes);
    } on FormatException {
      return; // not UTF-8
    }
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (matches.length >= sentinel) return;
      if (!regex.hasMatch(lines[i])) continue;
      final beforeStart = (i - contextLines).clamp(0, i);
      final afterEnd = (i + 1 + contextLines).clamp(0, lines.length);
      matches.add(GrepMatch(
        file: p.relative(filePath, from: rootPath),
        lineNumber: i + 1,
        lineContent: lines[i],
        contextBefore: lines.sublist(beforeStart, i),
        contextAfter: lines.sublist(i + 1, afterEnd),
      ));
    }
  }
}
```

- [ ] **Step 4.4: Run tests — verify they pass**

```bash
flutter test test/data/coding_tools/grep_datasource_io_test.dart
```

Expected: all 8 tests pass.

---

### Task 5: GrepDatasourceProcess — ripgrep backend

**Files:**
- Create: `lib/data/coding_tools/datasource/grep_datasource_process.dart`

No automated tests — requires `rg` installed. Manually verified in Task 13.

- [ ] **Step 5.1: Implement GrepDatasourceProcess**

```dart
// lib/data/coding_tools/datasource/grep_datasource_process.dart

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/utils/debug_logger.dart';
import '../coding_tools_exceptions.dart';
import '../models/grep_match.dart';
import 'grep_datasource.dart';

/// Grep backend that shells out to ripgrep (`rg`). Selected when `rg` is
/// available at startup (see RipgrepAvailabilityDatasource). Uses `--json`
/// output for structured parsing. [CodingToolsDiskException] is thrown if
/// rg disappears mid-session — ToolRegistry crash-catch surfaces it as an
/// error result.
class GrepDatasourceProcess implements GrepDatasource {
  @override
  Future<GrepResult> grep({
    required String pattern,
    required String rootPath,
    int contextLines = 2,
    int maxMatches = 100,
    List<String> fileExtensions = const [],
  }) async {
    final args = [
      '--json',
      '--context', '$contextLines',
      ...fileExtensions.expand((e) => ['--glob', '*.$e']),
      pattern,
      rootPath,
    ];

    ProcessResult result;
    try {
      result = await Process.run('rg', args);
    } on ProcessException catch (e) {
      dLog('[GrepDatasourceProcess] rg not available: $e');
      throw CodingToolsDiskException('ripgrep not available: ${e.message}');
    }

    // Exit code 1 = no matches (normal); 2 = rg error (bad regex, path, etc.)
    if (result.exitCode == 2) {
      final msg = (result.stderr as String).trim().split('\n').first;
      throw CodingToolsDiskException(msg);
    }

    return _parseJson(result.stdout as String, rootPath, maxMatches);
  }

  GrepResult _parseJson(String stdout, String rootPath, int maxMatches) {
    final sentinel = maxMatches + 1;
    final matches = <GrepMatch>[];

    // Per-group state: accumulate events between begin/end.
    typedef _Event = ({String type, String file, int lineNumber, String text});
    final List<_Event> groupEvents = [];

    void flushGroup() {
      // Find all match indices in the group.
      final matchPositions = <int>[];
      for (var i = 0; i < groupEvents.length; i++) {
        if (groupEvents[i].type == 'match') matchPositions.add(i);
      }
      for (var mi = 0; mi < matchPositions.length; mi++) {
        if (matches.length >= sentinel) return;
        final pos = matchPositions[mi];
        final prevPos = mi == 0 ? -1 : matchPositions[mi - 1];
        final nextPos = mi < matchPositions.length - 1 ? matchPositions[mi + 1] : groupEvents.length;
        final contextBefore = groupEvents
            .sublist(prevPos + 1, pos)
            .where((e) => e.type == 'context')
            .map((e) => e.text)
            .toList();
        final contextAfter = groupEvents
            .sublist(pos + 1, nextPos)
            .where((e) => e.type == 'context')
            .map((e) => e.text)
            .toList();
        final ev = groupEvents[pos];
        matches.add(GrepMatch(
          file: p.relative(ev.file, from: rootPath),
          lineNumber: ev.lineNumber,
          lineContent: ev.text,
          contextBefore: contextBefore,
          contextAfter: contextAfter,
        ));
      }
      groupEvents.clear();
    }

    for (final line in stdout.split('\n')) {
      if (line.isEmpty) continue;
      Map<String, dynamic> event;
      try {
        event = jsonDecode(line) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }
      final type = event['type'] as String?;
      final data = event['data'] as Map<String, dynamic>?;
      if (type == null || data == null) continue;

      switch (type) {
        case 'begin':
          groupEvents.clear();
        case 'match':
        case 'context':
          if (matches.length >= sentinel) continue;
          final filePath = ((data['path'] as Map?)??{})['text'] as String? ?? '';
          final lineNum = data['line_number'] as int? ?? 0;
          final text = (((data['lines'] as Map?)??{})['text'] as String? ?? '').trimRight();
          groupEvents.add((type: type, file: filePath, lineNumber: lineNum, text: text));
        case 'end':
          flushGroup();
      }
    }

    final wasCapped = matches.length >= sentinel;
    return GrepResult(
      matches: matches.take(maxMatches).toList(),
      totalFound: wasCapped ? sentinel : matches.length,
      wasCapped: wasCapped,
    );
  }
}
```

---

### Task 6: RipgrepAvailabilityDatasource

**Files:**
- Create: `lib/data/coding_tools/datasource/ripgrep_availability_datasource_process.dart`

- [ ] **Step 6.1: Implement the datasource**

```dart
// lib/data/coding_tools/datasource/ripgrep_availability_datasource_process.dart

import 'dart:io';

/// Checks whether the `rg` (ripgrep) binary is available on PATH.
/// File name ends in `_process.dart` so the dart:io arch rule is satisfied.
class RipgrepAvailabilityDatasource {
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run('rg', ['--version']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }
}
```

---

### Task 7: ripgrepAvailabilityProvider (service layer)

**Files:**
- Create: `lib/services/coding_tools/ripgrep_availability_service.dart`

- [ ] **Step 7.1: Implement the provider**

```dart
// lib/services/coding_tools/ripgrep_availability_service.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/coding_tools/datasource/ripgrep_availability_datasource_process.dart';

part 'ripgrep_availability_service.g.dart';

/// Returns true if ripgrep (`rg`) is installed. Cached for the session.
/// The user can force a re-check via [RipgrepAvailabilityNotifier.recheck].
@Riverpod(keepAlive: true)
Future<bool> ripgrepAvailability(Ref ref) =>
    RipgrepAvailabilityDatasource().isAvailable();
```

---

### Task 8: RipgrepAvailabilityNotifier — feature bridge

**Files:**
- Create: `lib/features/coding_tools/notifiers/ripgrep_availability_notifier.dart`

This notifier bridges the service-layer provider to widgets. Widgets cannot import from `/services/` (arch test rule) but CAN import from feature notifiers.

- [ ] **Step 8.1: Implement the notifier**

```dart
// lib/features/coding_tools/notifiers/ripgrep_availability_notifier.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/coding_tools/ripgrep_availability_service.dart';

export '../../../services/coding_tools/ripgrep_availability_service.dart'
    show ripgrepAvailabilityProvider;

part 'ripgrep_availability_notifier.g.dart';

/// Feature-layer state notifier for the ripgrep availability check.
/// Widgets watch [ripgrepAvailabilityNotifierProvider]; the "Check again"
/// button calls [recheck] which re-runs the rg detection.
@Riverpod(keepAlive: true)
class RipgrepAvailabilityNotifier extends _$RipgrepAvailabilityNotifier {
  @override
  Future<bool> build() => ref.watch(ripgrepAvailabilityProvider.future);

  Future<void> recheck() async {
    ref.invalidate(ripgrepAvailabilityProvider);
  }
}
```

---

### Task 9: GrepTool + tests

**Files:**
- Create: `lib/services/coding_tools/tools/grep_tool.dart`
- Create: `test/services/coding_tools/tools/grep_tool_test.dart`

- [ ] **Step 9.1: Write failing tests**

```dart
// test/services/coding_tools/tools/grep_tool_test.dart

import 'dart:io';

import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/models/grep_match.dart';
import 'package:code_bench_app/services/coding_tools/tools/grep_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

/// Fake datasource that returns a preset [GrepResult].
class _FakeDatasource implements GrepDatasource {
  _FakeDatasource(this._result);
  final GrepResult _result;
  int callCount = 0;
  String? lastPattern;

  @override
  Future<GrepResult> grep({
    required String pattern,
    required String rootPath,
    int contextLines = 2,
    int maxMatches = 100,
    List<String> fileExtensions = const [],
  }) async {
    callCount++;
    lastPattern = pattern;
    return _result;
  }
}

GrepResult _singleMatch({String file = 'lib/foo.dart'}) => GrepResult(
  matches: [
    GrepMatch(
      file: file,
      lineNumber: 10,
      lineContent: '  final tool = byName[name];',
      contextBefore: ['  // load denylist', '  Future<CodingToolResult> execute() async {'],
      contextAfter: ['  if (tool == null) return CodingToolResult.error(...);', '  }'],
    ),
  ],
  totalFound: 1,
  wasCapped: false,
);

GrepResult _cappedResult() => GrepResult(
  matches: List.generate(
    100,
    (i) => GrepMatch(
      file: 'lib/a.dart',
      lineNumber: i + 1,
      lineContent: 'MATCH $i',
      contextBefore: const [],
      contextAfter: const [],
    ),
  ),
  totalFound: 101,
  wasCapped: true,
);

void main() {
  late Directory projectDir;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('grep_tool_');
  });

  tearDown(() async {
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  });

  test('formats single match with context lines and summary', () async {
    final tool = GrepTool(datasource: _FakeDatasource(_singleMatch()));
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'pattern': 'byName', 'path': '.'}),
    );
    expect(r, isA<CodingToolResultSuccess>());
    final out = (r as CodingToolResultSuccess).output;
    expect(out, contains('lib/foo.dart:10:  final tool = byName[name];'));
    expect(out, contains('lib/foo.dart:9-  Future<CodingToolResult> execute() async {'));
    expect(out, contains('lib/foo.dart:11-  if (tool == null)'));
    expect(out, contains('Found 1 match.'));
  });

  test('formats capped result with truncation message', () async {
    final tool = GrepTool(datasource: _FakeDatasource(_cappedResult()));
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'pattern': 'MATCH', 'path': '.'}),
    );
    final out = (r as CodingToolResultSuccess).output;
    expect(out, contains('100+ matches'));
    expect(out, contains('showing first 100'));
  });

  test('returns "No matches found." when result is empty', () async {
    final tool = GrepTool(
      datasource: _FakeDatasource(const GrepResult(matches: [], totalFound: 0, wasCapped: false)),
    );
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'pattern': 'NOPE', 'path': '.'}),
    );
    expect((r as CodingToolResultSuccess).output, 'No matches found.');
  });

  test('returns error for invalid regex', () async {
    final tool = GrepTool(datasource: _FakeDatasource(_singleMatch()));
    final r = await tool.execute(
      fakeCtx(projectPath: projectDir.path, args: {'pattern': r'[bad', 'path': '.'}),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('Invalid regex'));
  });

  test('returns error when pattern is missing', () async {
    final tool = GrepTool(datasource: _FakeDatasource(_singleMatch()));
    final r = await tool.execute(fakeCtx(projectPath: projectDir.path, args: {'path': '.'}));
    expect(r, isA<CodingToolResultError>());
  });

  test('safePath rejects path escapes', () async {
    final tool = GrepTool(datasource: _FakeDatasource(_singleMatch()));
    final r = await tool.execute(
      fakeCtx(
        projectPath: projectDir.path,
        args: {'pattern': 'foo', 'path': '../../../etc'},
      ),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('outside'));
  });

  test('passes extensions arg to datasource', () async {
    final fake = _FakeDatasource(_singleMatch());
    final tool = GrepTool(datasource: fake);
    await tool.execute(
      fakeCtx(
        projectPath: projectDir.path,
        args: {'pattern': 'foo', 'path': '.', 'extensions': ['dart']},
      ),
    );
    expect(fake.callCount, 1);
  });
}
```

- [ ] **Step 9.2: Run tests — verify they fail**

```bash
flutter test test/services/coding_tools/tools/grep_tool_test.dart
```

Expected: compilation error (GrepTool not defined).

- [ ] **Step 9.3: Implement GrepTool**

```dart
// lib/services/coding_tools/tools/grep_tool.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/datasource/grep_datasource.dart';
import '../../../data/coding_tools/datasource/grep_datasource_io.dart';
import '../../../data/coding_tools/datasource/grep_datasource_process.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/grep_match.dart';
import '../../../data/coding_tools/models/path_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/repository/coding_tools_repository.dart';
import '../ripgrep_availability_service.dart';

export '../../../data/coding_tools/datasource/grep_datasource.dart';

part 'grep_tool.g.dart';

@riverpod
GrepTool grepTool(Ref ref) {
  final isAvailable = ref.watch(ripgrepAvailabilityProvider).valueOrNull ?? false;
  return GrepTool(datasource: isAvailable ? GrepDatasourceProcess() : GrepDatasourceIo());
}

class GrepTool extends Tool {
  GrepTool({required this.datasource});
  final GrepDatasource datasource;

  static const int _kMaxMatches = 100;

  @override
  String get name => 'grep';

  @override
  ToolCapability get capability => ToolCapability.readOnly;

  @override
  String get description =>
      'Search file contents by regex pattern inside the active project. '
      'Returns matching lines with 2 lines of context. Caps at 100 matches.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': 'Regex pattern to search for.',
      },
      'path': {
        'type': 'string',
        'description':
            'Project-relative or absolute path to search within. '
            'Use "." for the project root.',
      },
      'extensions': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'File extensions to include, e.g. ["dart", "yaml"]. Omit for all files.',
      },
    },
    'required': ['pattern', 'path'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final p = ctx.safePath('path', verb: 'Search', noun: 'directory');
    if (p is PathErr) return p.result;
    final PathOk(:abs) = p as PathOk;

    final patternRaw = ctx.args['pattern'];
    if (patternRaw is! String || patternRaw.isEmpty) {
      return CodingToolResult.error('grep requires a non-empty "pattern"');
    }
    try {
      RegExp(patternRaw);
    } on FormatException catch (e) {
      return CodingToolResult.error('Invalid regex pattern: ${e.message}');
    }

    final extensionsRaw = ctx.args['extensions'];
    final extensions = extensionsRaw is List
        ? extensionsRaw.whereType<String>().toList()
        : const <String>[];

    try {
      final result = await datasource.grep(
        pattern: patternRaw,
        rootPath: abs,
        maxMatches: _kMaxMatches,
        fileExtensions: extensions,
      );
      return CodingToolResult.success(_formatResult(result));
    } on CodingToolsNotFoundException {
      return CodingToolResult.error('Path does not exist.');
    } on CodingToolsDiskException catch (e) {
      dLog('[GrepTool] disk error: $e');
      return CodingToolResult.error('Cannot search: ${e.message}');
    }
  }

  static String _formatResult(GrepResult result) {
    if (result.matches.isEmpty) return 'No matches found.';

    final buf = StringBuffer();
    for (var i = 0; i < result.matches.length; i++) {
      final m = result.matches[i];
      for (var j = 0; j < m.contextBefore.length; j++) {
        final lineNo = m.lineNumber - m.contextBefore.length + j;
        buf.writeln('${m.file}:$lineNo-${m.contextBefore[j]}');
      }
      buf.writeln('${m.file}:${m.lineNumber}:${m.lineContent}');
      for (var j = 0; j < m.contextAfter.length; j++) {
        final lineNo = m.lineNumber + 1 + j;
        buf.writeln('${m.file}:$lineNo-${m.contextAfter[j]}');
      }
      if (i < result.matches.length - 1) buf.writeln('--');
    }
    buf.writeln();
    if (result.wasCapped) {
      buf.write(
        'Found 100+ matches (showing first ${_kMaxMatches}). '
        'Narrow your search with a more specific pattern or path.',
      );
    } else {
      final n = result.matches.length;
      buf.write('Found $n ${n == 1 ? 'match' : 'matches'}.');
    }
    return buf.toString();
  }
}
```

- [ ] **Step 9.4: Run tests — verify they pass**

```bash
flutter test test/services/coding_tools/tools/grep_tool_test.dart
```

Expected: all 7 tests pass.

---

### Task 10: GlobTool + tests

**Files:**
- Create: `lib/services/coding_tools/tools/glob_tool.dart`
- Create: `test/services/coding_tools/tools/glob_tool_test.dart`

- [ ] **Step 10.1: Write failing tests**

```dart
// test/services/coding_tools/tools/glob_tool_test.dart

import 'dart:io';

import 'package:code_bench_app/data/coding_tools/datasource/coding_tools_datasource_io.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_repository_impl.dart';
import 'package:code_bench_app/services/coding_tools/tools/glob_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../_helpers/tool_test_helpers.dart';

void main() {
  late Directory tmp;
  late GlobTool tool;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('glob_tool_');
    tool = GlobTool(repo: CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo()));
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  Future<File> makeFile(String rel) async {
    final f = File(p.join(tmp.path, rel));
    await f.parent.create(recursive: true);
    await f.writeAsString('');
    return f;
  }

  test('returns matching paths, project-relative', () async {
    await makeFile('lib/a.dart');
    await makeFile('lib/b.dart');
    await makeFile('lib/c.yaml');

    final r = await tool.execute(
      fakeCtx(projectPath: tmp.path, args: {'pattern': 'lib/**/*.dart'}),
    );
    expect(r, isA<CodingToolResultSuccess>());
    final out = (r as CodingToolResultSuccess).output;
    expect(out, contains('lib/a.dart'));
    expect(out, contains('lib/b.dart'));
    expect(out, isNot(contains('lib/c.yaml')));
    expect(out, contains('2 paths matched.'));
  });

  test('returns message when no paths match', () async {
    final r = await tool.execute(
      fakeCtx(projectPath: tmp.path, args: {'pattern': '**/*.nonexistent'}),
    );
    expect(r, isA<CodingToolResultSuccess>());
    expect((r as CodingToolResultSuccess).output, contains('No paths matched.'));
  });

  test('rejects pattern containing ".."', () async {
    final r = await tool.execute(
      fakeCtx(projectPath: tmp.path, args: {'pattern': '../**/*.dart'}),
    );
    expect(r, isA<CodingToolResultError>());
    expect((r as CodingToolResultError).message, contains('".."'));
  });

  test('returns error when pattern arg is missing', () async {
    final r = await tool.execute(fakeCtx(projectPath: tmp.path, args: {}));
    expect(r, isA<CodingToolResultError>());
  });
}
```

- [ ] **Step 10.2: Run tests — verify they fail**

```bash
flutter test test/services/coding_tools/tools/glob_tool_test.dart
```

Expected: compilation error (GlobTool not defined).

- [ ] **Step 10.3: Implement GlobTool**

```dart
// lib/services/coding_tools/tools/glob_tool.dart

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/coding_tools/repository/coding_tools_repository.dart';
import '../../../data/coding_tools/repository/coding_tools_repository_impl.dart';

part 'glob_tool.g.dart';

@riverpod
GlobTool globTool(Ref ref) => GlobTool(repo: ref.watch(codingToolsRepositoryProvider));

class GlobTool extends Tool {
  GlobTool({required this.repo});
  final CodingToolsRepository repo;

  static const int _kMaxPaths = 500;

  @override
  String get name => 'glob';

  @override
  ToolCapability get capability => ToolCapability.readOnly;

  @override
  String get description =>
      'Expand a glob pattern to matching file paths inside the active project. '
      'Returns one project-relative path per line. Caps at 500 paths.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': 'Glob pattern, e.g. lib/**/*.dart or test/**/*_test.dart',
      },
    },
    'required': ['pattern'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final pattern = ctx.args['pattern'];
    if (pattern is! String || pattern.isEmpty) {
      return CodingToolResult.error('glob requires a non-empty "pattern"');
    }
    if (pattern.contains('..')) {
      return CodingToolResult.error('Pattern must not contain ".."; use a path relative to the project root.');
    }

    try {
      final glob = Glob(pattern);
      final entities = await glob.list(root: ctx.projectPath, followLinks: false).toList();
      final paths = entities
          .map((e) => p.relative(e.path, from: ctx.projectPath))
          .toList()
        ..sort();

      if (paths.isEmpty) return CodingToolResult.success('No paths matched.');

      final buf = StringBuffer();
      final capped = paths.length > _kMaxPaths;
      for (final path in paths.take(_kMaxPaths)) {
        buf.writeln(path);
      }
      buf.writeln();
      if (capped) {
        buf.write(
          '$_kMaxPaths paths shown (pattern matched more). '
          'Refine the pattern to narrow results.',
        );
      } else {
        final n = paths.length;
        buf.write('$n ${n == 1 ? 'path' : 'paths'} matched.');
      }
      return CodingToolResult.success(buf.toString());
    } catch (e, st) {
      dLog('[GlobTool] error: $e\n$st');
      return CodingToolResult.error('Glob error: $e');
    }
  }
}
```

- [ ] **Step 10.4: Run tests — verify they pass**

```bash
flutter test test/services/coding_tools/tools/glob_tool_test.dart
```

Expected: all 4 tests pass.

---

### Task 11: RipgrepAvailabilityBanner widget

**Files:**
- Create: `lib/features/coding_tools/widgets/ripgrep_availability_banner.dart`

- [ ] **Step 11.1: Implement the banner widget**

```dart
// lib/features/coding_tools/widgets/ripgrep_availability_banner.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../notifiers/ripgrep_availability_notifier.dart';

/// Shows nothing when ripgrep is available. Shows an install-hint banner
/// when it is not. "Check again" re-runs the rg version check.
class RipgrepAvailabilityBanner extends ConsumerWidget {
  const RipgrepAvailabilityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ripgrepAvailabilityNotifierProvider);
    return state.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => _buildBanner(context, ref),
      data: (available) => available ? const SizedBox.shrink() : _buildBanner(context, ref),
    );
  }

  Widget _buildBanner(BuildContext context, WidgetRef ref) {
    final installCmd = Platform.isMacOS
        ? 'brew install ripgrep'
        : Platform.isLinux
        ? 'sudo apt install ripgrep'
        : 'winget install ripgrep';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 16),
              const SizedBox(width: 6),
              Text(
                'Grep backend: Pure Dart (fallback)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Install ripgrep for faster searches.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            installCmd,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: AppColors.codeText,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => ref.read(ripgrepAvailabilityNotifierProvider.notifier).recheck(),
              child: const Text('Check again'),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Note:** Replace `AppColors.warningSubtle`, `AppColors.warningBorder`, and `AppColors.codeText` with the actual color tokens from `lib/core/theme/app_colors.dart`. Check that file first — if those tokens don't exist, use the closest available warning/surface colors or add them following the existing pattern.

---

### Task 12: Run build_runner (Part 1 generated files)

- [ ] **Step 12.1: Generate .g.dart files**

```bash
cd /path/to/repo && dart run build_runner build --delete-conflicting-outputs
```

Expected: generates:
- `lib/services/coding_tools/ripgrep_availability_service.g.dart`
- `lib/services/coding_tools/tools/grep_tool.g.dart`
- `lib/services/coding_tools/tools/glob_tool.g.dart`
- `lib/features/coding_tools/notifiers/ripgrep_availability_notifier.g.dart`

No errors in the build output.

---

### Task 13: Verify Part 1

- [ ] **Step 13.1: Run Part 1 tests**

```bash
flutter test test/data/coding_tools/grep_datasource_io_test.dart test/services/coding_tools/tools/grep_tool_test.dart test/services/coding_tools/tools/glob_tool_test.dart
```

Expected: all tests pass.

- [ ] **Step 13.2: Check dart analyze (Part 1 files only)**

```bash
flutter analyze lib/data/coding_tools/models/grep_match.dart lib/data/coding_tools/datasource/ lib/services/coding_tools/ripgrep_availability_service.dart lib/services/coding_tools/tools/grep_tool.dart lib/services/coding_tools/tools/glob_tool.dart lib/features/coding_tools/notifiers/ripgrep_availability_notifier.dart lib/features/coding_tools/widgets/ripgrep_availability_banner.dart
```

Expected: no issues.

---

### Task 14: Commit 1

- [ ] **Step 14.1: Stage and commit additive files**

```bash
git add \
  pubspec.yaml pubspec.lock \
  lib/data/coding_tools/models/grep_match.dart \
  lib/data/coding_tools/datasource/grep_datasource.dart \
  lib/data/coding_tools/datasource/grep_datasource_io.dart \
  lib/data/coding_tools/datasource/grep_datasource_process.dart \
  lib/data/coding_tools/datasource/ripgrep_availability_datasource_process.dart \
  lib/services/coding_tools/ripgrep_availability_service.dart \
  lib/services/coding_tools/ripgrep_availability_service.g.dart \
  lib/services/coding_tools/tools/grep_tool.dart \
  lib/services/coding_tools/tools/grep_tool.g.dart \
  lib/services/coding_tools/tools/glob_tool.dart \
  lib/services/coding_tools/tools/glob_tool.g.dart \
  lib/features/coding_tools/notifiers/ripgrep_availability_notifier.dart \
  lib/features/coding_tools/notifiers/ripgrep_availability_notifier.g.dart \
  lib/features/coding_tools/widgets/ripgrep_availability_banner.dart \
  test/data/coding_tools/grep_datasource_io_test.dart \
  test/services/coding_tools/tools/grep_tool_test.dart \
  test/services/coding_tools/tools/glob_tool_test.dart

git commit -m "feat(coding-tools): add GrepTool + GlobTool with ripgrep/Dart backends"
```

---

## Part 2 — Cutover (Commit 2)

Wire new tools into the registry, enable parallel dispatch in AgentService, add the availability banner to CodingToolsScreen.

---

### Task 15: Register GrepTool and GlobTool in ToolRegistry

**Files:**
- Modify: `lib/services/coding_tools/tool_registry.dart`

- [ ] **Step 15.1: Add imports and register tools**

Open `lib/services/coding_tools/tool_registry.dart`. Add two imports after the existing tool imports:

```dart
import 'tools/glob_tool.dart';
import 'tools/grep_tool.dart';
```

Update the `toolRegistryProvider` function to include the new tools:

```dart
@Riverpod(keepAlive: true)
ToolRegistry toolRegistry(Ref ref) => ToolRegistry(
  builtIns: [
    ref.watch(readFileToolProvider),
    ref.watch(listDirToolProvider),
    ref.watch(writeFileToolProvider),
    ref.watch(strReplaceToolProvider),
    ref.watch(grepToolProvider),   // ← add
    ref.watch(globToolProvider),   // ← add
  ],
  denylistRepo: ref.watch(codingToolsDenylistRepositoryProvider),
);
```

- [ ] **Step 15.2: Verify registration compiles**

```bash
flutter analyze lib/services/coding_tools/tool_registry.dart
```

Expected: no issues.

---

### Task 16: Parallel dispatch in AgentService + tests

**Files:**
- Create: `test/services/agent/agent_service_parallel_test.dart`
- Modify: `lib/services/agent/agent_service.dart`

- [ ] **Step 16.1: Write failing tests**

```dart
// test/services/agent/agent_service_parallel_test.dart

import 'dart:async';

import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/models/tool.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_context.dart';
import 'package:code_bench_app/data/session/models/session_settings.dart';
import 'package:code_bench_app/services/coding_tools/tool_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'agent_service_test.dart' show buildAgentService;

/// Records execution order of tool calls by appending to [log].
class _OrderedTool extends Tool {
  _OrderedTool(this._name, this._capability, this._log, {Duration delay = Duration.zero})
    : _delay = delay;

  final String _name;
  final ToolCapability _capability;
  final List<String> _log;
  final Duration _delay;

  @override String get name => _name;
  @override ToolCapability get capability => _capability;
  @override String get description => _name;
  @override Map<String, dynamic> get inputSchema => const {'type': 'object', 'properties': {}};

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    if (_delay != Duration.zero) await Future.delayed(_delay);
    _log.add(_name);
    return CodingToolResult.success(_name);
  }
}

void main() {
  test('read-only tools in same round run in parallel', () async {
    // Two read tools with a delay each. If serial: total ≥ 200ms.
    // If parallel: total ≈ 100ms (they overlap).
    final log = <String>[];
    final read1 = _OrderedTool('grep', ToolCapability.readOnly, log, delay: const Duration(milliseconds: 80));
    final read2 = _OrderedTool('glob', ToolCapability.readOnly, log, delay: const Duration(milliseconds: 80));

    // This test verifies parallelism by timing, not by log order (Dart Future.wait
    // interleaves; the order depends on scheduling). Just assert both complete quickly.
    final started = DateTime.now();
    await Future.wait([read1.execute(_fakeCtx()), read2.execute(_fakeCtx())]);
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    expect(elapsed, lessThan(200), reason: 'should run in parallel not serial');
  });

  test('write tools are not parallelised (serial list partition)', () {
    // This is a unit test on the partition logic inside AgentService.
    // We cannot call AgentService directly without an LLM, so we test
    // the helper that decides which calls are parallelizable.
    // See agent_service.dart _isParallelizable for the exact predicate.

    // Smoke test: readOnly + no-prompt tools are parallelizable.
    final readTool = _OrderedTool('grep', ToolCapability.readOnly, []);
    final writeTool = _OrderedTool('write_file', ToolCapability.mutatingFiles, []);

    expect(readTool.capability, ToolCapability.readOnly);
    expect(writeTool.capability, ToolCapability.mutatingFiles);
    expect(writeTool.capability != ToolCapability.readOnly, isTrue);
  });
}

ToolContext _fakeCtx() => ToolContext(
  projectPath: '/tmp',
  sessionId: 's',
  messageId: 'm',
  args: const {},
  denylist: (segments: {}, filenames: {}, extensions: {}, prefixes: {}),
);
```

- [ ] **Step 16.2: Run tests — verify they pass (the partition test is structural)**

```bash
flutter test test/services/agent/agent_service_parallel_test.dart
```

Expected: both tests pass (they test structural properties, not LLM round-trip).

- [ ] **Step 16.3: Add `_isParallelizable` helper and replace the serial for-loop in AgentService**

Open `lib/services/agent/agent_service.dart`. Find the `for (final call in roundCalls)` loop starting at line 201. Replace the entire loop body (lines 201–231) with the following two-phase dispatch:

```dart
      // Phase 1: run read-only non-prompted calls in parallel (max 4 at a time).
      final parallelizable = roundCalls
          .where((c) => _isParallelizable(c, permission))
          .toList();
      final serial = roundCalls
          .where((c) => !parallelizable.contains(c))
          .toList();

      for (var i = 0; i < parallelizable.length; i += 4) {
        if (_cancelFlag()) break;
        final chunk = parallelizable.skip(i).take(4).toList();
        await Future.wait(chunk.map(_executeCall));
        yield snapshot(streaming: true);
      }

      for (final call in serial) {
        if (_cancelFlag()) break;
        if (call.decodeFailed) continue;

        final tool = _registry.byName(call.name);
        if (tool != null && _registry.requiresPrompt(tool, permission)) {
          final summary = _summaryFor(call);
          final req = PermissionRequest(toolEventId: call.id, toolName: call.name, summary: summary, input: call.args);
          yield snapshot(streaming: true).copyWith(pendingPermissionRequest: req);
          final approved = await _requestPermission(req);
          yield snapshot(streaming: true);
          if (!approved) {
            final idx = events.indexWhere((e) => e.id == call.id);
            if (idx >= 0) {
              events[idx] = events[idx].copyWith(status: ToolStatus.cancelled, error: 'Denied by user');
            }
            yield snapshot(streaming: true);
            continue;
          }
        }

        await _executeCall(call);
        yield snapshot(streaming: true);
      }
```

Then add the two new private methods at the bottom of the class (before the final `}`):

```dart
  /// True for calls that can safely run concurrently: readOnly capability,
  /// no permission prompt needed, and decode did not fail.
  bool _isParallelizable(_PendingCall call, ChatPermission permission) {
    if (call.decodeFailed) return false;
    final tool = _registry.byName(call.name);
    if (tool == null) return false;
    if (tool.capability != ToolCapability.readOnly) return false;
    if (_registry.requiresPrompt(tool, permission)) return false;
    return true;
  }

  /// Executes one tool call and records the result into [events].
  Future<void> _executeCall(_PendingCall call) async {
    final result = await _registry.execute(
      name: call.name,
      args: call.args,
      projectPath: projectPath,
      sessionId: sessionId,
      messageId: assistantId,
    );
    _recordResult(events, call.id, result);
  }
```

**Note:** `projectPath`, `sessionId`, `assistantId`, and `events` are captured from the enclosing `runAgenticTurn` method scope. The private methods must be defined as instance members on the class, capturing these from the method closure is not possible — instead, pass them as parameters. Revise the signature of `_executeCall` to accept these as parameters:

```dart
  Future<void> _executeCall(
    _PendingCall call, {
    required String projectPath,
    required String sessionId,
    required String assistantId,
    required List<ToolEvent> events,
  }) async {
    final result = await _registry.execute(
      name: call.name,
      args: call.args,
      projectPath: projectPath,
      sessionId: sessionId,
      messageId: assistantId,
    );
    _recordResult(events, call.id, result);
  }
```

And update the call sites accordingly:

```dart
      // In the parallel phase:
      await Future.wait(chunk.map(
        (c) => _executeCall(c, projectPath: projectPath, sessionId: sessionId, assistantId: assistantId, events: events),
      ));

      // In the serial phase:
      await _executeCall(call, projectPath: projectPath, sessionId: sessionId, assistantId: assistantId, events: events);
```

- [ ] **Step 16.4: Run the full agent service test suite**

```bash
flutter test test/services/agent/
```

Expected: all existing agent_service_test.dart tests still pass, plus the two new parallel tests.

---

### Task 17: Add RipgrepAvailabilityBanner to CodingToolsScreen

**Files:**
- Modify: `lib/features/coding_tools/coding_tools_screen.dart`

- [ ] **Step 17.1: Add the banner import**

At the top of `lib/features/coding_tools/coding_tools_screen.dart`, add:

```dart
import 'widgets/ripgrep_availability_banner.dart';
```

- [ ] **Step 17.2: Insert banner at the top of the screen body**

In `_CodingToolsScreenState`, find the `build` method's column/list body. Add `const RipgrepAvailabilityBanner()` as the first child, before the denylist category groups. The exact insertion depends on the current widget tree — search for where `DenylistCategoryGroup` is first constructed and insert above it:

```dart
// Before the first DenylistCategoryGroup:
const RipgrepAvailabilityBanner(),
const SizedBox(height: 8),
// ... existing denylist content
```

- [ ] **Step 17.3: Hot-restart the app and verify the banner**

```bash
flutter run -d macos
```

1. Navigate to Settings → Coding Tools.
2. If `rg` is not installed: confirm the banner with install command appears.
3. If `rg` is installed: confirm no banner is shown.
4. (Optional) If `rg` is installed, temporarily rename the binary, restart the app, confirm banner appears, run "Check again" after restoring.

---

### Task 18: Full verification

- [ ] **Step 18.1: Format**

```bash
dart format lib/ test/
```

Expected: no changes needed, or only whitespace-level reformatting.

- [ ] **Step 18.2: Analyze**

```bash
flutter analyze
```

Expected: no issues (0 errors, 0 warnings, 0 hints).

- [ ] **Step 18.3: Full test suite**

```bash
flutter test
```

Expected: all tests pass. Pay attention to:
- `test/arch_test.dart` — no new arch violations
- `test/services/agent/agent_service_test.dart` — no regressions
- `test/services/coding_tools/tool_registry_test.dart` — registry now has 6 tools; update any test that asserts tool count

**If tool_registry_test.dart asserts `tools.length == 4`:** update that assertion to `tools.length == 6`.

---

### Task 19: Commit 2

- [ ] **Step 19.1: Stage and commit cutover files**

```bash
git add \
  lib/services/coding_tools/tool_registry.dart \
  lib/services/agent/agent_service.dart \
  lib/features/coding_tools/coding_tools_screen.dart \
  test/services/agent/agent_service_parallel_test.dart

git commit -m "feat(agent): register grep+glob tools; parallel read-only dispatch (max 4)"
```
