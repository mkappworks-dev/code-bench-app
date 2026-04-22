# MCP Client (Phase 5) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add MCP (Model Context Protocol) client support so the agent can call tools from third-party MCP servers via stdio and HTTP/SSE transports, with a Settings UI to manage server configurations.

**Architecture:** `McpService` is injected into `AgentService` and calls `startSession()` at the start of each agentic turn. It loads enabled `McpServerConfig` entries, connects to each server via the appropriate transport datasource, performs the initialize/tools-list handshake, and registers one `McpTool` per discovered tool into the `ToolRegistry`. A teardown callback is called in `AgentService`'s `finally` block to close all connections. From the model's perspective, MCP tools are indistinguishable from built-ins.

**Tech Stack:** Drift (SQLite config storage), `dart:io Process` (stdio transport), Dio (HTTP/SSE transport), freezed (models), riverpod_annotation (providers), flutter_riverpod (test utilities).

---

## Worktree Setup

```bash
git worktree add .worktrees/feat/2026-04-22-mcp-client -b feat/2026-04-22-mcp-client
cd .worktrees/feat/2026-04-22-mcp-client
```

---

## File Map

**New files:**
```
lib/data/mcp/
  models/
    mcp_server_config.dart
    mcp_server_config.freezed.dart       # generated
    mcp_server_config.g.dart             # generated
    mcp_tool_info.dart
    mcp_tool_info.freezed.dart           # generated
    mcp_tool_info.g.dart                 # generated
  datasource/
    mcp_config_datasource_drift.dart
    mcp_config_datasource_drift.g.dart   # generated
    mcp_transport_datasource.dart        # abstract interface
    mcp_stdio_datasource_process.dart
    mcp_http_sse_datasource_dio.dart
  repository/
    mcp_repository.dart
    mcp_repository_impl.dart
    mcp_repository_impl.g.dart           # generated

lib/services/mcp/
  mcp_client_session.dart
  mcp_service.dart
  mcp_service.g.dart                     # generated
  mcp_tool.dart

lib/features/settings/
  mcp_servers_screen.dart
  widgets/
    mcp_server_card.dart
    mcp_server_editor_dialog.dart
  notifiers/
    mcp_servers_notifier.dart
    mcp_servers_notifier.g.dart          # generated
    mcp_servers_actions.dart
    mcp_servers_actions.g.dart           # generated
    mcp_servers_failure.dart
    mcp_servers_failure.freezed.dart     # generated
    mcp_server_status_notifier.dart
    mcp_server_status_notifier.freezed.dart  # generated
    mcp_server_status_notifier.g.dart    # generated
```

**Modified files:**
```
lib/data/_core/app_database.dart
lib/features/chat/utils/permission_request_preview.dart
lib/features/chat/widgets/tool_call_row.dart
lib/services/agent/agent_service.dart
lib/features/settings/settings_screen.dart
```

**Test files:**
```
test/data/mcp/models/mcp_server_config_test.dart
test/data/mcp/datasource/mcp_config_datasource_drift_test.dart
test/data/mcp/repository/mcp_repository_impl_test.dart
test/services/mcp/mcp_client_session_test.dart
test/services/mcp/mcp_tool_test.dart
test/services/mcp/mcp_service_test.dart
test/features/settings/notifiers/mcp_servers_notifier_test.dart
test/features/settings/notifiers/mcp_servers_actions_test.dart
```

---

## Task 1: McpServerConfig and McpToolInfo models

**Files:**
- Create: `lib/data/mcp/models/mcp_server_config.dart`
- Create: `lib/data/mcp/models/mcp_tool_info.dart`
- Test: `test/data/mcp/models/mcp_server_config_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/mcp/models/mcp_server_config_test.dart
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpServerConfig', () {
    test('serializes and deserializes round-trip', () {
      const config = McpServerConfig(
        id: 'abc',
        name: 'my-server',
        transport: McpTransport.stdio,
        command: 'npx -y @my/server',
        args: ['--verbose'],
        env: {'API_KEY': 'secret'},
        enabled: true,
      );
      final json = config.toJson();
      final restored = McpServerConfig.fromJson(json);
      expect(restored.id, 'abc');
      expect(restored.transport, McpTransport.stdio);
      expect(restored.args, ['--verbose']);
      expect(restored.env, {'API_KEY': 'secret'});
    });

    test('defaults enabled to true and collections to empty', () {
      const config = McpServerConfig(
        id: 'x',
        name: 'n',
        transport: McpTransport.httpSse,
        url: 'http://localhost:3000',
      );
      expect(config.enabled, true);
      expect(config.args, <String>[]);
      expect(config.env, <String, String>{});
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/data/mcp/models/mcp_server_config_test.dart
```
Expected: FAIL — file not found.

- [ ] **Step 3: Create McpServerConfig**

```dart
// lib/data/mcp/models/mcp_server_config.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_server_config.freezed.dart';
part 'mcp_server_config.g.dart';

enum McpTransport { stdio, httpSse }

@freezed
abstract class McpServerConfig with _$McpServerConfig {
  const factory McpServerConfig({
    required String id,
    required String name,
    required McpTransport transport,
    String? command,
    @Default([]) List<String> args,
    @Default({}) Map<String, String> env,
    String? url,
    @Default(true) bool enabled,
  }) = _McpServerConfig;

  factory McpServerConfig.fromJson(Map<String, dynamic> json) =>
      _$McpServerConfigFromJson(json);
}
```

- [ ] **Step 4: Create McpToolInfo**

```dart
// lib/data/mcp/models/mcp_tool_info.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_tool_info.freezed.dart';
part 'mcp_tool_info.g.dart';

@freezed
abstract class McpToolInfo with _$McpToolInfo {
  const factory McpToolInfo({
    required String name,
    required String description,
    required Map<String, dynamic> inputSchema,
  }) = _McpToolInfo;

  factory McpToolInfo.fromJson(Map<String, dynamic> json) =>
      _$McpToolInfoFromJson(json);
}
```

- [ ] **Step 5: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: generates 4 files under `lib/data/mcp/models/`.

- [ ] **Step 6: Run test to verify it passes**

```bash
flutter test test/data/mcp/models/mcp_server_config_test.dart
```
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/data/mcp/models/ test/data/mcp/models/
git commit -m "feat: add McpServerConfig and McpToolInfo freezed models"
```

---

## Task 2: McpServers Drift table + McpDao

**Files:**
- Modify: `lib/data/_core/app_database.dart`

All table and DAO definitions live inline in `app_database.dart`, following the existing pattern for `ChatSessions`/`SessionDao` and `WorkspaceProjects`/`ProjectDao`.

- [ ] **Step 1: Add McpServers table after WorkspaceProjects**

In `app_database.dart`, insert after the `WorkspaceProjects` class (before `// ── DAOs`):

```dart
@DataClassName('McpServerRow')
class McpServers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get transport => text()();
  TextColumn get command => text().nullable()();
  TextColumn get args => text().withDefault(const Constant('[]'))();
  TextColumn get env => text().withDefault(const Constant('{}'))();
  TextColumn get url => text().nullable()();
  IntColumn get enabled => integer().withDefault(const Constant(1))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 2: Add McpDao after ProjectDao**

In `app_database.dart`, insert after the `ProjectDao` closing brace (before `// ── Database`):

```dart
@DriftAccessor(tables: [McpServers])
class McpDao extends DatabaseAccessor<AppDatabase> with _$McpDaoMixin {
  McpDao(super.db);

  Stream<List<McpServerRow>> watchAll() =>
      (select(mcpServers)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Future<List<McpServerRow>> getAll() =>
      (select(mcpServers)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Future<List<McpServerRow>> getEnabled() =>
      (select(mcpServers)
            ..where((t) => t.enabled.equals(1))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<void> upsert(McpServersCompanion companion) =>
      into(mcpServers).insertOnConflictUpdate(companion);

  Future<void> deleteById(String id) =>
      (deleteFrom(mcpServers)..where((t) => t.id.equals(id))).go();
}
```

- [ ] **Step 3: Update @DriftDatabase annotation, add mcpDao getter, bump schema version**

Replace the existing `AppDatabase` class with:

```dart
@DriftDatabase(
  tables: [ChatSessions, ChatMessages, WorkspaceProjects, McpServers],
  daos: [SessionDao, ProjectDao, McpDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  late final mcpDao = McpDao(this);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 6) {
        await m.addColumn(chatSessions, chatSessions.systemPrompt);
        await m.addColumn(chatSessions, chatSessions.mode);
        await m.addColumn(chatSessions, chatSessions.effort);
        await m.addColumn(chatSessions, chatSessions.permission);
      }
      if (from < 7) {
        await m.addColumn(chatMessages, chatMessages.toolEventsJson);
      }
      if (from < 8) {
        await m.createTable(mcpServers);
      }
    },
  );
}
```

- [ ] **Step 4: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: `app_database.g.dart` regenerated with `McpServerRow`, `McpServersCompanion`, `_$McpDaoMixin`.

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/data/_core/app_database.dart
```
Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/data/_core/app_database.dart lib/data/_core/app_database.g.dart
git commit -m "feat: add McpServers Drift table, McpDao, and schema migration to v8"
```

---

## Task 3: McpConfigDatasourceDrift

