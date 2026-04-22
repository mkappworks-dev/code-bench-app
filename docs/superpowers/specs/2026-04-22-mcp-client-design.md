# MCP Client Design — Phase 5

**Date:** 2026-04-22
**Status:** Approved — ready for implementation planning

---

## Overview

Add a Model Context Protocol (MCP) client to Code Bench so the agent can call tools provided by third-party MCP servers. MCP tools are first-class `Tool` subclasses registered into the existing `ToolRegistry` — from the agent loop's perspective they are indistinguishable from built-in tools.

---

## Settled Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Transports | stdio + HTTP/SSE | Matches Claude Code; covers local CLI servers and remote/cloud servers |
| Settings placement | New "MCP Servers" tab in Settings | Dedicated surface scales better than appending to Coding Tools or Integrations |
| Lifecycle | Session-scoped on-demand | Start on first session use, stop on session end — matches Claude Code behaviour |
| Add/edit UX | Form ↔ JSON dual editor | Both views stay in sync; JSON is blocked from switching if invalid |
| Permission gating | Always prompt (`ToolCapability.shell`) | MCP is third-party code; every call requires explicit user approval |
| Architecture | Session-scoped McpService (Approach A) | Clean per-session lifecycle; no cache invalidation complexity |

**Out of scope for this phase:** auth flows, resource subscriptions, sampling, WebSearch.

---

## Data Layer

### Drift table — `mcp_servers`

Stored in the existing SQLite database alongside sessions and projects.

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT PK | UUID |
| `name` | TEXT | User-chosen label (e.g. `github-tools`) |
| `transport` | TEXT | `stdio` or `http_sse` |
| `command` | TEXT nullable | stdio only — full command string as entered |
| `args` | TEXT | JSON array, default `[]` |
| `env` | TEXT | JSON object, default `{}` — stored in SQLite (not secure storage) for v1 |
| `url` | TEXT nullable | HTTP/SSE only |
| `enabled` | INTEGER | 1 = enabled, 0 = disabled |
| `sort_order` | INTEGER | Display order in the list |

`env` values (tokens etc.) live in SQLite for v1. Migrate to `flutter_secure_storage` if users request it.

### Domain model

```dart
// lib/data/mcp/models/mcp_server_config.dart
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
}

enum McpTransport { stdio, httpSse }
```

```dart
// lib/data/mcp/models/mcp_tool_info.dart
@freezed
abstract class McpToolInfo with _$McpToolInfo {
  const factory McpToolInfo({
    required String name,
    required String description,
    required Map<String, dynamic> inputSchema,
  }) = _McpToolInfo;
}
```

### Files

```
lib/data/mcp/
  models/
    mcp_server_config.dart          # freezed + McpTransport enum
    mcp_server_config.freezed.dart  # generated
    mcp_server_config.g.dart        # generated
    mcp_tool_info.dart              # freezed
    mcp_tool_info.freezed.dart      # generated
  datasource/
    mcp_config_datasource_drift.dart   # CRUD for mcp_servers table
    mcp_stdio_datasource_process.dart  # JSON-RPC over stdin/stdout
    mcp_http_sse_datasource_dio.dart   # JSON-RPC over HTTP/SSE
  repository/
    mcp_repository.dart             # interface
    mcp_repository_impl.dart        # impl + @riverpod
    mcp_repository_impl.g.dart      # generated
```

---

## Service Layer

### `McpClientSession`

Owns one live connection to a single MCP server. Created by `McpService` after a successful `initialize` + `tools/list` handshake.

```dart
// lib/services/mcp/mcp_client_session.dart
class McpClientSession {
  McpClientSession({required this.config, required this.tools, required McpTransportDatasource datasource});

  final McpServerConfig config;
  final List<McpToolInfo> tools;

  Future<String> execute(String toolName, Map<String, dynamic> args);
  Future<void> teardown();
}
```

### `McpService`

Instantiated per chat session (not `keepAlive`). Injected into `AgentService`.

Responsibilities:
- Iterates enabled `McpServerConfig` entries
- Starts each server via the appropriate datasource
- Calls `initialize` + `tools/list`; on failure logs via `dLog` and updates `McpServerStatusNotifier` to `error` — non-fatal, session continues
- Registers each discovered `McpTool` into `ToolRegistry` via `register()`
- Returns a teardown callback used in `AgentService`'s `try/finally`

Timeouts: 30 s for initialization, 120 s per tool call.

```dart
// lib/services/mcp/mcp_service.dart
@riverpod
McpService mcpService(Ref ref) => McpService(
  repository: ref.watch(mcpRepositoryProvider),
  statusNotifier: ref.watch(mcpServerStatusProvider.notifier),
);
```

### Datasources

**`McpStdioDatasource`** (`mcp_stdio_datasource_process.dart`):
- Spawns command via `Process.start` with `runInShell: false` (same pattern as `BashDatasourceProcess`)
- `command` string is split into executable + args via shell-word split before spawning
- JSON-RPC framing: `Content-Length: N\r\n\r\n{...}` over stdin/stdout
- Handles `initialize`, `tools/list`, `tools/call` requests

**`McpHttpSseDatasource`** (`mcp_http_sse_datasource_dio.dart`):
- Opens SSE stream via Dio to configured URL
- Sends JSON-RPC requests as HTTP POST; reads responses from SSE stream
- Reconnect on disconnect: up to 3 retries with 2 s backoff
- On final failure: marks session dead; subsequent `execute()` calls return `CodingToolResult.error('MCP server disconnected')`

---

## Tool Layer

### `McpTool`

```dart
// lib/services/mcp/mcp_tool.dart
class McpTool extends Tool {
  McpTool({required this.session, required McpToolInfo info});

  final McpClientSession session;
  final McpToolInfo _info;

  @override String get name => '${session.config.name}/${_info.name}';
  @override String get description => _info.description;
  @override Map<String, dynamic> get inputSchema => _info.inputSchema;
  @override ToolCapability get capability => ToolCapability.shell;
}
```

Name format: `server-name/tool-name` (slash separator). The registry uses this as the unique key. The UI converts `server/tool` → `server › tool` for display only.

### `PermissionRequestPreview` changes

Any tool name containing `/` is treated as an MCP call. Args are rendered as a `JsonEncoder.withIndent('  ')`-formatted block — always visible, no collapse. No bidi/ANSI sanitization needed (args come from the model, not user shell input).

### `ToolCallRow` changes

`_iconForTool`: any name containing `/` → `Icons.extension_outlined`.
Display label: `server › tool_name` (truncated to fit collapsed row).

### `AgentService` changes

`_kActSystemPrompt`: remove hardcoded tool name list. Replace with: *"You have access to the tools listed in the tools array. Use them as needed."* The model receives the live tool list via the `tools:` parameter on every turn.

`runAgenticTurn` wiring:

```dart
final teardown = await _mcpService.startSession(
  registry: _registry,
  sessionId: sessionId,
);
try {
  // existing while(true) loop
} finally {
  await teardown();
}
```

---

## Settings UI

### New nav entry

`_SettingsNav.mcpServers` added to `settings_screen.dart`. Nav label: **MCP Servers**. No "Restore defaults" action (no defaults to restore).

### `McpServersScreen`

Reads `AsyncValue<List<McpServerConfig>>` from `McpServersNotifier`. Server list renders `McpServerCard` per entry. Empty state: centred prompt with "+ Add your first MCP server" button.

### `McpServerCard`

Shows per the mockup:
- Status dot: green (running), grey (stopped), red (error)
- Server name + transport badge (`stdio` / `HTTP/SSE`)
- Command or URL in monospace
- Tool chips (from last known `McpClientSession`) when running; "Tools visible after first use" when stopped
- Actions: Edit · Stop (running only) · Remove. Error state: Edit · Remove + inline red error message.

### `McpServerEditorDialog`

Form ↔ JSON toggle in dialog header.