**Files:**
- Create: `lib/data/mcp/datasource/mcp_config_datasource_drift.dart`
- Test: `test/data/mcp/datasource/mcp_config_datasource_drift_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/mcp/datasource/mcp_config_datasource_drift_test.dart
import 'package:code_bench_app/data/_core/app_database.dart';
import 'package:code_bench_app/data/mcp/datasource/mcp_config_datasource_drift.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late McpConfigDatasourceDrift ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = McpConfigDatasourceDrift(db);
  });
  tearDown(() => db.close());

  group('McpConfigDatasourceDrift', () {
    test('upsert then getAll returns the row', () async {
      await ds.upsert(McpServersCompanion.insert(
        id: 'srv-1',
        name: 'github',
        transport: 'stdio',
        enabled: const Value(1),
        sortOrder: const Value(0),
      ));
      final rows = await ds.getAll();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'srv-1');
      expect(rows.first.name, 'github');
    });

    test('getEnabled filters disabled rows', () async {
      await ds.upsert(McpServersCompanion.insert(
        id: 'a', name: 'enabled', transport: 'stdio',
        enabled: const Value(1), sortOrder: const Value(0),
      ));
      await ds.upsert(McpServersCompanion.insert(
        id: 'b', name: 'disabled', transport: 'stdio',
        enabled: const Value(0), sortOrder: const Value(1),
      ));
      final enabled = await ds.getEnabled();
      expect(enabled, hasLength(1));
      expect(enabled.first.id, 'a');
    });

    test('upsert updates existing row by id', () async {
      await ds.upsert(McpServersCompanion.insert(
        id: 'srv-1', name: 'old', transport: 'stdio',
        enabled: const Value(1), sortOrder: const Value(0),
      ));
      await ds.upsert(McpServersCompanion.insert(
        id: 'srv-1', name: 'new', transport: 'stdio',
        enabled: const Value(1), sortOrder: const Value(0),
      ));
      final rows = await ds.getAll();
      expect(rows, hasLength(1));
      expect(rows.first.name, 'new');
    });

    test('deleteById removes the row', () async {
      await ds.upsert(McpServersCompanion.insert(
        id: 'del-me', name: 'temp', transport: 'stdio',
        enabled: const Value(1), sortOrder: const Value(0),
      ));
      await ds.deleteById('del-me');
      expect(await ds.getAll(), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/data/mcp/datasource/mcp_config_datasource_drift_test.dart
```
Expected: FAIL — file not found.

- [ ] **Step 3: Write the datasource**

```dart
// lib/data/mcp/datasource/mcp_config_datasource_drift.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../_core/app_database.dart';

export '../../_core/app_database.dart' show McpServerRow, McpServersCompanion;

part 'mcp_config_datasource_drift.g.dart';

@Riverpod(keepAlive: true)
McpConfigDatasourceDrift mcpConfigDatasource(Ref ref) =>
    McpConfigDatasourceDrift(ref.watch(appDatabaseProvider));

class McpConfigDatasourceDrift {
  McpConfigDatasourceDrift(this._db);
  final AppDatabase _db;

  Stream<List<McpServerRow>> watchAll() => _db.mcpDao.watchAll();
  Future<List<McpServerRow>> getAll() => _db.mcpDao.getAll();
  Future<List<McpServerRow>> getEnabled() => _db.mcpDao.getEnabled();
  Future<void> upsert(McpServersCompanion companion) => _db.mcpDao.upsert(companion);
  Future<void> deleteById(String id) => _db.mcpDao.deleteById(id);
}
```

- [ ] **Step 4: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test test/data/mcp/datasource/mcp_config_datasource_drift_test.dart
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/data/mcp/datasource/mcp_config_datasource_drift.dart \
        lib/data/mcp/datasource/mcp_config_datasource_drift.g.dart \
        test/data/mcp/datasource/