**Form view fields:**
- Name (text)
- Transport toggle: stdio | HTTP/SSE
- Command (stdio) or URL (HTTP/SSE)
- Env vars: key/value row list with × delete and "+ Add variable"

**JSON view:**
- `re_editor` widget (already in pubspec) — editable JSON of the draft config
- Live re-serialised from form on every field change
- On switch Form→JSON: re-serialise current draft
- On switch JSON→Form: parse; if invalid JSON, show inline error and block switch
- All string fields sanitized (strip bidi overrides, null bytes) before persisting

**Save path:** `McpServersActions.save(draft)` → `McpRepository.upsert(config)`.

### Notifiers

| Class | Type | Owns |
|---|---|---|
| `McpServersNotifier` | `AsyncNotifier<List<McpServerConfig>>` | Config list from DB |
| `McpServersActions` | `AsyncNotifier<void>` | `save`, `remove` |
| `McpServerStatusNotifier` | `StateNotifier<Map<String, McpServerStatus>>` | Runtime status (ephemeral) |

```dart
// lib/features/settings/notifiers/mcp_server_status_notifier.dart
@freezed
sealed class McpServerStatus with _$McpServerStatus {
  const factory McpServerStatus.stopped() = McpServerStopped;
  const factory McpServerStatus.starting() = McpServerStarting;
  const factory McpServerStatus.running() = McpServerRunning;
  const factory McpServerStatus.error(String message) = McpServerError;
  const factory McpServerStatus.pendingRemoval() = McpServerPendingRemoval;
}
```

### Files

```
lib/features/settings/
  mcp_servers_screen.dart
  widgets/
    mcp_server_card.dart
    mcp_server_editor_dialog.dart
  notifiers/
    mcp_servers_notifier.dart
    mcp_servers_actions.dart
    mcp_servers_failure.dart
    mcp_server_status_notifier.dart
    mcp_server_status_notifier.g.dart
```

---

## Error Handling

### `McpServersFailure`

```dart
@freezed
sealed class McpServersFailure with _$McpServersFailure {
  const factory McpServersFailure.saveError([String? detail]) = McpServersSaveError;
  const factory McpServersFailure.removeError([String? detail]) = McpServersRemoveError;
  const factory McpServersFailure.unknown(Object error) = McpServersUnknownError;
}
```

### Server startup errors

Non-fatal. `McpService.startSession` catches per-server failures, calls `sLog` for security events (bad path, missing binary), `dLog` for general failures, and updates `McpServerStatusNotifier` to `error(message)`. The session proceeds without that server's tools.

### Tool call errors

JSON-RPC error response → `CodingToolResult.error(message)`. Flows through the existing `AgentService` error path unchanged.

### Removal while session active

Config deletion is queued. The status notifier shows `pendingRemoval`. The actual DB delete and `ToolRegistry.unregister` happen after `teardown()` completes.

---

## Open Questions

None — all design questions resolved in this session.

---

## File Change Summary

**New files:**
- `lib/data/mcp/**` (models, datasources, repository)
- `lib/services/mcp/mcp_service.dart`
- `lib/services/mcp/mcp_client_session.dart`
- `lib/services/mcp/mcp_tool.dart`
- `lib/features/settings/mcp_servers_screen.dart`
- `lib/features/settings/widgets/mcp_server_card.dart`
- `lib/features/settings/widgets/mcp_server_editor_dialog.dart`
- `lib/features/settings/notifiers/mcp_servers_notifier.dart`
- `lib/features/settings/notifiers/mcp_servers_actions.dart`
- `lib/features/settings/notifiers/mcp_servers_failure.dart`
- `lib/features/settings/notifiers/mcp_server_status_notifier.dart`

**Modified files:**
- Existing Drift database class — add `mcp_servers` table declaration
- `lib/features/chat/utils/permission_request_preview.dart` (MCP case)
- `lib/features/chat/widgets/tool_call_row.dart` (MCP icon + label)
- `lib/services/agent/agent_service.dart` (McpService wiring, system prompt update)
- `lib/features/settings/settings_screen.dart` (new nav entry)