git commit -m "feat: add McpConfigDatasourceDrift with CRUD operations"
```

---

## Task 4: McpRepository interface + impl

**Files:**
- Create: `lib/data/mcp/repository/mcp_repository.dart`
- Create: `lib/data/mcp/repository/mcp_repository_impl.dart`
- Test: `test/data/mcp/repository/mcp_repository_impl_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/mcp/repository/mcp_repository_impl_test.dart
import 'package:code_bench_app/data/_core/app_database.dart';
import 'package:code_bench_app/data/mcp/datasource/mcp_config_datasource_drift.dart';
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository_impl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late McpRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = McpRepositoryImpl(datasource: McpConfigDatasourceDrift(db));
  });
  tearDown(() => db.close());

  group('McpRepositoryImpl', () {
    test('upsert then getEnabled returns McpServerConfig', () async {
      const config = McpServerConfig(
        id: 'srv-1',
        name: 'github',
        transport: McpTransport.stdio,
        command: 'npx github-mcp',
        args: ['--port', '3000'],
        env: {'TOKEN': 'abc'},
        enabled: true,
      );
      await repo.upsert(config);
      final enabled = await repo.getEnabled();
      expect(enabled, hasLength(1));
      expect(enabled.first.id, 'srv-1');
      expect(enabled.first.transport, McpTransport.stdio);
      expect(enabled.first.command, 'npx github-mcp');
      expect(enabled.first.args, ['--port', '3000']);
      expect(enabled.first.env, {'TOKEN': 'abc'});
    });

    test('disabled config excluded from getEnabled', () async {
      const config = McpServerConfig(
        id: 'off',
        name: 'server',
        transport: McpTransport.httpSse,
        url: 'http://localhost:3000',
        enabled: false,
      );
      await repo.upsert(config);
      expect(await repo.getEnabled(), isEmpty);
      expect(await repo.getAll(), hasLength(1));
    });

    test('httpSse transport round-trips', () async {
      const config = McpServerConfig(
        id: 'sse-1',
        name: 'remote',
        transport: McpTransport.httpSse,
        url: 'https://api.example.com/mcp',
      );
      await repo.upsert(config);
      final all = await repo.getAll();
      expect(all.first.transport, McpTransport.httpSse);
      expect(all.first.url, 'https://api.example.com/mcp');
    });

    test('delete removes the config', () async {
      const config = McpServerConfig(
        id: 'del-me',
        name: 'temp',
        transport: McpTransport.stdio,
        command: 'cmd',
      );
      await repo.upsert(config);
      await repo.delete('del-me');
      expect(await repo.getAll(), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/data/mcp/repository/mcp_repository_impl_test.dart
```
Expected: FAIL — files not found.

- [ ] **Step 3: Write the repository interface**

```dart
// lib/data/mcp/repository/mcp_repository.dart
import '../models/mcp_server_config.dart';

abstract interface class McpRepository {
  Stream<List<McpServerConfig>> watchAll();
  Future<List<McpServerConfig>> getAll();
  Future<List<McpServerConfig>> getEnabled();
  Future<void> upsert(McpServerConfig config);
  Future<void> delete(String id);
}
```

- [ ] **Step 4: Write the repository impl**

```dart
// lib/data/mcp/repository/mcp_repository_impl.dart
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../datasource/mcp_config_datasource_drift.dart';
import '../models/mcp_server_config.dart';
import 'mcp_repository.dart';

part 'mcp_repository_impl.g.dart';

@Riverpod(keepAlive: true)
McpRepository mcpRepository(Ref ref) =>
    McpRepositoryImpl(datasource: ref.watch(mcpConfigDatasourceProvider));

class McpRepositoryImpl implements McpRepository {
  McpRepositoryImpl({required McpConfigDatasourceDrift datasource})
      : _ds = datasource;
  final McpConfigDatasourceDrift _ds;

  @override
  Stream<List<McpServerConfig>> watchAll() =>
      _ds.watchAll().map((rows) => rows.map(_toDomain).toList());

  @override
  Future<List<McpServerConfig>> getAll() async =>
      (await _ds.getAll()).map(_toDomain).toList();

  @override
  Future<List<McpServerConfig>> getEnabled() async =>
      (await _ds.getEnabled()).map(_toDomain).toList();

  @override
  Future<void> upsert(McpServerConfig config) => _ds.upsert(_toCompanion(config));

  @override
  Future<void> delete(String id) => _ds.deleteById(id);

  McpServerConfig _toDomain(McpServerRow row) {
    List<String> args = const [];
    Map<String, String> env = const {};
    try {
      args = (jsonDecode(row.args) as List<dynamic>).cast<String>();
    } on FormatException catch (e) {
      dLog('[McpRepository] args parse error for ${row.id}: $e');
    }
    try {
      env = (jsonDecode(row.env) as Map<String, dynamic>).cast<String, String>();
    } on FormatException catch (e) {
      dLog('[McpRepository] env parse error for ${row.id}: $e');
    }
    return McpServerConfig(
      id: row.id,
      name: row.name,
      transport: McpTransport.values.firstWhere(
        (t) => t.name == row.transport,
        orElse: () => McpTransport.stdio,
      ),
      command: row.command,
      args: args,
      env: env,
      url: row.url,
      enabled: row.enabled == 1,
    );
  }

  McpServersCompanion _toCompanion(McpServerConfig c) => McpServersCompanion(
    id: Value(c.id),
    name: Value(c.name),
    transport: Value(c.transport.name),
    command: Value(c.command),
    args: Value(jsonEncode(c.args)),
    env: Value(jsonEncode(c.env)),
    url: Value(c.url),
    enabled: Value(c.enabled ? 1 : 0),
  );
}
```

- [ ] **Step 5: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Run test to verify it passes**

```bash
flutter test test/data/mcp/repository/mcp_repository_impl_test.dart
```
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/data/mcp/repository/ test/data/mcp/repository/
git commit -m "feat: add McpRepository interface and impl with JSON serialization for args/env"
```

---

## Task 5: McpTransportDatasource interface + McpStdioDatasource

**Files:**
- Create: `lib/data/mcp/datasource/mcp_transport_datasource.dart`
- Create: `lib/data/mcp/datasource/mcp_stdio_datasource_process.dart`

The stdio datasource spawns a real OS process. Unit tests would require a running MCP server; instead, `McpClientSession` (Task 7) is tested via a fake transport that implements this interface.

- [ ] **Step 1: Write the transport interface**

```dart
// lib/data/mcp/datasource/mcp_transport_datasource.dart
import '../models/mcp_server_config.dart';

abstract class McpTransportDatasource {
  /// Opens the transport connection (spawns process or opens SSE stream).
  /// No MCP-level handshaking — that happens in McpClientSession.
  Future<void> connect(McpServerConfig config);

  /// Sends a JSON-RPC 2.0 request and returns the response matched by `id`.
  Future<Map<String, dynamic>> sendRequest(
    String method, [
    Map<String, dynamic>? params,
  ]);

  /// Sends a JSON-RPC notification (no `id` field, no response expected).
  void sendNotification(String method, [Map<String, dynamic>? params]);

  /// Closes the connection and cancels all pending requests.
  Future<void> close();
}
```

- [ ] **Step 2: Write McpStdioDatasourceProcess**

```dart
// lib/data/mcp/datasource/mcp_stdio_datasource_process.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/debug_logger.dart';
import '../models/mcp_server_config.dart';
import 'mcp_transport_datasource.dart';

class McpStdioDatasourceProcess implements McpTransportDatasource {
  Process? _process;
  StreamSubscription<Map<String, dynamic>>? _sub;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  int _nextId = 1;

  @override
  Future<void> connect(McpServerConfig config) async {
    final parts = _splitCommand(config.command ?? '');
    if (parts.isEmpty) throw ArgumentError('MCP stdio config "${config.name}" has no command');
    final executable = parts.first;
    final extraArgs = [...parts.skip(1), ...config.args];

    try {
      _process = await Process.start(
        executable,
        extraArgs,
        environment: config.env.isEmpty ? null : config.env,
        runInShell: false,
      );
    } on ProcessException catch (e) {
      sLog('[McpStdio] Process.start failed for "${config.name}": $e');
      rethrow;
    } on IOException catch (e) {
      sLog('[McpStdio] IO error starting "${config.name}": $e');
      rethrow;
    }

    final responseStream = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(_McpFrameDecoder());

    _sub = responseStream.listen(
      _onMessage,
      onError: (Object e) => dLog('[McpStdio] stdout error for "${config.name}": $e'),
    );
  }

  @override
  Future<Map<String, dynamic>> sendRequest(
    String method, [
    Map<String, dynamic>? params,
  ]) {
    final id = _nextId++;
    _writeMessage({'jsonrpc': '2.0', 'id': id, 'method': method, if (params != null) 'params': params});
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    return completer.future;
  }

  @override
  void sendNotification(String method, [Map<String, dynamic>? params]) {
    _writeMessage({'jsonrpc': '2.0', 'method': method, if (params != null) 'params': params});
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _process?.kill(ProcessSignal.sigterm);
    await _process?.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _process?.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    _failPending('MCP connection closed');
  }

  void _onMessage(Map<String, dynamic> msg) {
    final id = msg['id'];
    if (id is int) _pending.remove(id)?.complete(msg);
  }

  void _writeMessage(Map<String, dynamic> msg) {
    final body = utf8.encode(jsonEncode(msg));
    _process!.stdin.add(utf8.encode('Content-Length: ${body.length}\r\n\r\n'));
    _process!.stdin.add(body);
  }

  void _failPending(String reason) {
    for (final c in _pending.values) {
      c.completeError(StateError(reason));
    }
    _pending.clear();
  }

  // Splits "npx -y @scope/pkg" into ["npx", "-y", "@scope/pkg"],
  // respecting single and double quotes.
  static List<String> _splitCommand(String command) {
    final parts = <String>[];
    final buf = StringBuffer();
    var inSingle = false;
    var inDouble = false;
    for (var i = 0; i < command.length; i++) {
      final ch = command[i];
      if (ch == "'" && !inDouble) {
        inSingle = !inSingle;
      } else if (ch == '"' && !inSingle) {
        inDouble = !inDouble;
      } else if (ch == ' ' && !inSingle && !inDouble) {
        if (buf.isNotEmpty) { parts.add(buf.toString()); buf.clear(); }
      } else {
        buf.write(ch);
      }
    }
    if (buf.isNotEmpty) parts.add(buf.toString());
    return parts;
  }
}

// Decodes Content-Length-framed lines from stdout into JSON-RPC messages.
// Expects output from LineSplitter: header line, blank line, JSON body line.
class _McpFrameDecoder extends StreamTransformerBase<String, Map<String, dynamic>> {
  const _McpFrameDecoder();

  @override
  Stream<Map<String, dynamic>> bind(Stream<String> stream) async* {
    int? pendingLength;
    await for (final line in stream) {
      if (pendingLength == null) {
        if (line.startsWith('Content-Length: ')) {
          pendingLength = int.tryParse(line.substring(16).trim());
        }
      } else if (line.trim().isEmpty) {
        // blank separator — next non-empty line is the body
      } else {
        try {
          yield jsonDecode(line) as Map<String, dynamic>;
        } catch (e) {
          dLog('[McpFrameDecoder] JSON parse error: $e');
        }
        pendingLength = null;
      }
    }
  }
}
```

- [ ] **Step 3: Run analyze**

```bash
flutter analyze lib/data/mcp/datasource/mcp_stdio_datasource_process.dart \
               lib/data/mcp/datasource/mcp_transport_datasource.dart
```
Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/data/mcp/datasource/mcp_transport_datasource.dart \
        lib/data/mcp/datasource/mcp_stdio_datasource_process.dart
git commit -m "feat: add McpTransportDatasource interface and McpStdioDatasourceProcess"
```

---

## Task 6: McpHttpSseDatasource

**Files:**
- Create: `lib/data/mcp/datasource/mcp_http_sse_datasource_dio.dart`

Tested indirectly via McpClientSession in Task 7 using a fake transport.

- [ ] **Step 1: Write the datasource**

```dart
// lib/data/mcp/datasource/mcp_http_sse_datasource_dio.dart
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/utils/debug_logger.dart';
import '../models/mcp_server_config.dart';
import 'mcp_transport_datasource.dart';

class McpHttpSseDatasourceDio implements McpTransportDatasource {
  McpHttpSseDatasourceDio({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  final _pending = <int, Completer<Map<String, dynamic>>>{};
  int _nextId = 1;
  String? _postUrl;
  StreamSubscription<_SseEvent>? _sseSub;
  bool _dead = false;

  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  @override
  Future<void> connect(McpServerConfig config) =>
      _connectSse(config.url!, attempt: 0);

  Future<void> _connectSse(String sseUrl, {required int attempt}) async {
    try {
      final response = await _dio.get<ResponseBody>(
        sseUrl,
        options: Options(
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
          responseType: ResponseType.stream,
        ),
      );
      final events = response.data!.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .transform(const _SseLineDecoder());

      _sseSub = events.listen(
        _onEvent,
        onError: (Object e) async {
          dLog('[McpHttpSse] SSE error: $e');
          await _maybeReconnect(sseUrl, attempt);
        },
        onDone: () async => _maybeReconnect(sseUrl, attempt),
      );
    } on DioException catch (e) {
      dLog('[McpHttpSse] connect failed (attempt $attempt): $e');
      if (attempt < _maxRetries) {
        await Future<void>.delayed(_retryDelay);
        return _connectSse(sseUrl, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  Future<void> _maybeReconnect(String sseUrl, int attempt) async {
    if (_dead) return;
    if (attempt < _maxRetries) {
      await Future<void>.delayed(_retryDelay);
      await _connectSse(sseUrl, attempt: attempt + 1);
    } else {
      _dead = true;
      _failPending('MCP server disconnected after ${ _maxRetries} retries');
    }
  }

  @override
  Future<Map<String, dynamic>> sendRequest(
    String method, [
    Map<String, dynamic>? params,
  ]) async {
    if (_dead) throw StateError('MCP server disconnected');
    if (_postUrl == null) throw StateError('MCP endpoint not yet received from SSE');
    final id = _nextId++;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    });
    await _dio.post<void>(
      _postUrl!,
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    return completer.future;
  }

  @override
  void sendNotification(String method, [Map<String, dynamic>? params]) {
    if (_dead || _postUrl == null) return;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      if (params != null) 'params': params,
    });
    _dio.post<void>(
      _postUrl!,
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  @override
  Future<void> close() async {
    _dead = true;
    await _sseSub?.cancel();
    _failPending('MCP connection closed');
  }

  void _onEvent(_SseEvent event) {
    if (event.type == 'endpoint') {
      _postUrl = event.data.trim();
      return;
    }
    if (event.data.isEmpty) return;
    try {
      final msg = jsonDecode(event.data) as Map<String, dynamic>;
      final id = msg['id'];
      if (id is int) _pending.remove(id)?.complete(msg);
    } catch (e) {
      dLog('[McpHttpSse] JSON parse error: $e');
    }
  }

  void _failPending(String reason) {
    for (final c in _pending.values) {
      c.completeError(StateError(reason));
    }
    _pending.clear();
  }
}

class _SseEvent {
  _SseEvent({required this.type, required this.data});
  final String type;
  final String data;
}

class _SseLineDecoder extends StreamTransformerBase<String, _SseEvent> {
  const _SseLineDecoder();

  @override
  Stream<_SseEvent> bind(Stream<String> stream) async* {
    String? type;
    final dataBuf = StringBuffer();
    await for (final line in stream) {
      if (line.isEmpty) {
        if (dataBuf.isNotEmpty) {
          yield _SseEvent(type: type ?? 'message', data: dataBuf.toString());
          type = null;
          dataBuf.clear();
        }
      } else if (line.startsWith('event: ')) {
        type = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        if (dataBuf.isNotEmpty) dataBuf.write('\n');
        dataBuf.write(line.substring(6));
      }
    }
  }
}
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/data/mcp/datasource/mcp_http_sse_datasource_dio.dart
```
Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/data/mcp/datasource/mcp_http_sse_datasource_dio.dart
git commit -m "feat: add McpHttpSseDatasourceDio with SSE stream parsing and POST dispatch"
```

---

## Task 7: McpClientSession

**Files:**
- Create: `lib/services/mcp/mcp_client_session.dart`
- Test: `test/services/mcp/mcp_client_session_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/services/mcp/mcp_client_session_test.dart
import 'package:code_bench_app/data/mcp/datasource/mcp_transport_datasource.dart';
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/services/mcp/mcp_client_session.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransport implements McpTransportDatasource {
  final notifications = <String>[];
  bool closed = false;

  final _responses = <String, Map<String, dynamic>>{
    'initialize': {
      'jsonrpc': '2.0',
      'id': 1,
      'result': {
        'protocolVersion': '2024-11-05',
        'serverInfo': {'name': 'test', 'version': '1.0'},
        'capabilities': {},
      },
    },
    'tools/list': {
      'jsonrpc': '2.0',
      'id': 2,
      'result': {
        'tools': [
          {
            'name': 'search',
            'description': 'Search the web',
            'inputSchema': {'type': 'object'},
          },
        ],
      },
    },
    'tools/call': {
      'jsonrpc': '2.0',
      'id': 3,
      'result': {
        'content': [{'type': 'text', 'text': 'Result text'}],
        'isError': false,
      },
    },
  };

  @override
  Future<void> connect(McpServerConfig config) async {}

  @override
  Future<Map<String, dynamic>> sendRequest(String method, [Map<String, dynamic>? params]) async =>
      _responses[method] ?? {'jsonrpc': '2.0', 'id': 1, 'result': {}};

  @override
  void sendNotification(String method, [Map<String, dynamic>? params]) => notifications.add(method);

  @override
  Future<void> close() async => closed = true;
}

const _cfg = McpServerConfig(
  id: 'srv',
  name: 'test',
  transport: McpTransport.stdio,
  command: 'npx test-server',
);

void main() {
  group('McpClientSession.start()', () {
    test('discovers tools from tools/list', () async {
      final session = await McpClientSession.start(
        config: _cfg,
        datasource: _FakeTransport(),
        initTimeout: const Duration(seconds: 5),
      );
      expect(session.tools, hasLength(1));
      expect(session.tools.first.name, 'search');
    });

    test('sends notifications/initialized after initialize', () async {
      final transport = _FakeTransport();
      await McpClientSession.start(
        config: _cfg,
        datasource: transport,
        initTimeout: const Duration(seconds: 5),
      );
      expect(transport.notifications, contains('notifications/initialized'));
    });
  });

  group('McpClientSession.execute()', () {
    test('returns text content from tools/call response', () async {
      final session = await McpClientSession.start(
        config: _cfg,
        datasource: _FakeTransport(),
        initTimeout: const Duration(seconds: 5),
      );
      final result = await session.execute('search', {'query': 'flutter'});
      expect(result, 'Result text');
    });

    test('throws McpToolCallException when isError is true', () async {
      final transport = _FakeTransport();
      transport._responses['tools/call'] = {
        'jsonrpc': '2.0',
        'id': 3,
        'result': {
          'content': [{'type': 'text', 'text': 'something broke'}],
          'isError': true,
        },
      };
      final session = await McpClientSession.start(
        config: _cfg,
        datasource: transport,
        initTimeout: const Duration(seconds: 5),
      );
      expect(
        () => session.execute('search', {}),
        throwsA(isA<McpToolCallException>()),
      );
    });
  });

  group('McpClientSession.teardown()', () {
    test('closes the transport', () async {
      final transport = _FakeTransport();
      final session = await McpClientSession.start(
        config: _cfg,
        datasource: transport,
        initTimeout: const Duration(seconds: 5),
      );
      await session.teardown();
      expect(transport.closed, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/mcp/mcp_client_session_test.dart
```
Expected: FAIL — file not found.

- [ ] **Step 3: Write McpClientSession**

```dart
// lib/services/mcp/mcp_client_session.dart
import '../../data/mcp/datasource/mcp_transport_datasource.dart';
import '../../data/mcp/models/mcp_server_config.dart';
import '../../data/mcp/models/mcp_tool_info.dart';

class McpClientSession {
  McpClientSession._({
    required this.config,
    required this.tools,
    required McpTransportDatasource datasource,
  }) : _datasource = datasource;

  final McpServerConfig config;
  final List<McpToolInfo> tools;
  final McpTransportDatasource _datasource;

  static Future<McpClientSession> start({
    required McpServerConfig config,
    required McpTransportDatasource datasource,
    Duration initTimeout = const Duration(seconds: 30),
  }) async {
    await datasource.connect(config);

    await datasource
        .sendRequest('initialize', {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'code-bench', 'version': '1.0'},
        })
        .timeout(initTimeout);

    datasource.sendNotification('notifications/initialized');

    final toolsResponse =
        await datasource.sendRequest('tools/list').timeout(initTimeout);

    final rawTools =
        (toolsResponse['result']?['tools'] as List<dynamic>?) ?? [];
    final tools = rawTools
        .whereType<Map<String, dynamic>>()
        .map((t) => McpToolInfo(
              name: t['name'] as String,
              description: (t['description'] as String?) ?? '',
              inputSchema:
                  (t['inputSchema'] as Map<String, dynamic>?) ?? const {},
            ))
        .toList();

    return McpClientSession._(
        config: config, tools: tools, datasource: datasource);
  }

  Future<String> execute(
    String toolName,
    Map<String, dynamic> args, {
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final response = await _datasource
        .sendRequest('tools/call', {'name': toolName, 'arguments': args})
        .timeout(timeout);

    final result = response['result'] as Map<String, dynamic>?;
    final isError = result?['isError'] as bool? ?? false;
    final content = (result?['content'] as List<dynamic>?) ?? [];

    final text = content
        .whereType<Map<String, dynamic>>()
        .where((c) => c['type'] == 'text')
        .map((c) => (c['text'] as String?) ?? '')
        .join('\n');

    if (isError) throw McpToolCallException(text);
    return text;
  }

  Future<void> teardown() => _datasource.close();
}

class McpToolCallException implements Exception {
  McpToolCallException(this.message);
  final String message;
  @override
  String toString() => 'McpToolCallException: $message';
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/services/mcp/mcp_client_session_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/mcp/mcp_client_session.dart test/services/mcp/mcp_client_session_test.dart
git commit -m "feat: add McpClientSession with initialize handshake and tool execution"
```

---

## Task 8: McpTool

**Files:**
- Create: `lib/services/mcp/mcp_tool.dart`
- Test: `test/services/mcp/mcp_tool_test.dart`

- [ ] **Step 1: Write the failing test**

The `McpTool` uses a function injection for `execute` to avoid needing a live `McpClientSession` in tests. Check `lib/data/coding_tools/models/tool_context.dart` for the exact `EffectiveDenylist` type import path before running.

```dart
// test/services/mcp/mcp_tool_test.dart
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_context.dart';
import 'package:code_bench_app/data/mcp/models/mcp_tool_info.dart';
import 'package:code_bench_app/services/mcp/mcp_client_session.dart';
import 'package:code_bench_app/services/mcp/mcp_tool.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal fake denylist — EffectiveDenylist is required by ToolContext.
// Adjust import path to match the actual location in this codebase.
import 'package:code_bench_app/data/coding_tools/models/coding_tools_denylist_state.dart';
import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';

class _EmptyDenylist implements EffectiveDenylist {
  const _EmptyDenylist();
  @override
  bool isDenied(String path, DenylistCategory category) => false;
  @override
  Set<String> patterns(DenylistCategory category) => {};
}

ToolContext _ctx(Map<String, dynamic> args) => ToolContext(
      projectPath: '/tmp/proj',
      sessionId: 's1',
      messageId: 'm1',
      args: args,
      denylist: const _EmptyDenylist(),
    );

const _info = McpToolInfo(
  name: 'search',
  description: 'Search the web',
  inputSchema: {'type': 'object'},
);

void main() {
  group('McpTool', () {
    test('name is "serverName/toolName"', () {
      final tool = McpTool(
        serverName: 'github', info: _info, execute: (_, __) async => 'ok',
      );
      expect(tool.name, 'github/search');
    });

    test('capability is shell', () {
      final tool = McpTool(
        serverName: 'github', info: _info, execute: (_, __) async => 'ok',
      );
      expect(tool.capability, ToolCapability.shell);
    });

    test('execute returns CodingToolResult.success with text', () async {
      final tool = McpTool(
        serverName: 'github',
        info: _info,
        execute: (name, args) async => 'found: ${args['query']}',
      );
      final result = await tool.execute(_ctx({'query': 'flutter'}));
      expect(result, isA<CodingToolResultSuccess>());
      expect((result as CodingToolResultSuccess).output, 'found: flutter');
    });

    test('execute returns CodingToolResult.error on McpToolCallException', () async {
      final tool = McpTool(
        serverName: 'github',
        info: _info,
        execute: (_, __) async => throw McpToolCallException('server error'),
      );
      final result = await tool.execute(_ctx({}));
      expect(result, isA<CodingToolResultError>());
      expect((result as CodingToolResultError).message, contains('server error'));
    });

    test('fromSession factory builds correct name', () {
      // fromSession is a convenience factory — name must still be server/tool.
      // Verify via the McpTool.fromSession constructor. Requires a live session,
      // so we test the name contract via the base constructor instead.
      final tool = McpTool(
        serverName: 'my-server', info: _info, execute: (_, __) async => '',
      );
      expect(tool.name, startsWith('my-server/'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/mcp/mcp_tool_test.dart
```
Expected: FAIL — file not found.

- [ ] **Step 3: Write McpTool**

```dart
// lib/services/mcp/mcp_tool.dart
import '../../core/utils/debug_logger.dart';
import '../../data/coding_tools/models/coding_tool_result.dart';
import '../../data/coding_tools/models/tool.dart';
import '../../data/coding_tools/models/tool_capability.dart';
import '../../data/coding_tools/models/tool_context.dart';
import '../../data/mcp/models/mcp_tool_info.dart';
import 'mcp_client_session.dart';

typedef _McpExecutor = Future<String> Function(
  String toolName,
  Map<String, dynamic> args,
);

class McpTool implements Tool {
  McpTool({
    required String serverName,
    required McpToolInfo info,
    required _McpExecutor execute,
  })  : _serverName = serverName,
        _info = info,
        _execute = execute;

  factory McpTool.fromSession({
    required McpClientSession session,
    required McpToolInfo info,
  }) =>
      McpTool(
        serverName: session.config.name,
        info: info,
        execute: (toolName, args) => session.execute(toolName, args),
      );

  final String _serverName;
  final McpToolInfo _info;
  final _McpExecutor _execute;

  @override
  String get name => '$_serverName/${_info.name}';

  @override
  String get description => _info.description;

  @override
  Map<String, dynamic> get inputSchema => _info.inputSchema;

  @override
  ToolCapability get capability => ToolCapability.shell;

  @override
  Map<String, dynamic> toOpenAiToolJson() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': inputSchema,
        },
      };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    try {
      final result = await _execute(_info.name, ctx.args);
      return CodingToolResult.success(result);
    } on McpToolCallException catch (e) {
      dLog('[McpTool] tool error for $name: ${e.message}');
      return CodingToolResult.error(e.message);
    } catch (e, st) {
      dLog('[McpTool] unexpected error for $name: $e\n$st');
      return CodingToolResult.error('MCP tool call failed: $e');
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/services/mcp/mcp_tool_test.dart
```
Expected: PASS. If `EffectiveDenylist` import fails, check the actual path in `tool_context.dart` and adjust.

- [ ] **Step 5: Commit**

```bash
git add lib/services/mcp/mcp_tool.dart test/services/mcp/mcp_tool_test.dart
git commit -m "feat: add McpTool extending Tool with shell capability and error handling"
```

---

## Task 9: McpServerStatusNotifier + McpServersFailure

**Files:**
- Create: `lib/features/settings/notifiers/mcp_server_status_notifier.dart`
- Create: `lib/features/settings/notifiers/mcp_servers_failure.dart`

These types carry no logic beyond freezed-generated code; they are exercised in McpService and Actions tests.

- [ ] **Step 1: Create McpServerStatus and McpServerStatusNotifier**

```dart
// lib/features/settings/notifiers/mcp_server_status_notifier.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_server_status_notifier.freezed.dart';
part 'mcp_server_status_notifier.g.dart';

@freezed
sealed class McpServerStatus with _$McpServerStatus {
  const factory McpServerStatus.stopped() = McpServerStopped;
  const factory McpServerStatus.starting() = McpServerStarting;
  const factory McpServerStatus.running() = McpServerRunning;
  const factory McpServerStatus.error(String message) = McpServerError;
  const factory McpServerStatus.pendingRemoval() = McpServerPendingRemoval;
}

@riverpod
class McpServerStatusNotifier extends _$McpServerStatusNotifier {
  @override
  Map<String, McpServerStatus> build() => {};

  void setStatus(String serverId, McpServerStatus status) =>
      state = {...state, serverId: status};

  void remove(String serverId) =>
      state = Map.of(state)..remove(serverId);

  void clearAll() => state = {};
}
```

- [ ] **Step 2: Create McpServersFailure**

```dart
// lib/features/settings/notifiers/mcp_servers_failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_servers_failure.freezed.dart';

@freezed
sealed class McpServersFailure with _$McpServersFailure {
  const factory McpServersFailure.saveError([String? detail]) = McpServersSaveError;
  const factory McpServersFailure.removeError([String? detail]) = McpServersRemoveError;
  const factory McpServersFailure.unknown(Object error) = McpServersUnknownError;
}
```

- [ ] **Step 3: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: generates 4 files.

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/notifiers/mcp_server_status_notifier.dart \
        lib/features/settings/notifiers/mcp_server_status_notifier.freezed.dart \
        lib/features/settings/notifiers/mcp_server_status_notifier.g.dart \
        lib/features/settings/notifiers/mcp_servers_failure.dart \
        lib/features/settings/notifiers/mcp_servers_failure.freezed.dart
git commit -m "feat: add McpServerStatusNotifier and McpServersFailure sealed types"
```

---

## Task 10: McpServersNotifier + McpServersActions

**Files:**
- Create: `lib/features/settings/notifiers/mcp_servers_notifier.dart`
- Create: `lib/features/settings/notifiers/mcp_servers_actions.dart`
- Test: `test/features/settings/notifiers/mcp_servers_notifier_test.dart`
- Test: `test/features/settings/notifiers/mcp_servers_actions_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/settings/notifiers/mcp_servers_notifier_test.dart
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository.dart';
import 'package:code_bench_app/features/settings/notifiers/mcp_servers_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends Fake implements McpRepository {
  final List<McpServerConfig> _configs;
  _FakeRepo([List<McpServerConfig>? configs]) : _configs = configs ?? [];

  @override
  Stream<List<McpServerConfig>> watchAll() => Stream.value(List.of(_configs));

  @override
  Future<List<McpServerConfig>> getAll() async => List.of(_configs);

  @override
  Future<List<McpServerConfig>> getEnabled() async =>
      _configs.where((c) => c.enabled).toList();

  @override
  Future<void> upsert(McpServerConfig c) async => _configs.add(c);

  @override
  Future<void> delete(String id) async =>
      _configs.removeWhere((c) => c.id == id);
}

void main() {
  group('McpServersNotifier', () {
    test('emits empty list when repository is empty', () async {
      final c = ProviderContainer(
        overrides: [mcpRepositoryProvider.overrideWithValue(_FakeRepo())],
      );
      addTearDown(c.dispose);
      final state = await c.read(mcpServersProvider.future);
      expect(state, isEmpty);
    });

    test('emits configs from repository', () async {
      final repo = _FakeRepo([
        const McpServerConfig(
          id: '1', name: 'github',
          transport: McpTransport.stdio, command: 'npx mcp',
        ),
      ]);
      final c = ProviderContainer(
        overrides: [mcpRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      final state = await c.read(mcpServersProvider.future);
      expect(state, hasLength(1));
      expect(state.first.name, 'github');
    });
  });
}
```

```dart
// test/features/settings/notifiers/mcp_servers_actions_test.dart
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository.dart';
import 'package:code_bench_app/features/settings/notifiers/mcp_servers_actions.dart';
import 'package:code_bench_app/features/settings/notifiers/mcp_servers_failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends Fake implements McpRepository {
  final List<McpServerConfig> _configs = [];
  bool throwOnSave = false;
  bool throwOnDelete = false;

  @override
  Stream<List<McpServerConfig>> watchAll() => Stream.value(List.of(_configs));

  @override
  Future<List<McpServerConfig>> getAll() async => List.of(_configs);

  @override
  Future<List<McpServerConfig>> getEnabled() async =>
      _configs.where((c) => c.enabled).toList();

  @override
  Future<void> upsert(McpServerConfig config) async {
    if (throwOnSave) throw Exception('DB error');
    _configs.removeWhere((c) => c.id == config.id);
    _configs.add(config);
  }

  @override
  Future<void> delete(String id) async {
    if (throwOnDelete) throw Exception('DB error');
    _configs.removeWhere((c) => c.id == id);
  }
}

const _cfg = McpServerConfig(
  id: 'x', name: 'server', transport: McpTransport.stdio, command: 'cmd',
);

void main() {
  group('McpServersActions.save()', () {
    test('calls upsert and transitions to AsyncData', () async {
      final repo = _FakeRepo();
      final c = ProviderContainer(
        overrides: [mcpRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      await c.read(mcpServersActionsProvider.notifier).save(_cfg);
      expect(c.read(mcpServersActionsProvider).hasValue, isTrue);
      expect(repo._configs, hasLength(1));
    });

    test('transitions to AsyncError with McpServersSaveError on failure', () async {
      final repo = _FakeRepo()..throwOnSave = true;
      final c = ProviderContainer(
        overrides: [mcpRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      await c.read(mcpServersActionsProvider.notifier).save(_cfg);
      expect(c.read(mcpServersActionsProvider).hasError, isTrue);
      expect(c.read(mcpServersActionsProvider).error, isA<McpServersSaveError>());
    });
  });

  group('McpServersActions.remove()', () {
    test('calls delete and transitions to AsyncData', () async {
      final repo = _FakeRepo().._configs.add(_cfg);
      final c = ProviderContainer(
        overrides: [mcpRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      await c.read(mcpServersActionsProvider.notifier).remove('x');
      expect(c.read(mcpServersActionsProvider).hasValue, isTrue);
      expect(repo._configs, isEmpty);
    });

    test('transitions to AsyncError with McpServersRemoveError on failure', () async {
      final repo = _FakeRepo()
        .._configs.add(_cfg)
        ..throwOnDelete = true;
      final c = ProviderContainer(
        overrides: [mcpRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      await c.read(mcpServersActionsProvider.notifier).remove('x');
      expect(c.read(mcpServersActionsProvider).error, isA<McpServersRemoveError>());
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/features/settings/notifiers/mcp_servers_notifier_test.dart \
             test/features/settings/notifiers/mcp_servers_actions_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Write McpServersNotifier**

`McpServersNotifier` is a `StreamNotifier` — it derives its `AsyncValue<List<McpServerConfig>>` directly from the repository's Drift stream. The Drift stream auto-emits on every DB write, so no manual invalidation is needed.

```dart
// lib/features/settings/notifiers/mcp_servers_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/mcp/models/mcp_server_config.dart';
import '../../../data/mcp/repository/mcp_repository.dart';

part 'mcp_servers_notifier.g.dart';

@riverpod
class McpServersNotifier extends _$McpServersNotifier {
  @override
  Stream<List<McpServerConfig>> build() =>
      ref.watch(mcpRepositoryProvider).watchAll();
}
```

- [ ] **Step 4: Write McpServersActions**

```dart
// lib/features/settings/notifiers/mcp_servers_actions.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/mcp/models/mcp_server_config.dart';
import '../../../data/mcp/repository/mcp_repository.dart';
import 'mcp_servers_failure.dart';

part 'mcp_servers_actions.g.dart';

@Riverpod(keepAlive: true)
class McpServersActions extends _$McpServersActions {
  @override
  FutureOr<void> build() {}

  McpServersFailure _asFailure(Object e) => switch (e) {
        McpServersFailure() => e,
        _ => McpServersFailure.unknown(e),
      };

  Future<void> save(McpServerConfig config) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(mcpRepositoryProvider).upsert(config);
      } catch (e, st) {
        dLog('[McpServersActions] save failed: $e');
        Error.throwWithStackTrace(McpServersFailure.saveError(e.toString()), st);
      }
    });
  }

  Future<void> remove(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(mcpRepositoryProvider).delete(id);
      } catch (e, st) {
        dLog('[McpServersActions] remove failed: $e');
        Error.throwWithStackTrace(McpServersFailure.removeError(e.toString()), st);
      }
    });
  }
}
```

- [ ] **Step 5: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
flutter test test/features/settings/notifiers/mcp_servers_notifier_test.dart \
             test/features/settings/notifiers/mcp_servers_actions_test.dart
```
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/notifiers/mcp_servers_notifier.dart \
        lib/features/settings/notifiers/mcp_servers_notifier.g.dart \
        lib/features/settings/notifiers/mcp_servers_actions.dart \
        lib/features/settings/notifiers/mcp_servers_actions.g.dart \
        test/features/settings/notifiers/
git commit -m "feat: add McpServersNotifier (stream-backed) and McpServersActions"
```

---

## Task 11: McpService

**Files:**
- Create: `lib/services/mcp/mcp_service.dart`
- Test: `test/services/mcp/mcp_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/services/mcp/mcp_service_test.dart
import 'package:code_bench_app/data/coding_tools/models/coding_tools_denylist_state.dart';
import 'package:code_bench_app/data/coding_tools/models/denylist_category.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench_app/data/coding_tools/repository/coding_tools_denylist_repository.dart';
import 'package:code_bench_app/data/mcp/datasource/mcp_transport_datasource.dart';
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/data/mcp/repository/mcp_repository.dart';
import 'package:code_bench_app/features/settings/notifiers/mcp_server_status_notifier.dart';
import 'package:code_bench_app/services/coding_tools/tool_registry.dart';
import 'package:code_bench_app/services/mcp/mcp_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends Fake implements McpRepository {
  final List<McpServerConfig> enabled;
  _FakeRepo(this.enabled);

  @override
  Future<List<McpServerConfig>> getEnabled() async => enabled;

  @override
  Stream<List<McpServerConfig>> watchAll() => Stream.value([]);

  @override
  Future<List<McpServerConfig>> getAll() async => [];

  @override
  Future<void> upsert(McpServerConfig c) async {}

  @override
  Future<void> delete(String id) async {}
}

class _FakeTransport implements McpTransportDatasource {
  @override Future<void> connect(McpServerConfig c) async {}
  @override
  Future<Map<String, dynamic>> sendRequest(String m, [Map<String, dynamic>? p]) async {
    if (m == 'initialize') {
      return {'jsonrpc': '2.0', 'id': 1, 'result': {
        'protocolVersion': '2024-11-05', 'capabilities': {}, 'serverInfo': {},
      }};
    }
    if (m == 'tools/list') {
      return {'jsonrpc': '2.0', 'id': 2, 'result': {'tools': [
        {'name': 'search', 'description': 'Search', 'inputSchema': {'type': 'object'}},
      ]}};
    }
    return {'jsonrpc': '2.0', 'id': 3, 'result': {}};
  }
  @override void sendNotification(String m, [Map<String, dynamic>? p]) {}
  @override Future<void> close() async {}
}

class _EmptyDenylistRepo implements CodingToolsDenylistRepository {
  @override Future<CodingToolsDenylistState> load() async => CodingToolsDenylistState.empty();
  @override Future<CodingToolsDenylistState> save(CodingToolsDenylistState s) async => s;
  @override Future<Set<String>> effective(DenylistCategory c) async => {};
  @override Future<void> restoreAllDefaults() async {}
}

void main() {
  group('McpService.startSession()', () {
    test('registers one McpTool per discovered server tool', () async {
      final registry = ToolRegistry(
        builtIns: [],
        denylistRepo: _EmptyDenylistRepo(),
      );
      final statusNotifier = McpServerStatusNotifier();

      final svc = McpService(
        repository: _FakeRepo([
          const McpServerConfig(
            id: 'srv', name: 'test', transport: McpTransport.stdio, command: 'cmd',
          ),
        ]),
        statusNotifier: statusNotifier,
        transportFactory: (_) => _FakeTransport(),
      );

      final teardown = await svc.startSession(
        registry: registry,
        sessionId: 'session-1',
      );

      expect(registry.tools.where((t) => t.name == 'test/search'), hasLength(1));
      expect(
        registry.tools.firstWhere((t) => t.name == 'test/search').capability,
        ToolCapability.shell,
      );

      await teardown();
      expect(registry.tools.where((t) => t.name.startsWith('test/')), isEmpty);
    });

    test('skips a server on startup error without failing the session', () async {
      final registry = ToolRegistry(builtIns: [], denylistRepo: _EmptyDenylistRepo());
      final statusNotifier = McpServerStatusNotifier();

      final svc = McpService(
        repository: _FakeRepo([
          const McpServerConfig(
            id: 'bad', name: 'broken', transport: McpTransport.stdio, command: 'bad-cmd',
          ),
        ]),
        statusNotifier: statusNotifier,
        transportFactory: (_) => throw Exception('process not found'),
      );

      final teardown = await svc.startSession(registry: registry, sessionId: 's2');
      expect(registry.tools.where((t) => t.name.startsWith('broken/')), isEmpty);
      await teardown();
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/mcp/mcp_service_test.dart
```
Expected: FAIL — file not found.

- [ ] **Step 3: Write McpService**

```dart
// lib/services/mcp/mcp_service.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/mcp/datasource/mcp_http_sse_datasource_dio.dart';
import '../../data/mcp/datasource/mcp_stdio_datasource_process.dart';
import '../../data/mcp/datasource/mcp_transport_datasource.dart';
import '../../data/mcp/models/mcp_server_config.dart';
import '../../data/mcp/repository/mcp_repository.dart';
import '../../features/settings/notifiers/mcp_server_status_notifier.dart';
import '../../services/coding_tools/tool_registry.dart';
import 'mcp_client_session.dart';
import 'mcp_tool.dart';

part 'mcp_service.g.dart';

typedef _TransportFactory = McpTransportDatasource Function(McpServerConfig);

@riverpod
McpService mcpService(Ref ref) => McpService(
      repository: ref.watch(mcpRepositoryProvider),
      statusNotifier: ref.watch(mcpServerStatusProvider.notifier),
    );

class McpService {
  McpService({
    required McpRepository repository,
    required McpServerStatusNotifier statusNotifier,
    _TransportFactory? transportFactory,
  })  : _repository = repository,
        _statusNotifier = statusNotifier,
        _transportFactory = transportFactory ?? _defaultTransport;

  final McpRepository _repository;
  final McpServerStatusNotifier _statusNotifier;
  final _TransportFactory _transportFactory;

  static McpTransportDatasource _defaultTransport(McpServerConfig config) =>
      switch (config.transport) {
        McpTransport.stdio => McpStdioDatasourceProcess(),
        McpTransport.httpSse => McpHttpSseDatasourceDio(),
      };

  Future<Future<void> Function()> startSession({
    required ToolRegistry registry,
    required String sessionId,
  }) async {
    final configs = await _repository.getEnabled();
    final sessions = <McpClientSession>[];
    final registeredNames = <String>[];

    for (final config in configs) {
      _statusNotifier.setStatus(config.id, const McpServerStatus.starting());
      try {
        final transport = _transportFactory(config);
        final session = await McpClientSession.start(
          config: config,
          datasource: transport,
          initTimeout: const Duration(seconds: 30),
        );
        sessions.add(session);

        for (final toolInfo in session.tools) {
          final tool = McpTool.fromSession(session: session, info: toolInfo);
          registry.register(tool);
          registeredNames.add(tool.name);
        }

        _statusNotifier.setStatus(config.id, const McpServerStatus.running());
      } catch (e, st) {
        dLog('[McpService] failed to start "${config.name}": $e\n$st');
        sLog('[McpService] server startup error for "${config.name}": ${e.runtimeType}');
        _statusNotifier.setStatus(
          config.id,
          McpServerStatus.error(e.toString()),
        );
      }
    }

    return () async {
      for (final name in registeredNames) {
        registry.unregister(name);
      }
      for (final session in sessions) {
        try {
          await session.teardown();
          _statusNotifier.setStatus(session.config.id, const McpServerStatus.stopped());
        } catch (e) {
          dLog('[McpService] teardown error for "${session.config.name}": $e');
        }
      }
    };
  }
}
```

- [ ] **Step 4: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test test/services/mcp/mcp_service_test.dart
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/services/mcp/ test/services/mcp/mcp_service_test.dart
git commit -m "feat: add McpService with per-session startSession/teardown orchestration"
```

---

## Task 12: AgentService wiring + system prompt update

**Files:**
- Modify: `lib/services/agent/agent_service.dart`

- [ ] **Step 1: Open the file and find the system prompt constant**

Find `_kActSystemPrompt` in `lib/services/agent/agent_service.dart`. Replace the hardcoded tool name list with the generic instruction:

```dart
const String _kActSystemPrompt = '''
You are a coding assistant embedded in a local IDE. You have access to the tools listed in the tools array. Use them as needed.

Rules:
- Read before you edit. Always call read_file on a file before write_file or str_replace against it.
- Prefer str_replace over write_file for targeted edits.
- After making changes, briefly describe what you changed and why in 1-3 sentences.
- If a task is ambiguous or destructive, ask the user before acting.
- All paths you provide must be inside the active project directory.
- If asked to do something your tools cannot do, decline in one sentence.
''';
```

Keep the existing rules; only remove the hardcoded tool name enumeration.

- [ ] **Step 2: Find the agentService provider and inject McpService**

Find the `agentService` provider function (annotated `@Riverpod(keepAlive: true)`). Add `mcpService` to the `AgentService` constructor:

```dart
@Riverpod(keepAlive: true)
Future<AgentService> agentService(Ref ref) async {
  final ai = await ref.watch(aiRepositoryProvider.future);
  final registry = ref.watch(toolRegistryProvider);
  final mcpSvc = ref.watch(mcpServiceProvider);  // add this line
  return AgentService(
    ai: ai,
    registry: registry,
    mcpService: mcpSvc,                           // add this parameter
    cancelFlag: () => ref.read(agentCancelProvider),
    requestPermission: (req) =>
        ref.read(agentPermissionRequestProvider.notifier).request(req),
  );
}
```

- [ ] **Step 3: Update the AgentService constructor and runAgenticTurn**

Add `McpService` field to `AgentService`:

```dart
class AgentService {
  AgentService({
    required AIRepository ai,
    required ToolRegistry registry,
    required McpService mcpService,          // add
    required bool Function() cancelFlag,
    Future<bool> Function(PermissionRequest req)? requestPermission,
    String Function()? idGen,
  })  : _ai = ai,
        _registry = registry,
        _mcpService = mcpService,            // add
        _cancelFlag = cancelFlag,
        _requestPermission = requestPermission,
        _idGen = idGen ?? _defaultIdGen;

  final McpService _mcpService;             // add
  // ... existing fields
```

In `runAgenticTurn`, wrap the existing `while(true)` loop with McpService lifecycle:

```dart
Stream<ChatMessage> runAgenticTurn({...}) async* {
  final teardown = await _mcpService.startSession(
    registry: _registry,
    sessionId: sessionId,
  );
  try {
    // existing while(true) loop — unchanged
    while (true) {
      // ... existing code
    }
  } finally {
    await teardown();
  }
}
```

- [ ] **Step 4: Run build_runner (McpService provider is referenced)**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/services/agent/agent_service.dart
```
Expected: no issues.

- [ ] **Step 6: Run existing agent service tests**

```bash
flutter test test/services/agent/
```
Expected: all pass. If tests break because `AgentService` constructor changed, update the test fixtures to pass a fake `McpService` with a no-op `startSession`.

- [ ] **Step 7: Commit**

```bash
git add lib/services/agent/agent_service.dart lib/services/mcp/mcp_service.g.dart
git commit -m "feat: wire McpService into AgentService and remove hardcoded tool list from system prompt"
```

---

## Task 13: PermissionRequestPreview + ToolCallRow display changes

**Files:**
- Modify: `lib/features/chat/utils/permission_request_preview.dart`
- Modify: `lib/features/chat/widgets/tool_call_row.dart`

- [ ] **Step 1: Update PermissionRequestPreview**

In `permission_request_preview.dart`, add an MCP case to `buildLines`. MCP tool names contain `/`; args are rendered as indented JSON — no bidi sanitization needed (args come from the model, not user shell input):

```dart
static List<String>? buildLines(PermissionRequest req) {
  // MCP tool: name contains "/"
  if (req.toolName.contains('/')) {
    if (req.input.isEmpty) return null;
    final encoded = const JsonEncoder.withIndent('  ').convert(req.input);
    return encoded.split('\n');
  }
  // ... existing cases for write_file, str_replace, bash
}
```

Insert the MCP block as the first condition in `buildLines` (before the `write_file` check).

- [ ] **Step 2: Update ToolCallRow icon and label**

In `tool_call_row.dart`, update `_iconForTool` to handle MCP names:

```dart
IconData _iconForTool(String toolName) {
  if (toolName.contains('/')) return Icons.extension_outlined;
  return switch (toolName) {
    'read_file' || 'read' => Icons.description_outlined,
    'write_file' || 'write' => Icons.edit_outlined,
    'run_command' || 'bash' => Icons.terminal,
    'search' || 'grep' => Icons.search,
    _ => Icons.build_outlined,
  };
}
```

Find the label-rendering logic (likely in `_primaryArg` or the main `build` method) and convert `server/tool_name` to `server › tool_name` for display. Locate where `event.toolName` is shown in the collapsed row and wrap it:

```dart
String _displayName(String toolName) {
  if (toolName.contains('/')) {
    final parts = toolName.split('/');
    return '${parts.first} › ${parts.skip(1).join('/')}';
  }
  return toolName;
}
```

Replace the direct `event.toolName` text reference in the collapsed row with `_displayName(event.toolName)`.

- [ ] **Step 3: Run analyze**

```bash
flutter analyze lib/features/chat/utils/permission_request_preview.dart \
               lib/features/chat/widgets/tool_call_row.dart
```
Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/utils/permission_request_preview.dart \
        lib/features/chat/widgets/tool_call_row.dart
git commit -m "feat: add MCP tool display support in PermissionRequestPreview and ToolCallRow"
```

---

## Task 14: Settings nav + McpServersScreen

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`
- Create: `lib/features/settings/mcp_servers_screen.dart`

- [ ] **Step 1: Add mcpServers to the nav enum**

In `settings_screen.dart`, add `mcpServers` to `_SettingsNav`:

```dart
enum _SettingsNav { general, providers, integrations, codingTools, mcpServers, archive }
```

- [ ] **Step 2: Wire the new nav item into _SettingsLeftNav**

In `_SettingsLeftNav.build`, add after the `codingTools` nav item:

```dart
_NavItem(
  icon: Icons.extension_outlined,
  label: 'MCP Servers',
  isActive: widget.activeNav == _SettingsNav.mcpServers,
  onTap: () => widget.onSelect(_SettingsNav.mcpServers),
),
```

- [ ] **Step 3: Add the content route**

In `_buildContent()`, add the mcpServers case:

```dart
Widget _buildContent() {
  return switch (_activeNav) {
    _SettingsNav.general => GeneralScreen(key: ValueKey('general-$_generalVersion')),
    _SettingsNav.providers => const ProvidersScreen(),
    _SettingsNav.integrations => const IntegrationsScreen(),
    _SettingsNav.codingTools => CodingToolsScreen(key: ValueKey('coding-tools-$_codingToolsVersion')),
    _SettingsNav.mcpServers => const McpServersScreen(),    // add
    _SettingsNav.archive => const ArchiveScreen(),
  };
}
```

- [ ] **Step 4: Write McpServersScreen**

```dart
// lib/features/settings/mcp_servers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_constants.dart';
import '../../data/mcp/models/mcp_server_config.dart';
import 'notifiers/mcp_servers_notifier.dart';
import 'notifiers/mcp_servers_actions.dart';
import 'notifiers/mcp_servers_failure.dart';
import 'notifiers/mcp_server_status_notifier.dart';
import 'widgets/mcp_server_card.dart';
import 'widgets/mcp_server_editor_dialog.dart';

class McpServersScreen extends ConsumerStatefulWidget {
  const McpServersScreen({super.key});

  @override
  ConsumerState<McpServersScreen> createState() => _McpServersScreenState();
}

class _McpServersScreenState extends ConsumerState<McpServersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(mcpServersActionsProvider, (_, next) {
        if (next is! AsyncError) return;
        final failure = next.error;
        if (failure is! McpServersFailure) return;
        final msg = switch (failure) {
          McpServersSaveError() => 'Failed to save MCP server',
          McpServersRemoveError() => 'Failed to remove MCP server',
          McpServersUnknownError() => 'Unexpected error',
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      });
    });
  }

  void _openAdd() {
    showDialog<void>(
      context: context,
      builder: (_) => McpServerEditorDialog(
        onSave: (config) =>
            ref.read(mcpServersActionsProvider.notifier).save(config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serversAsync = ref.watch(mcpServersProvider);
    final statusMap = ref.watch(mcpServerStatusProvider);

    return Scaffold(
      backgroundColor: ThemeConstants.surfaceColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Text(
                  'MCP Servers',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _openAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Server'),
                ),
              ],
            ),
          ),
          Expanded(
            child: serversAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (servers) => servers.isEmpty
                  ? _EmptyState(onAdd: _openAdd)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: servers.length,
                      itemBuilder: (_, i) => McpServerCard(
                        config: servers[i],
                        status: statusMap[servers[i].id] ??
                            const McpServerStatus.stopped(),
                        onEdit: (config) {
                          showDialog<void>(
                            context: context,
                            builder: (_) => McpServerEditorDialog(
                              initial: config,
                              onSave: (updated) => ref
                                  .read(mcpServersActionsProvider.notifier)
                                  .save(updated),
                            ),
                          );
                        },
                        onRemove: (id) =>
                            ref.read(mcpServersActionsProvider.notifier).remove(id),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.extension_outlined,
              size: 48, color: ThemeConstants.textSecondaryColor),
          const SizedBox(height: 16),
          Text('No MCP servers configured',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAdd,
            child: const Text('+ Add your first MCP server'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/features/settings/settings_screen.dart \
               lib/features/settings/mcp_servers_screen.dart
```
Expected: no issues (stub import errors until Card and Dialog files are created in the next tasks).

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/settings_screen.dart \
        lib/features/settings/mcp_servers_screen.dart
git commit -m "feat: add McpServersScreen and MCP Servers nav entry to settings"
```

---

## Task 15: McpServerCard

**Files:**
- Create: `lib/features/settings/widgets/mcp_server_card.dart`

- [ ] **Step 1: Write McpServerCard**

```dart
// lib/features/settings/widgets/mcp_server_card.dart
import 'package:flutter/material.dart';

import '../../../core/theme/theme_constants.dart';
import '../../../data/mcp/models/mcp_server_config.dart';
import '../notifiers/mcp_server_status_notifier.dart';

class McpServerCard extends StatelessWidget {
  const McpServerCard({
    super.key,
    required this.config,
    required this.status,
    required this.onEdit,
    required this.onRemove,
  });

  final McpServerConfig config;
  final McpServerStatus status;
  final void Function(McpServerConfig) onEdit;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusDot(status: status),
                const SizedBox(width: 8),
                Text(config.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                _TransportBadge(transport: config.transport),
                const Spacer(),
                _ActionMenu(config: config, status: status,
                    onEdit: onEdit, onRemove: onRemove),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              config.transport == McpTransport.stdio
                  ? (config.command ?? '')
                  : (config.url ?? ''),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: ThemeConstants.textSecondaryColor,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            if (status case McpServerRunning()) ...[
              const SizedBox(height: 8),
              // Tool chips are derived from registry — shown as placeholder text
              // for now; full chip implementation requires reading McpService state.
              Text('Tools loaded',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ThemeConstants.successColor,
                      )),
            ],
            if (status case McpServerError(:final message)) ...[
              const SizedBox(height: 8),
              Text(message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeConstants.errorColor,
                      )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final McpServerStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      McpServerRunning() => ThemeConstants.successColor,
      McpServerError() => ThemeConstants.errorColor,
      McpServerStarting() => ThemeConstants.warningColor,
      _ => ThemeConstants.textSecondaryColor,
    };
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TransportBadge extends StatelessWidget {
  const _TransportBadge({required this.transport});
  final McpTransport transport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ThemeConstants.chipBackgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        transport == McpTransport.stdio ? 'stdio' : 'HTTP/SSE',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({
    required this.config,
    required this.status,
    required this.onEdit,
    required this.onRemove,
  });

  final McpServerConfig config;
  final McpServerStatus status;
  final void Function(McpServerConfig) onEdit;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') onEdit(config);
        if (value == 'remove') onRemove(config.id);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(
          value: 'remove',
          child: Text('Remove', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
```

Note: `ThemeConstants.successColor`, `ThemeConstants.warningColor`, `ThemeConstants.errorColor`, and `ThemeConstants.chipBackgroundColor` must exist. If any are missing, add them to `ThemeConstants` — never hardcode hex values in widgets.

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/features/settings/widgets/mcp_server_card.dart
```
Fix any missing `ThemeConstants` tokens before proceeding.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/widgets/mcp_server_card.dart
git commit -m "feat: add McpServerCard with status dot, transport badge, and action menu"
```

---

## Task 16: McpServerEditorDialog

**Files:**
- Create: `lib/features/settings/widgets/mcp_server_editor_dialog.dart`

The dialog has two views: Form (default) and JSON. Uses `re_editor` for the JSON view. Import the package as `re_editor` — verify the exact widget names in the package's pub.dev documentation if needed.

- [ ] **Step 1: Write McpServerEditorDialog**

```dart
// lib/features/settings/widgets/mcp_server_editor_dialog.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/theme_constants.dart';
import '../../../data/mcp/models/mcp_server_config.dart';

class McpServerEditorDialog extends StatefulWidget {
  const McpServerEditorDialog({
    super.key,
    this.initial,
    required this.onSave,
  });

  final McpServerConfig? initial;
  final Future<void> Function(McpServerConfig) onSave;

  @override
  State<McpServerEditorDialog> createState() => _McpServerEditorDialogState();
}

enum _EditorView { form, json }

class McpServerEditorDialogState extends State<McpServerEditorDialog> {
  late McpServerConfig _draft;
  _EditorView _view = _EditorView.form;
  String? _jsonError;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _commandCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  late final CodeLineEditingController _jsonCtrl;

  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _draft = widget.initial ??
        McpServerConfig(
          id: _uuid.v4(),
          name: '',
          transport: McpTransport.stdio,
        );
    _nameCtrl.text = _draft.name;
    _commandCtrl.text = _draft.command ?? '';
    _urlCtrl.text = _draft.url ?? '';
    _jsonCtrl = CodeLineEditingController.fromText(_encodeJson(_draft));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commandCtrl.dispose();
    _urlCtrl.dispose();
    _jsonCtrl.dispose();
    super.dispose();
  }

  McpServerConfig _buildFromForm() => _draft.copyWith(
        name: _sanitize(_nameCtrl.text.trim()),
        command: _draft.transport == McpTransport.stdio
            ? _sanitize(_commandCtrl.text.trim())
            : null,
        url: _draft.transport == McpTransport.httpSse
            ? _sanitize(_urlCtrl.text.trim())
            : null,
      );

  String _encodeJson(McpServerConfig c) =>
      const JsonEncoder.withIndent('  ').convert(c.toJson());

  // Strips bidi override characters and null bytes before persisting.
  static String _sanitize(String s) {
    final buf = StringBuffer();
    for (final rune in s.runes) {
      if (rune == 0) continue;
      if (rune >= 0x202a && rune <= 0x202e) continue;
      if (rune >= 0x2066 && rune <= 0x2069) continue;
      buf.writeCharCode(rune);
    }
    return buf.toString();
  }

  void _switchView(_EditorView target) {
    if (target == _view) return;
    if (target == _EditorView.json) {
      _draft = _buildFromForm();
      _jsonCtrl.text = _encodeJson(_draft);
      setState(() { _view = target; _jsonError = null; });
      return;
    }
    // json → form: parse and validate
    try {
      final parsed = jsonDecode(_jsonCtrl.text) as Map<String, dynamic>;
      _draft = McpServerConfig.fromJson(parsed);
      _nameCtrl.text = _draft.name;
      _commandCtrl.text = _draft.command ?? '';
      _urlCtrl.text = _draft.url ?? '';
      setState(() { _view = target; _jsonError = null; });
    } on FormatException catch (e) {
      setState(() => _jsonError = 'Invalid JSON: ${e.message}');
    } on TypeError catch (_) {
      setState(() => _jsonError = 'JSON does not match server config schema');
    }
  }

  Future<void> _save() async {
    final config = _view == _EditorView.form
        ? _buildFromForm()
        : () {
            final parsed =
                jsonDecode(_jsonCtrl.text) as Map<String, dynamic>;
            return McpServerConfig.fromJson(parsed);
          }();

    setState(() => _saving = true);
    await widget.onSave(config);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.initial == null ? 'Add MCP Server' : 'Edit MCP Server',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  SegmentedButton<_EditorView>(
                    segments: const [
                      ButtonSegment(value: _EditorView.form, label: Text('Form')),
                      ButtonSegment(value: _EditorView.json, label: Text('JSON')),
                    ],
                    selected: {_view},
                    onSelectionChanged: (s) => _switchView(s.first),
                  ),
                ],
              ),
              if (_jsonError != null) ...[
                const SizedBox(height: 8),
                Text(_jsonError!,
                    style: TextStyle(color: ThemeConstants.errorColor,
                        fontSize: 12)),
              ],
              const SizedBox(height: 16),
              Expanded(child: _view == _EditorView.form ? _FormView(this) : _JsonView(this)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Expose state to sub-widgets via named constructor alias
typedef _State = McpServerEditorDialogState;

class _FormView extends StatelessWidget {
  const _FormView(this.s);
  final _State s;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: s._nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<McpTransport>(
            segments: const [
              ButtonSegment(value: McpTransport.stdio, label: Text('stdio')),
              ButtonSegment(value: McpTransport.httpSse, label: Text('HTTP/SSE')),
            ],
            selected: {s._draft.transport},
            onSelectionChanged: (t) =>
                s.setState(() => s._draft = s._draft.copyWith(transport: t.first)),
          ),
          const SizedBox(height: 12),
          if (s._draft.transport == McpTransport.stdio)
            TextField(
              controller: s._commandCtrl,
              decoration: const InputDecoration(
                labelText: 'Command',
                hintText: 'npx -y @modelcontextprotocol/server-github',
              ),
            )
          else
            TextField(
              controller: s._urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://mcp.example.com/sse',
              ),
            ),
          const SizedBox(height: 16),
          _EnvVarsEditor(
            env: s._draft.env,
            onChange: (env) => s.setState(() => s._draft = s._draft.copyWith(env: env)),
          ),
        ],
      ),
    );
  }
}

class _JsonView extends StatelessWidget {
  const _JsonView(this.s);
  final _State s;

  @override
  Widget build(BuildContext context) {
    return CodeEditor(
      controller: s._jsonCtrl,
      style: CodeEditorStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        backgroundColor: ThemeConstants.codeBackgroundColor,
      ),
    );
  }
}

class _EnvVarsEditor extends StatelessWidget {
  const _EnvVarsEditor({required this.env, required this.onChange});
  final Map<String, String> env;
  final void Function(Map<String, String>) onChange;

  @override
  Widget build(BuildContext context) {
    final pairs = env.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Environment Variables',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        ...pairs.asMap().entries.map((e) {
          final index = e.key;
          final pair = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Key'),
                  controller: TextEditingController(text: pair.key),
                  onChanged: (k) {
                    final updated = Map<String, String>.from(env);
                    final val = updated.remove(pair.key) ?? '';
                    updated[k] = val;
                    onChange(updated);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Value'),
                  controller: TextEditingController(text: pair.value),
                  onChanged: (v) {
                    final updated = Map<String, String>.from(env)
                      ..[pair.key] = v;
                    onChange(updated);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  final updated = Map<String, String>.from(env)..remove(pair.key);
                  onChange(updated);
                },
              ),
            ]),
          );
        }),
        TextButton.icon(
          onPressed: () {
            final updated = Map<String, String>.from(env)..[''] = '';
            onChange(updated);
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add variable'),
        ),
      ],
    );
  }
}
```

Note: `ThemeConstants.codeBackgroundColor` must exist. Add it if missing. The `re_editor` `CodeEditorStyle` and `CodeEditor` API — verify against the package version in `pubspec.yaml` if compile errors occur.

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/features/settings/widgets/mcp_server_editor_dialog.dart
```
Fix any API mismatches with `re_editor` based on the installed version.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/widgets/mcp_server_editor_dialog.dart
git commit -m "feat: add McpServerEditorDialog with form/JSON dual editor"
```

---

## Task 17: Full integration pass

- [ ] **Step 1: Run all tests**

```bash
flutter test
```
Expected: all pass. Fix any failures before continuing.

- [ ] **Step 2: Run analyze on the entire lib**

```bash
flutter analyze lib/
```
Expected: no issues.

- [ ] **Step 3: Run dart format**

```bash
dart format lib/ test/
```

- [ ] **Step 4: Re-run build_runner if any generated files are stale**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Commit all generated files and formatting**

```bash
git add -u
git commit -m "chore: format and regenerate all MCP-related generated files"
```

---

## Self-Review Checklist

Spec sections vs. plan coverage:

| Spec section | Covered in task |
|---|---|
| `mcp_servers` Drift table with all columns | Task 2 |
| `McpServerConfig` + `McpTransport` enum | Task 1 |
| `McpToolInfo` model | Task 1 |
| `McpConfigDatasourceDrift` CRUD | Task 3 |
| `McpRepository` interface + impl | Task 4 |
| `McpStdioDatasource` — JSON-RPC framing, command split | Task 5 |
| `McpHttpSseDatasource` — SSE + POST, 3 retries, 2s backoff | Task 6 |
| `McpClientSession` — initialize + tools/list + execute | Task 7 |
| `McpTool` — name `server/tool`, capability shell | Task 8 |
| `McpService` — per-session start/teardown, non-fatal errors | Task 11 |
| `AgentService` — McpService wiring, system prompt | Task 12 |
| `PermissionRequestPreview` — MCP JSON args block | Task 13 |
| `ToolCallRow` — `Icons.extension_outlined`, `server › tool` label | Task 13 |
| `McpServerStatusNotifier` + sealed status type | Task 9 |
| `McpServersFailure` sealed type | Task 9 |
| `McpServersNotifier` + `McpServersActions` | Task 10 |
| `McpServersScreen` + empty state | Task 14 |
| `McpServerCard` — status dot, badge, error inline | Task 15 |
| `McpServerEditorDialog` — form ↔ JSON, sanitization | Task 16 |
| Settings nav `mcpServers` entry | Task 14 |
| 30s init timeout, 120s tool-call timeout | Task 7 (McpClientSession.start + execute signatures) |
| `sLog` for security events (bad path, missing binary) | Task 5 + Task 11 |
| `pendingRemoval` status on deletion during active session | **Not yet covered** — see note below |

**Note on `pendingRemoval`:** The spec says config deletion is queued and `McpServerStatusNotifier` shows `pendingRemoval` if deletion is requested during an active session. `McpServersActions.remove` calls `repository.delete()` immediately. To implement the queue, `McpService` would need to expose a way to detect if a session is active. For v1, `McpServersActions.remove` sets status to `pendingRemoval` before deleting and the session teardown handles `unregister`. Implement this enhancement in `McpServersActions.remove`:

```dart
Future<void> remove(String id) async {
  // Mark as pending so UI shows queued state during active sessions
  ref.read(mcpServerStatusProvider.notifier).setStatus(
        id, const McpServerStatus.pendingRemoval());
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try {
      await ref.read(mcpRepositoryProvider).delete(id);
      ref.read(mcpServerStatusProvider.notifier).remove(id);
    } catch (e, st) {
      dLog('[McpServersActions] remove failed: $e');
      Error.throwWithStackTrace(McpServersFailure.removeError(e.toString()), st);
    }
  });
}
```

Add this to Task 10's `McpServersActions` implementation.
