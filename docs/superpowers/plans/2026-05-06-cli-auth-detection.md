# CLI Auth Detection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Distinguish "CLI installed" from "CLI authenticated" across the providers screen and chat input. Both Claude CLI and Codex CLI gain a real auth probe; the chat input proactively gates Send when the active transport is signed out, missing an API key, or not installed.

**Architecture:** A new `verifyAuth()` capability on `AIProviderDatasource` returns one of three `AuthStatus` cases. The service layer composes install + auth into a unified `ProviderEntry`. A new `transportReadinessProvider` derives a chat-input-facing readiness union from the active model + selected transport + provider entries. UI surfaces (provider cards, chat input bar) read the derived state and render two pills / a warning strip + CTA accordingly.

**Spec:** [docs/superpowers/specs/2026-05-06-cli-auth-detection-design.md](../specs/2026-05-06-cli-auth-detection-design.md)

**Tech Stack:** Flutter, Riverpod 2 (`@riverpod` codegen), `freezed` for sealed unions, `build_runner`, `flutter_test` + `ProviderContainer` for tests. No new dependencies. Reuses existing `IdeService.openInTerminal` for the open-in-terminal CTA.

**Spec deviation note:** The spec proposed putting `TransportReadiness` (the freezed sealed model) and `transportReadinessProvider` (the derived provider) in the same file under `lib/features/chat/notifiers/`. To respect the dependency rule (data → notifiers, not notifiers → data), the model lives in `lib/data/chat/models/transport_readiness.dart` and the provider stays in `lib/features/chat/notifiers/transport_readiness_notifier.dart`. The `AgentFailure.transportNotReady(TransportReadiness)` variant in `lib/data/chat/models/agent_failure.dart` then imports the model cleanly without a layer-skip.

---

## File Structure

### New files (8)

| Path | Responsibility |
|---|---|
| `lib/data/ai/models/auth_status.dart` | `AuthStatus` freezed sealed: `authenticated` / `unauthenticated(signInCommand, hint?)` / `unknown` |
| `lib/data/chat/models/transport_readiness.dart` | `TransportReadiness` freezed sealed: `ready` / `notInstalled(provider)` / `signedOut(provider, signInCommand)` / `httpKeyMissing(provider)` / `unknown` |
| `lib/features/chat/notifiers/transport_readiness_notifier.dart` | `transportReadinessProvider` (derived value provider) |
| `test/data/ai/models/auth_status_test.dart` | Exhaustive switch test for `AuthStatus` |
| `test/data/chat/models/transport_readiness_test.dart` | Exhaustive switch test for `TransportReadiness` |
| `test/data/ai/datasource/claude_cli_auth_test.dart` | Pure-parser tests for Claude auth output cases |
| `test/data/ai/datasource/codex_cli_auth_test.dart` | Pure-parser tests for Codex auth output cases |
| `test/features/chat/notifiers/transport_readiness_test.dart` | `transportReadinessProvider` resolution matrix |

### Modified files (10)

| Path | Change |
|---|---|
| `lib/core/constants/app_icons.dart` | Add `static const IconData terminal = LucideIcons.terminal;` |
| `lib/data/ai/datasource/ai_provider_datasource.dart` | Add `Future<AuthStatus> verifyAuth();` to the interface |
| `lib/data/ai/datasource/claude_cli_datasource_process.dart` | Implement `verifyAuth` via `claude auth status --json`; expose pure parser `parseClaudeAuthOutput(exitCode, stdout)` for tests |
| `lib/data/ai/datasource/codex_cli_datasource_process.dart` | Implement `verifyAuth` via `codex login status`; remove old `_checkAuth` invocation in `_send`; expose pure parser `parseCodexAuthOutput(exitCode, stdout)` for tests |
| `lib/data/chat/models/agent_failure.dart` | Add `AgentFailure.transportNotReady(TransportReadiness readiness)` variant |
| `lib/services/ai_provider/ai_provider_service.dart` | Extend `ProviderEntry` with `authStatus` field; add `getAuthStatus(id)`; `listWithStatus()` runs install + auth in parallel via `Future.wait` per provider (auth-probe skipped when install missing) |
| `lib/features/chat/notifiers/chat_notifier.dart` | Pre-send block in `ChatMessagesNotifier.sendMessage` (cache pre-flight + fresh CLI probe) returning `AgentFailure.transportNotReady` on not-ready states |
| `lib/features/chat/widgets/chat_input_bar.dart` | Watch `transportReadinessProvider`; render warning/error strip + dim Send when not `ready/unknown`; two CTA buttons (copy + open-in-terminal); add `AgentTransportNotReady` arm to existing send-error switch |
| `lib/features/providers/widgets/anthropic_provider_card.dart` | `_cliBadge()` returns `Widget` (was `CardStatusBadge`); render install pill + sibling `Signed out` pill via `Wrap` when `authStatus is AuthUnauthenticated` |
| `lib/features/providers/widgets/openai_provider_card.dart` | Same change for the Codex CLI sub-card |

`*.freezed.dart` and `*.g.dart` regenerated and committed alongside their sources per project convention.

---

## Tasks

### Task 1 — `AuthStatus` model

**Files:**
- Create: `lib/data/ai/models/auth_status.dart`
- Test: `test/data/ai/models/auth_status_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/ai/models/auth_status_test.dart
import 'package:code_bench_app/data/ai/models/auth_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exhaustive switch covers every variant', () {
    String label(AuthStatus s) => switch (s) {
      AuthAuthenticated() => 'authenticated',
      AuthUnauthenticated() => 'unauthenticated',
      AuthUnknown() => 'unknown',
    };

    expect(label(const AuthStatus.authenticated()), 'authenticated');
    expect(label(const AuthStatus.unauthenticated(signInCommand: 'foo login')), 'unauthenticated');
    expect(label(const AuthStatus.unknown()), 'unknown');
  });

  test('unauthenticated carries signInCommand and optional hint', () {
    const a = AuthStatus.unauthenticated(signInCommand: 'codex login');
    expect(a, isA<AuthUnauthenticated>());
    expect((a as AuthUnauthenticated).signInCommand, 'codex login');
    expect(a.hint, isNull);

    const b = AuthStatus.unauthenticated(signInCommand: 'claude auth login', hint: 'subscription required');
    expect((b as AuthUnauthenticated).hint, 'subscription required');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/ai/models/auth_status_test.dart`
Expected: compile error — `auth_status.dart` does not exist.

- [ ] **Step 3: Implement the model**

```dart
// lib/data/ai/models/auth_status.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_status.freezed.dart';

@freezed
sealed class AuthStatus with _$AuthStatus {
  const factory AuthStatus.authenticated() = AuthAuthenticated;
  const factory AuthStatus.unauthenticated({
    required String signInCommand,
    String? hint,
  }) = AuthUnauthenticated;
  const factory AuthStatus.unknown() = AuthUnknown;
}
```

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: writes `lib/data/ai/models/auth_status.freezed.dart`.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/data/ai/models/auth_status_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Format + analyze**

Run: `dart format lib/ test/ && flutter analyze`
Expected: no new issues.

- [ ] **Step 7: Commit**

```bash
git add lib/data/ai/models/auth_status.dart lib/data/ai/models/auth_status.freezed.dart test/data/ai/models/auth_status_test.dart
git commit -m "feat(ai-models): add AuthStatus sealed union

Models 'authenticated', 'unauthenticated' (with signInCommand + optional
hint), and 'unknown' as a real fallback for probe failures. First piece
of the cli-auth-detection design (see docs/superpowers/specs/2026-05-06-
cli-auth-detection-design.md)."
```

---

### Task 2 — `TransportReadiness` model

**Files:**
- Create: `lib/data/chat/models/transport_readiness.dart`
- Test: `test/data/chat/models/transport_readiness_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/chat/models/transport_readiness_test.dart
import 'package:code_bench_app/data/chat/models/transport_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exhaustive switch covers every variant', () {
    String label(TransportReadiness r) => switch (r) {
      TransportReady() => 'ready',
      TransportNotInstalled() => 'notInstalled',
      TransportSignedOut() => 'signedOut',
      TransportHttpKeyMissing() => 'httpKeyMissing',
      TransportUnknown() => 'unknown',
    };

    expect(label(const TransportReadiness.ready()), 'ready');
    expect(label(const TransportReadiness.notInstalled(provider: 'codex')), 'notInstalled');
    expect(
      label(const TransportReadiness.signedOut(provider: 'codex', signInCommand: 'codex login')),
      'signedOut',
    );
    expect(label(const TransportReadiness.httpKeyMissing(provider: 'anthropic')), 'httpKeyMissing');
    expect(label(const TransportReadiness.unknown()), 'unknown');
  });

  test('signedOut carries provider and signInCommand', () {
    const r = TransportReadiness.signedOut(provider: 'claude-cli', signInCommand: 'claude auth login');
    expect(r, isA<TransportSignedOut>());
    expect((r as TransportSignedOut).provider, 'claude-cli');
    expect(r.signInCommand, 'claude auth login');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/chat/models/transport_readiness_test.dart`
Expected: compile error — file does not exist.

- [ ] **Step 3: Implement the model**

```dart
// lib/data/chat/models/transport_readiness.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transport_readiness.freezed.dart';

@freezed
sealed class TransportReadiness with _$TransportReadiness {
  const factory TransportReadiness.ready() = TransportReady;
  const factory TransportReadiness.notInstalled({required String provider}) = TransportNotInstalled;
  const factory TransportReadiness.signedOut({
    required String provider,
    required String signInCommand,
  }) = TransportSignedOut;
  const factory TransportReadiness.httpKeyMissing({required String provider}) = TransportHttpKeyMissing;
  const factory TransportReadiness.unknown() = TransportUnknown;
}
```

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/data/chat/models/transport_readiness_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Format + analyze**

Run: `dart format lib/ test/ && flutter analyze`

- [ ] **Step 7: Commit**

```bash
git add lib/data/chat/models/transport_readiness.dart lib/data/chat/models/transport_readiness.freezed.dart test/data/chat/models/transport_readiness_test.dart
git commit -m "feat(chat-models): add TransportReadiness sealed union

Captures the five chat-input gating states: ready, notInstalled,
signedOut, httpKeyMissing, unknown. Lives in lib/data/chat/models/ so
both AgentFailure and the upcoming transportReadinessProvider can
import it without crossing layer boundaries."
```

---

### Task 3 — `AgentFailure.transportNotReady` variant

**Files:**
- Modify: `lib/data/chat/models/agent_failure.dart`
- Test: `test/data/chat/models/agent_failure_test.dart` (or extend existing failure test)

- [ ] **Step 1: Locate the existing failure file and any existing test**

Run: `ls lib/data/chat/models/agent_failure.dart && find test -name 'agent_failure_test.dart'`
Expected: source file exists; if no test file, create one.

- [ ] **Step 2: Write the failing test**

```dart
// test/data/chat/models/agent_failure_test.dart  (create if missing; extend if present)
import 'package:code_bench_app/data/chat/models/agent_failure.dart';
import 'package:code_bench_app/data/chat/models/transport_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exhaustive switch includes transportNotReady', () {
    String label(AgentFailure f) => switch (f) {
      AgentIterationCapReached() => 'iter',
      AgentProviderDoesNotSupportTools() => 'noTools',
      AgentStreamAbortedUnexpectedly() => 'abort',
      AgentToolDispatchFailed() => 'toolFail',
      AgentNetworkExhausted() => 'netExhaust',
      AgentTransportNotReady() => 'transport',
      AgentUnknownError() => 'unknown',
    };

    expect(
      label(AgentFailure.transportNotReady(const TransportReadiness.signedOut(
        provider: 'codex',
        signInCommand: 'codex login',
      ))),
      'transport',
    );
  });

  test('transportNotReady carries readiness', () {
    const readiness = TransportReadiness.signedOut(provider: 'codex', signInCommand: 'codex login');
    final f = AgentFailure.transportNotReady(readiness);
    expect((f as AgentTransportNotReady).readiness, readiness);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/data/chat/models/agent_failure_test.dart`
Expected: compile error — `transportNotReady` / `AgentTransportNotReady` not defined.

- [ ] **Step 4: Add the variant**

Add inside the existing sealed class in `lib/data/chat/models/agent_failure.dart`:

```dart
import 'transport_readiness.dart';
// (other existing imports)

@freezed
sealed class AgentFailure with _$AgentFailure {
  // ... existing variants ...
  const factory AgentFailure.transportNotReady(TransportReadiness readiness) = AgentTransportNotReady;
  // ... existing variants ...
}
```

Place the new variant alongside the others (preserving alphabetical or existing ordering — match what's there).

- [ ] **Step 5: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/data/chat/models/agent_failure_test.dart`
Expected: PASS.

- [ ] **Step 7: Format + analyze**

Run: `dart format lib/ test/ && flutter analyze`
Expected: any switch-on-AgentFailure call site that wasn't exhaustive will surface here. Defer fixing them — Tasks 8 and 12 update those call sites.

If analyze reports `non_exhaustive_switch` errors elsewhere, add a temporary `AgentTransportNotReady() => /* TODO Task 8/12 */` arm only where needed to keep `flutter analyze` clean. **No `AgentTransportNotReady` runtime path exists yet, so these arms are unreachable at runtime in this commit.**

- [ ] **Step 8: Commit**

```bash
git add lib/data/chat/models/agent_failure.dart lib/data/chat/models/agent_failure.freezed.dart test/data/chat/models/agent_failure_test.dart
git commit -m "feat(chat-models): add AgentFailure.transportNotReady(TransportReadiness)

Wraps the readiness directly so existing call sites can switch on it
without parallel sub-variants on the failure union. Pre-send probe
(coming in chat_notifier change) and chat_input_bar's send-error switch
(coming in UI tasks) will populate the new arm."
```

---

### Task 4 — `verifyAuth` interface + Claude CLI implementation

**Files:**
- Modify: `lib/data/ai/datasource/ai_provider_datasource.dart`
- Modify: `lib/data/ai/datasource/claude_cli_datasource_process.dart`
- Modify: `lib/data/ai/datasource/codex_cli_datasource_process.dart` (temporary stub returning `AuthStatus.unknown` — replaced in Task 5)
- Test: `test/data/ai/datasource/claude_cli_auth_test.dart`

- [ ] **Step 1: Add `verifyAuth` to the interface**

In `lib/data/ai/datasource/ai_provider_datasource.dart`, add:

```dart
import '../models/auth_status.dart';

abstract interface class AIProviderDatasource {
  // ... existing methods ...

  /// Probes whether the user is signed in to this provider's account.
  /// Returns `AuthStatus.unknown` for any failure that isn't a definitive
  /// signed-in / signed-out signal — never blocks send on a probe failure.
  Future<AuthStatus> verifyAuth();
}
```

- [ ] **Step 2: Stub the Codex implementation (temporary, replaced in Task 5)**

In `lib/data/ai/datasource/codex_cli_datasource_process.dart`, add at the end of the class body:

```dart
  // Replaced with real impl in Task 5; stubbed so the codebase compiles.
  @override
  Future<AuthStatus> verifyAuth() async => const AuthStatus.unknown();
```

Also add the import at the top:

```dart
import '../models/auth_status.dart';
```

- [ ] **Step 3: Write the failing Claude parser test**

```dart
// test/data/ai/datasource/claude_cli_auth_test.dart
import 'package:code_bench_app/data/ai/datasource/claude_cli_datasource_process.dart';
import 'package:code_bench_app/data/ai/models/auth_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseClaudeAuthOutput', () {
    test('exit 0 with loggedIn:true returns authenticated', () {
      final out = parseClaudeAuthOutput(0, '{"loggedIn":true,"email":"u@x.com"}');
      expect(out, const AuthStatus.authenticated());
    });

    test('exit 0 with loggedIn:false returns unauthenticated with claude auth login', () {
      final out = parseClaudeAuthOutput(0, '{"loggedIn":false}');
      expect(out, isA<AuthUnauthenticated>());
      expect((out as AuthUnauthenticated).signInCommand, 'claude auth login');
    });

    test('exit 0 with malformed JSON returns unknown', () {
      expect(parseClaudeAuthOutput(0, 'not json'), const AuthStatus.unknown());
    });

    test('exit 0 with JSON missing loggedIn returns unknown', () {
      expect(parseClaudeAuthOutput(0, '{"email":"u@x.com"}'), const AuthStatus.unknown());
    });

    test('non-zero exit returns unknown regardless of stdout', () {
      expect(parseClaudeAuthOutput(1, '{"loggedIn":true}'), const AuthStatus.unknown());
    });
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/data/ai/datasource/claude_cli_auth_test.dart`
Expected: compile error — `parseClaudeAuthOutput` is not defined.

- [ ] **Step 5: Implement the Claude parser + datasource method**

In `lib/data/ai/datasource/claude_cli_datasource_process.dart`, add at file scope (top-level, not inside the class):

```dart
import 'dart:convert';                       // already present? if so, skip
import '../models/auth_status.dart';

@visibleForTesting
AuthStatus parseClaudeAuthOutput(int exitCode, String stdout) {
  if (exitCode != 0) return const AuthStatus.unknown();
  try {
    final decoded = jsonDecode(stdout);
    if (decoded is! Map<String, dynamic>) return const AuthStatus.unknown();
    final loggedIn = decoded['loggedIn'];
    if (loggedIn == true) return const AuthStatus.authenticated();
    if (loggedIn == false) {
      return const AuthStatus.unauthenticated(signInCommand: 'claude auth login');
    }
    return const AuthStatus.unknown();
  } catch (_) {
    return const AuthStatus.unknown();
  }
}
```

(`@visibleForTesting` lives in `package:meta/meta.dart` — add the import if not already present.)

In the class body, add:

```dart
  @override
  Future<AuthStatus> verifyAuth() async {
    try {
      final exePath = _resolvedPath ?? binaryPath;
      final probeEnv = _shellPath != null ? {'PATH': _shellPath!} : null;
      final result = await Process.run(
        exePath,
        ['auth', 'status', '--json'],
        environment: probeEnv,
        includeParentEnvironment: probeEnv == null,
      ).timeout(const Duration(seconds: 5));
      return parseClaudeAuthOutput(result.exitCode, result.stdout as String);
    } catch (e) {
      sLog('[ClaudeCli] verifyAuth failed: ${e.runtimeType}');
      return const AuthStatus.unknown();
    }
  }
```

- [ ] **Step 6: Run codegen (interface change touches `@riverpod` codegen)**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 7: Run all tests and analyze**

Run: `flutter test test/data/ai/ && flutter analyze`
Expected: PASS (5 new parser tests). No new analyze issues.

- [ ] **Step 8: Format**

Run: `dart format lib/ test/`

- [ ] **Step 9: Commit**

```bash
git add lib/data/ai/datasource/ai_provider_datasource.dart lib/data/ai/datasource/claude_cli_datasource_process.dart lib/data/ai/datasource/codex_cli_datasource_process.dart test/data/ai/datasource/claude_cli_auth_test.dart lib/data/ai/datasource/*.g.dart
git commit -m "feat(ai-datasource): add verifyAuth capability + Claude CLI impl

Probes 'claude auth status --json' and parses the loggedIn field. A
pure parseClaudeAuthOutput helper is exposed via @visibleForTesting so
output cases can be tested without mocking Process.run. Codex stub
returns AuthStatus.unknown — replaced with real impl in next commit."
```

---

### Task 5 — Codex CLI `verifyAuth` (replace stub) + remove `_checkAuth` from `_send`

**Files:**
- Modify: `lib/data/ai/datasource/codex_cli_datasource_process.dart`
- Test: `test/data/ai/datasource/codex_cli_auth_test.dart`

- [ ] **Step 1: Write the failing parser test**

```dart
// test/data/ai/datasource/codex_cli_auth_test.dart
import 'package:code_bench_app/data/ai/datasource/codex_cli_datasource_process.dart';
import 'package:code_bench_app/data/ai/models/auth_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCodexAuthOutput', () {
    test('exit 0 with "Logged in using ChatGPT" returns authenticated', () {
      final out = parseCodexAuthOutput(0, 'Logged in using ChatGPT\n');
      expect(out, const AuthStatus.authenticated());
    });

    test('exit 0 with "Logged in using API key" returns authenticated', () {
      final out = parseCodexAuthOutput(0, 'Logged in using API key\n');
      expect(out, const AuthStatus.authenticated());
    });

    test('exit 0 with "Not logged in" returns unauthenticated with codex login', () {
      final out = parseCodexAuthOutput(0, 'Not logged in\n');
      expect(out, isA<AuthUnauthenticated>());
      expect((out as AuthUnauthenticated).signInCommand, 'codex login');
    });

    test('exit 0 with unrecognised stdout returns unknown', () {
      expect(parseCodexAuthOutput(0, 'something else\n'), const AuthStatus.unknown());
    });

    test('non-zero exit returns unknown', () {
      expect(parseCodexAuthOutput(1, ''), const AuthStatus.unknown());
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/ai/datasource/codex_cli_auth_test.dart`
Expected: compile error — `parseCodexAuthOutput` is not defined.

- [ ] **Step 3: Replace the stubbed Codex `verifyAuth` with the real impl**

In `lib/data/ai/datasource/codex_cli_datasource_process.dart`:

Add at file scope (top-level, alongside any other top-level helpers):

```dart
@visibleForTesting
AuthStatus parseCodexAuthOutput(int exitCode, String stdout) {
  if (exitCode != 0) return const AuthStatus.unknown();
  if (stdout.contains('Logged in')) return const AuthStatus.authenticated();
  if (stdout.contains('Not logged in')) {
    return const AuthStatus.unauthenticated(signInCommand: 'codex login');
  }
  return const AuthStatus.unknown();
}
```

Replace the stub with:

```dart
  @override
  Future<AuthStatus> verifyAuth() async {
    try {
      final exePath = _resolvedPath ?? binaryPath;
      final probeEnv = _shellPath != null ? {'PATH': _shellPath!} : null;
      final result = await Process.run(
        exePath,
        ['login', 'status'],
        environment: probeEnv,
        includeParentEnvironment: probeEnv == null,
      ).timeout(const Duration(seconds: 5));
      return parseCodexAuthOutput(result.exitCode, result.stdout as String);
    } catch (e) {
      sLog('[CodexCli] verifyAuth failed: ${e.runtimeType}');
      return const AuthStatus.unknown();
    }
  }
```

(Use the same `binaryPath` field name as the existing class uses — adjust if it's spelled differently in the actual file.)

- [ ] **Step 4: Remove the old `_checkAuth` invocation from `_send`**

Locate `_send` (around line 174) and remove the `_checkAuth` call. Locate `_checkAuth` itself (around line 616) and remove the entire method — its responsibility now lives in `verifyAuth`.

The `_send` block that previously read:

```dart
      // Initialize if this is a fresh process
      if (_version == null) {
        await _initialize();
        await _checkAuth();
      }
```

Becomes:

```dart
      // Initialize if this is a fresh process
      if (_version == null) {
        await _initialize();
      }
```

(Auth is now gated upstream in `ChatMessagesNotifier.sendMessage` — Task 8.)

- [ ] **Step 5: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6: Run all tests and analyze**

Run: `flutter test test/data/ai/ && flutter analyze`
Expected: PASS (5 new parser tests, all existing tests still pass). No new analyze issues.

- [ ] **Step 7: Format**

Run: `dart format lib/ test/`

- [ ] **Step 8: Commit**

```bash
git add lib/data/ai/datasource/codex_cli_datasource_process.dart test/data/ai/datasource/codex_cli_auth_test.dart
git commit -m "feat(codex-cli): real verifyAuth via 'codex login status'

Replaces the temporary stub from the previous commit and removes the
old _checkAuth probe inside _send (auth is now gated upstream in
ChatMessagesNotifier). Parser is pure and unit-tested over five cases
(authenticated/ChatGPT, authenticated/API key, not logged in, unknown
stdout, non-zero exit)."
```

---

### Task 6 — `AIProviderService`: parallel install + auth probes; `ProviderEntry.authStatus`

**Files:**
- Modify: `lib/services/ai_provider/ai_provider_service.dart`
- Test: `test/services/ai_provider/ai_provider_service_test.dart` (create if missing)

- [ ] **Step 1: Write the failing test**

```dart
// test/services/ai_provider/ai_provider_service_test.dart
import 'package:code_bench_app/data/ai/datasource/ai_provider_datasource.dart';
import 'package:code_bench_app/data/ai/models/auth_status.dart';
import 'package:code_bench_app/data/ai/models/detection_result.dart';
import 'package:code_bench_app/services/ai_provider/ai_provider_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDs implements AIProviderDatasource {
  _FakeDs({required this.detectResult, required this.authResult, required this.id, this.displayName = 'Fake'});
  final DetectionResult detectResult;
  final AuthStatus authResult;

  @override
  final String id;
  @override
  final String displayName;

  @override
  Future<DetectionResult> detect() async => detectResult;
  @override
  Future<AuthStatus> verifyAuth() async => authResult;

  // Other interface methods are unused in this test — throw to surface accidental calls.
  @override
  Stream sendAndStream({required String prompt, required String sessionId, required String workingDirectory}) =>
      throw UnimplementedError();
  @override
  void respondToPermissionRequest(String requestId, {required bool approved}) => throw UnimplementedError();
  @override
  void cancel() => throw UnimplementedError();
}

void main() {
  test('listWithStatus returns ProviderEntry with both install and auth status', () async {
    final container = ProviderContainer(
      overrides: [
        // Override the registry-building provider with our fakes.
        aIProviderServiceProvider.overrideWith(() => _AIProviderServiceUnderTest({
          'fake': _FakeDs(
            id: 'fake',
            detectResult: const DetectionResult.installed('1.0.0'),
            authResult: const AuthStatus.unauthenticated(signInCommand: 'fake login'),
          ),
        })),
      ],
    );
    addTearDown(container.dispose);

    final entries = await container.read(aIProviderServiceProvider.notifier).listWithStatus();
    expect(entries, hasLength(1));
    expect(entries.first.status, isA<ProviderAvailable>());
    expect(entries.first.authStatus, isA<AuthUnauthenticated>());
  });

  test('listWithStatus skips auth probe when install missing', () async {
    final fake = _FakeDs(
      id: 'gone',
      detectResult: const DetectionResult.missing(),
      authResult: const AuthStatus.unknown(),
    );
    final container = ProviderContainer(
      overrides: [
        aIProviderServiceProvider.overrideWith(() => _AIProviderServiceUnderTest({'gone': fake})),
      ],
    );
    addTearDown(container.dispose);

    var verifyAuthCalled = false;
    final spyDs = _SpyDs(fake, () => verifyAuthCalled = true);
    final spyContainer = ProviderContainer(
      overrides: [
        aIProviderServiceProvider.overrideWith(() => _AIProviderServiceUnderTest({'gone': spyDs})),
      ],
    );
    addTearDown(spyContainer.dispose);

    await spyContainer.read(aIProviderServiceProvider.notifier).listWithStatus();
    expect(verifyAuthCalled, isFalse, reason: 'auth probe should not run when install is missing');
  });
}

class _SpyDs implements AIProviderDatasource {
  _SpyDs(this._inner, this._onVerifyAuth);
  final _FakeDs _inner;
  final void Function() _onVerifyAuth;

  @override
  String get id => _inner.id;
  @override
  String get displayName => _inner.displayName;
  @override
  Future<DetectionResult> detect() => _inner.detect();
  @override
  Future<AuthStatus> verifyAuth() {
    _onVerifyAuth();
    return _inner.verifyAuth();
  }
  @override
  Stream sendAndStream({required String prompt, required String sessionId, required String workingDirectory}) =>
      throw UnimplementedError();
  @override
  void respondToPermissionRequest(String requestId, {required bool approved}) => throw UnimplementedError();
  @override
  void cancel() => throw UnimplementedError();
}

// Minimal subclass that lets us swap the registry map for the test.
class _AIProviderServiceUnderTest extends AIProviderService {
  _AIProviderServiceUnderTest(this._fakes);
  final Map<String, AIProviderDatasource> _fakes;
  @override
  Map<String, AIProviderDatasource> build() => _fakes;
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/ai_provider/ai_provider_service_test.dart`
Expected: compile errors — `entries.first.authStatus` not defined.

- [ ] **Step 3: Add `authStatus` to `ProviderEntry`; add `getAuthStatus`; parallelize `listWithStatus`**

In `lib/services/ai_provider/ai_provider_service.dart`:

Add the import:

```dart
import '../../data/ai/models/auth_status.dart';
```

Replace the `ProviderEntry` class:

```dart
class ProviderEntry {
  const ProviderEntry({
    required this.id,
    required this.displayName,
    required this.status,
    required this.authStatus,
  });

  final String id;
  final String displayName;
  final ProviderStatus status;
  final AuthStatus authStatus;

  bool get isAvailable => status is ProviderAvailable;
}
```

Add a `getAuthStatus` method on `AIProviderService`:

```dart
  Future<AuthStatus> getAuthStatus(String id) async {
    final provider = state[id];
    if (provider == null) return const AuthStatus.unknown();
    try {
      return await provider.verifyAuth();
    } on Exception catch (e) {
      dLog('[AIProviderService] verifyAuth($id) threw: $e');
      return const AuthStatus.unknown();
    }
  }
```

Rewrite `listWithStatus` to fan out per provider:

```dart
  Future<List<ProviderEntry>> listWithStatus() async {
    final futures = state.entries.map((entry) async {
      final id = entry.key;
      final ds = entry.value;
      final status = await getStatus(id);
      // Skip auth probe when install isn't available — auth is meaningless on a missing binary.
      final authStatus = status is ProviderAvailable
          ? await getAuthStatus(id)
          : const AuthStatus.unknown();
      return ProviderEntry(id: id, displayName: ds.displayName, status: status, authStatus: authStatus);
    });
    return Future.wait(futures);
  }
```

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/services/ai_provider/ai_provider_service_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Run full test suite + analyze**

Run: `flutter test && flutter analyze`
Expected: any provider-card test that constructs `ProviderEntry` directly will need the new `authStatus` field — fix call sites by passing `authStatus: const AuthStatus.unknown()`.

- [ ] **Step 7: Format**

Run: `dart format lib/ test/`

- [ ] **Step 8: Commit**

```bash
git add lib/services/ai_provider/ai_provider_service.dart test/services/ai_provider/ai_provider_service_test.dart lib/services/ai_provider/*.g.dart
git commit -m "feat(ai-provider-service): expose authStatus on ProviderEntry

listWithStatus now fans out install + auth probes per provider via
Future.wait. Auth probe is skipped when install is missing (auth is
meaningless without a binary). Pure provider-status getters split:
getStatus() for install, getAuthStatus() for auth — composed by
listWithStatus."
```

---

### Task 7 — `transportReadinessProvider`

**Files:**
- Create: `lib/features/chat/notifiers/transport_readiness_notifier.dart`
- Test: `test/features/chat/notifiers/transport_readiness_test.dart`

- [ ] **Step 1: Write the failing test**

The test uses `ProviderContainer` overrides plus a small fake-notifier pattern matching `test/features/chat/notifiers/chat_notifier_test.dart` (which uses `class _DisposalTestFakeApiKeysNotifier extends ApiKeysNotifier { @override Future<ApiKeysNotifierState> build() async => const ApiKeysNotifierState(...); }`).

```dart
// test/features/chat/notifiers/transport_readiness_test.dart
import 'package:code_bench_app/data/ai/models/auth_status.dart';
import 'package:code_bench_app/data/chat/models/transport_readiness.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/chat/notifiers/transport_readiness_notifier.dart';
import 'package:code_bench_app/features/providers/notifiers/ai_provider_status_notifier.dart';
import 'package:code_bench_app/features/providers/notifiers/providers_notifier.dart';
import 'package:code_bench_app/services/ai_provider/ai_provider_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiKeys extends ApiKeysNotifier {
  _FakeApiKeys(this._state);
  final ApiKeysNotifierState _state;
  @override
  Future<ApiKeysNotifierState> build() async => _state;
}

class _FakeStatus extends AiProviderStatusNotifier {
  _FakeStatus(this._entries);
  final AsyncValue<List<ProviderEntry>> _entries;
  @override
  Future<List<ProviderEntry>> build() async => _entries.valueOrNull ?? const [];
  // For loading-state tests, override _entries to AsyncLoading and use a different fake.
}

class _FakeStatusLoading extends AiProviderStatusNotifier {
  @override
  Future<List<ProviderEntry>> build() async {
    final c = Completer<List<ProviderEntry>>();
    return c.future; // never completes — leaves provider in AsyncLoading
  }
}

ProviderEntry _entry({
  required String id,
  ProviderStatus? status,
  AuthStatus? authStatus,
}) => ProviderEntry(
  id: id,
  displayName: id,
  status: status ?? ProviderStatus.available(version: '1', checkedAt: DateTime(2026)),
  authStatus: authStatus ?? const AuthStatus.authenticated(),
);

ProviderContainer _container({
  required AIModel model,
  required ApiKeysNotifierState prefs,
  required AsyncValue<List<ProviderEntry>> entries,
}) {
  return ProviderContainer(
    overrides: [
      selectedModelProvider.overrideWith(() {
        final n = SelectedModelNotifier();
        // riverpod 2 build() runs lazily; we set initial state via factory below
        return n..select(model);
      }),
      apiKeysProvider.overrideWith(() => _FakeApiKeys(prefs)),
      if (entries is AsyncLoading)
        aiProviderStatusProvider.overrideWith(() => _FakeStatusLoading())
      else
        aiProviderStatusProvider.overrideWith(() => _FakeStatus(entries)),
    ],
  );
}

const _httpPrefs = ApiKeysNotifierState(
  openai: 'sk-x', anthropic: 'sk-y', gemini: 'g-z',
  ollamaUrl: '', customEndpoint: '', customApiKey: '',
  anthropicTransport: 'api-key', openaiTransport: 'api-key',
);
const _emptyPrefs = ApiKeysNotifierState(
  openai: '', anthropic: '', gemini: '',
  ollamaUrl: '', customEndpoint: '', customApiKey: '',
  anthropicTransport: 'api-key', openaiTransport: 'api-key',
);
const _claudeCliPrefs = ApiKeysNotifierState(
  openai: '', anthropic: '', gemini: '',
  ollamaUrl: '', customEndpoint: '', customApiKey: '',
  anthropicTransport: 'cli', openaiTransport: 'api-key',
);
const _codexCliPrefs = ApiKeysNotifierState(
  openai: '', anthropic: '', gemini: '',
  ollamaUrl: '', customEndpoint: '', customApiKey: '',
  anthropicTransport: 'api-key', openaiTransport: 'cli',
);

void main() {
  test('CLI install ok + authenticated → ready', () {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _claudeCliPrefs,
      entries: AsyncData([_entry(id: 'claude-cli', authStatus: const AuthStatus.authenticated())]),
    );
    addTearDown(c.dispose);
    expect(c.read(transportReadinessProvider), const TransportReadiness.ready());
  });

  test('CLI install ok + unauthenticated → signedOut(provider, signInCommand)', () {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _claudeCliPrefs,
      entries: AsyncData([_entry(
        id: 'claude-cli',
        authStatus: const AuthStatus.unauthenticated(signInCommand: 'claude auth login'),
      )]),
    );
    addTearDown(c.dispose);
    final r = c.read(transportReadinessProvider);
    expect(r, isA<TransportSignedOut>());
    expect((r as TransportSignedOut).provider, 'claude-cli');
    expect(r.signInCommand, 'claude auth login');
  });

  test('CLI install missing → notInstalled(provider)', () {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _claudeCliPrefs,
      entries: AsyncData([_entry(
        id: 'claude-cli',
        status: const ProviderStatus.unavailable(reason: 'gone', reasonKind: ProviderUnavailableReason.missing),
      )]),
    );
    addTearDown(c.dispose);
    final r = c.read(transportReadinessProvider);
    expect(r, isA<TransportNotInstalled>());
    expect((r as TransportNotInstalled).provider, 'claude-cli');
  });

  test('CLI auth unknown → ready (honest bias)', () {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _claudeCliPrefs,
      entries: AsyncData([_entry(id: 'claude-cli', authStatus: const AuthStatus.unknown())]),
    );
    addTearDown(c.dispose);
    expect(c.read(transportReadinessProvider), const TransportReadiness.ready());
  });

  test('AsyncLoading providerEntries → unknown', () {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _claudeCliPrefs,
      entries: const AsyncLoading(),
    );
    addTearDown(c.dispose);
    expect(c.read(transportReadinessProvider), const TransportReadiness.unknown());
  });

  test('HTTP transport, key configured → ready', () {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _httpPrefs,
      entries: const AsyncData(<ProviderEntry>[]),
    );
    addTearDown(c.dispose);
    expect(c.read(transportReadinessProvider), const TransportReadiness.ready());
  });

  test('HTTP transport, key empty → httpKeyMissing(provider)', () {
    final c = _container(
      model: AIModels.claude35Sonnet,
      prefs: _emptyPrefs,
      entries: const AsyncData(<ProviderEntry>[]),
    );
    addTearDown(c.dispose);
    final r = c.read(transportReadinessProvider);
    expect(r, isA<TransportHttpKeyMissing>());
    expect((r as TransportHttpKeyMissing).provider, 'anthropic');
  });
}
```

The exact field names on `ApiKeysNotifierState` (`openai`, `anthropic`, `gemini`, `anthropicTransport`, `openaiTransport`) come from the existing `ApiKeysNotifierState` in `lib/features/providers/notifiers/providers_notifier.dart`. If the class has different field names in your branch, adjust the test fixtures to match — the *intent* is what matters: a CLI transport selected, with the matching `ProviderEntry` in `aiProviderStatusProvider`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/chat/notifiers/transport_readiness_test.dart`
Expected: compile error — `transportReadinessProvider` not defined.

- [ ] **Step 3: Implement the provider**

```dart
// lib/features/chat/notifiers/transport_readiness_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/models/auth_status.dart';
import '../../../data/chat/models/transport_readiness.dart';
import '../../../data/shared/ai_model.dart';
import '../../providers/notifiers/ai_provider_status_notifier.dart';
import '../../providers/notifiers/api_keys_notifier.dart' show apiKeysProvider, ApiKeysNotifierState;
import '../../../services/ai_provider/ai_provider_service.dart';
import 'chat_notifier.dart' show selectedModelProvider;

part 'transport_readiness_notifier.g.dart';

@riverpod
TransportReadiness transportReadiness(Ref ref) {
  final model = ref.watch(selectedModelProvider);
  final prefsAsync = ref.watch(apiKeysProvider);
  final entriesAsync = ref.watch(aiProviderStatusProvider);

  // Wait for both prefs and entries before deciding.
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) return const TransportReadiness.unknown();

  final providerId = _resolveProviderId(model, prefs);
  if (providerId == null) {
    // HTTP transport — readiness is fully determined by apiKeysProvider.
    return _httpReadiness(model.provider, prefs);
  }

  // CLI transport.
  final entries = entriesAsync.valueOrNull;
  if (entries == null) return const TransportReadiness.unknown();
  final entry = entries.firstWhere(
    (e) => e.id == providerId,
    orElse: () => ProviderEntry(
      id: providerId,
      displayName: providerId,
      status: const ProviderStatus.unavailable(reason: 'not registered', reasonKind: ProviderUnavailableReason.notRegistered),
      authStatus: const AuthStatus.unknown(),
    ),
  );

  if (entry.status is! ProviderAvailable) {
    return TransportReadiness.notInstalled(provider: providerId);
  }
  return switch (entry.authStatus) {
    AuthAuthenticated() => const TransportReadiness.ready(),
    AuthUnauthenticated(:final signInCommand) =>
      TransportReadiness.signedOut(provider: providerId, signInCommand: signInCommand),
    AuthUnknown() => const TransportReadiness.ready(), // honest bias
  };
}

String? _resolveProviderId(AIModel model, ApiKeysNotifierState prefs) {
  // Mirror the helper in chat_notifier.dart — keep the two in sync.
  return switch ((model.provider, prefs)) {
    (AIProvider.anthropic, ApiKeysNotifierState(anthropicTransport: 'cli')) => 'claude-cli',
    (AIProvider.openai, ApiKeysNotifierState(openaiTransport: 'cli')) => 'codex',
    _ => null,
  };
}

TransportReadiness _httpReadiness(AIProvider provider, ApiKeysNotifierState prefs) {
  // Map provider → (savedVerified or savedUnverified) → Ready, else HttpKeyMissing.
  // Use the same "saved + non-empty" heuristic that the providers cards already use
  // (see anthropic_provider_card._dotStatus / openai_provider_card._dotStatus).
  final keyConfigured = switch (provider) {
    AIProvider.anthropic => (prefs.anthropicApiKey ?? '').isNotEmpty,
    AIProvider.openai => (prefs.openaiApiKey ?? '').isNotEmpty,
    AIProvider.gemini => (prefs.geminiApiKey ?? '').isNotEmpty,
    AIProvider.ollama => (prefs.ollamaUrl ?? '').isNotEmpty,
    AIProvider.custom => (prefs.customApiKey ?? '').isNotEmpty && (prefs.customApiUrl ?? '').isNotEmpty,
  };
  return keyConfigured
      ? const TransportReadiness.ready()
      : TransportReadiness.httpKeyMissing(provider: _providerLabel(provider));
}

String _providerLabel(AIProvider p) => switch (p) {
  AIProvider.anthropic => 'anthropic',
  AIProvider.openai => 'openai',
  AIProvider.gemini => 'gemini',
  AIProvider.ollama => 'ollama',
  AIProvider.custom => 'custom',
};
```

(If field names like `anthropicApiKey` / `openaiTransport` differ in the real codebase, adjust to match. Use the existing `_resolveProviderId` from `chat_notifier.dart` as the source of truth.)

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Fill in the test bodies and run**

Wire up the test fixtures using existing patterns. Run: `flutter test test/features/chat/notifiers/transport_readiness_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 6: Format + analyze**

Run: `dart format lib/ test/ && flutter analyze`

- [ ] **Step 7: Commit**

```bash
git add lib/features/chat/notifiers/transport_readiness_notifier.dart lib/features/chat/notifiers/transport_readiness_notifier.g.dart test/features/chat/notifiers/transport_readiness_test.dart
git commit -m "feat(chat-notifier): transportReadinessProvider derived state

Composes selectedModelProvider + apiKeysProvider + aiProviderStatus
into a single TransportReadiness value the chat input bar reads to
gate Send. CLI auth=unknown maps to Ready (honest bias — never block on
probe failure)."
```

---

### Task 8 — Pre-send probe in `ChatMessagesNotifier.sendMessage`

**Files:**
- Modify: `lib/features/chat/notifiers/chat_notifier.dart`
- Test: extend `test/features/chat/notifiers/chat_notifier_test.dart`

- [ ] **Step 1: Write the failing test**

In `test/features/chat/notifiers/chat_notifier_test.dart`, add:

```dart
test('sendMessage returns AgentTransportNotReady when readiness is signedOut', () async {
  // Build a container with transportReadinessProvider overridden to signedOut.
  final container = ProviderContainer(
    overrides: [
      transportReadinessProvider.overrideWithValue(
        const TransportReadiness.signedOut(provider: 'codex', signInCommand: 'codex login'),
      ),
      // ... other overrides matching the existing chat_notifier_test setup ...
    ],
  );
  addTearDown(container.dispose);

  // ... seed activeSessionIdProvider, sessionServiceProvider with a fake, etc. ...

  final notifier = container.read(chatMessagesProvider('s').notifier);
  final result = await notifier.sendMessage('hi');
  expect(result, isA<AgentTransportNotReady>());
  expect(((result as AgentTransportNotReady).readiness as TransportSignedOut).provider, 'codex');
});

test('sendMessage proceeds when readiness is unknown', () async {
  // Override readiness with TransportUnknown — sendMessage must NOT short-circuit.
  // Use a fake registry that records whether registry.start was called.
  // ...
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/chat/notifiers/chat_notifier_test.dart -p "sendMessage returns AgentTransportNotReady"`
Expected: FAIL — `sendMessage` doesn't return that variant yet.

- [ ] **Step 3: Add the pre-send block to `sendMessage`**

In `lib/features/chat/notifiers/chat_notifier.dart`, inside `ChatMessagesNotifier.sendMessage`, immediately after the existing `final providerId = _resolveProviderId(model, prefs);` line, add:

```dart
    // Pre-flight against derived readiness — belt+suspenders for paths that
    // bypass the input bar (e.g. continueAgenticTurn).
    final readiness = ref.read(transportReadinessProvider);
    if (readiness is! TransportReady && readiness is! TransportUnknown) {
      _sendInProgress = false;
      return AgentFailure.transportNotReady(readiness);
    }

    // Fresh CLI auth re-probe — picks up state changes since last cache.
    if (providerId != null) {
      final ds = ref.read(aIProviderServiceProvider.notifier).getProvider(providerId);
      if (ds != null) {
        final freshAuth = await ds.verifyAuth();
        if (freshAuth is AuthUnauthenticated) {
          _sendInProgress = false;
          return AgentFailure.transportNotReady(
            TransportReadiness.signedOut(
              provider: providerId,
              signInCommand: freshAuth.signInCommand,
            ),
          );
        }
      }
    }
```

Add the imports at the top of the file:

```dart
import '../../../data/ai/models/auth_status.dart';
import '../../../data/chat/models/transport_readiness.dart';
import 'transport_readiness_notifier.dart';
```

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run the test**

Run: `flutter test test/features/chat/notifiers/chat_notifier_test.dart`
Expected: PASS (new tests + all existing).

- [ ] **Step 6: Run full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: PASS, no new analyze issues.

- [ ] **Step 7: Format + commit**

```bash
dart format lib/ test/
git add lib/features/chat/notifiers/chat_notifier.dart test/features/chat/notifiers/chat_notifier_test.dart
git commit -m "feat(chat-notifier): pre-send transport readiness gate

sendMessage now returns AgentFailure.transportNotReady before spawning
the stream when readiness is anything other than ready/unknown, plus
runs a fresh CLI verifyAuth() to catch externally-changed auth state
between session activation and Send."
```

---

### Task 9 — `AppIcons.terminal` constant

**Files:**
- Modify: `lib/core/constants/app_icons.dart`

- [ ] **Step 1: Open `lib/core/constants/app_icons.dart` and locate the icon list (alphabetical or grouped — match the existing convention)**

- [ ] **Step 2: Add the entry**

```dart
  static const IconData terminal = LucideIcons.terminal;
```

Place it in alphabetical position (between e.g. `static const IconData stop = ...;` and `static const IconData x = ...;` if those exist nearby).

- [ ] **Step 3: Verify with analyze**

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/app_icons.dart
git commit -m "chore(icons): add AppIcons.terminal

Wraps LucideIcons.terminal for the chat input strip's open-in-terminal
CTA button."
```

---

### Task 10 — Two-pill state in `anthropic_provider_card.dart`

**Files:**
- Modify: `lib/features/providers/widgets/anthropic_provider_card.dart`

- [ ] **Step 1: Locate `_cliBadge` (around line 202)**

Current shape:
```dart
CardStatusBadge _cliBadge({required bool selected}) {
  // returns single CardStatusBadge
}
```

- [ ] **Step 2: Change return type to `Widget` and render two pills via `Wrap`**

Replace `_cliBadge` with:

```dart
Widget _cliBadge({required bool selected}) {
  final entry = _cliEntry();
  final loading = ref.watch(aiProviderStatusProvider) is AsyncLoading;
  if (loading) return const CardStatusBadge(label: 'Checking…', tone: TransportBadgeTone.muted);
  final status = entry?.status;
  final installPill = switch (status) {
    ProviderAvailable(:final version) => CardStatusBadge(
      label: 'Installed · $version',
      tone: TransportBadgeTone.success,
    ),
    ProviderUnavailable() => selected
        ? const CardStatusBadge(label: 'Active · Not installed', tone: TransportBadgeTone.error)
        : const CardStatusBadge(label: 'Not installed', tone: TransportBadgeTone.muted),
    null => const CardStatusBadge(label: 'Not installed', tone: TransportBadgeTone.muted),
  };
  // Auth pill only renders alongside an Available install + an unauthenticated state.
  // Authenticated and Unknown both leave the auth pill off (honest bias).
  if (status is ProviderAvailable && entry?.authStatus is AuthUnauthenticated) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        installPill,
        const CardStatusBadge(label: 'Signed out', tone: TransportBadgeTone.warning),
      ],
    );
  }
  return installPill;
}
```

Add the import:

```dart
import '../../../data/ai/models/auth_status.dart';
```

- [ ] **Step 3: Update any caller site that expected `CardStatusBadge` specifically (rather than `Widget`)**

Most likely the badge is just embedded into a layout. If anything fails to compile, fix the caller to accept `Widget`.

- [ ] **Step 4: Run analyze + flutter test**

Run: `flutter analyze && flutter test test/features/providers/`
Expected: PASS.

- [ ] **Step 5: Smoke test in DevTools (manual)**

Run: `flutter run -d macos`
Open the providers screen → Anthropic card → Claude CLI sub-card. Verify:
- When signed in: single "Installed · v$VER" pill (success).
- When signed out: two pills wrapped right-aligned.
- When binary missing: single "Not installed" pill (no auth pill).

(If a real signed-out state isn't easily reproducible, temporarily override `aiProviderStatusProvider` in dev to force the unauthenticated case.)

- [ ] **Step 6: Format + commit**

```bash
dart format lib/
git add lib/features/providers/widgets/anthropic_provider_card.dart
git commit -m "feat(providers): two-pill state on Anthropic Claude CLI card

Renders a 'Signed out' warning pill alongside the existing 'Installed'
pill when authStatus is unauthenticated. Authenticated and unknown
states keep the existing single-pill rendering (honest bias — don't
imply signed-in/out when we don't know)."
```

---

### Task 11 — Two-pill state in `openai_provider_card.dart`

**Files:**
- Modify: `lib/features/providers/widgets/openai_provider_card.dart`

- [ ] **Step 1: Locate `_cliBadge` (around line 200)**

- [ ] **Step 2: Apply the same change as Task 10**

Replace `_cliBadge` with the same shape, swapping any name differences (e.g., the static `_providerId = 'codex'` instead of `'claude-cli'`):

```dart
Widget _cliBadge({required bool selected}) {
  final entry = _cliEntry();
  final loading = ref.watch(aiProviderStatusProvider) is AsyncLoading;
  if (loading) return const CardStatusBadge(label: 'Checking…', tone: TransportBadgeTone.muted);
  final status = entry?.status;
  final installPill = switch (status) {
    ProviderAvailable(:final version) => CardStatusBadge(
      label: 'Installed · $version',
      tone: TransportBadgeTone.success,
    ),
    ProviderUnavailable() => selected
        ? const CardStatusBadge(label: 'Active · Not installed', tone: TransportBadgeTone.error)
        : const CardStatusBadge(label: 'Not installed', tone: TransportBadgeTone.muted),
    null => const CardStatusBadge(label: 'Not installed', tone: TransportBadgeTone.muted),
  };
  if (status is ProviderAvailable && entry?.authStatus is AuthUnauthenticated) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        installPill,
        const CardStatusBadge(label: 'Signed out', tone: TransportBadgeTone.warning),
      ],
    );
  }
  return installPill;
}
```

Add the same import.

- [ ] **Step 3: Run analyze + tests**

Run: `flutter analyze && flutter test test/features/providers/`
Expected: PASS.

- [ ] **Step 4: Manual smoke test (Codex card)**

Same as Task 10 step 5 but on the OpenAI card → Codex CLI sub-card.

- [ ] **Step 5: Format + commit**

```bash
dart format lib/
git add lib/features/providers/widgets/openai_provider_card.dart
git commit -m "feat(providers): two-pill state on OpenAI Codex CLI card

Mirror of the Claude CLI change — 'Signed out' warning pill renders
alongside 'Installed · v$VER' when authStatus is unauthenticated."
```

---

### Task 12 — Chat input bar: warning strip, dimmed Send, two CTA buttons, send-error switch arm

**Files:**
- Modify: `lib/features/chat/widgets/chat_input_bar.dart`

This task is the most involved. Break it into discrete steps:

- [ ] **Step 1: Watch `transportReadinessProvider` in `build`**

Add the import:

```dart
import '../../../data/chat/models/transport_readiness.dart';
import '../notifiers/transport_readiness_notifier.dart';
```

In the widget's `build` method, near the top:

```dart
final readiness = ref.watch(transportReadinessProvider);
final notReady = readiness is! TransportReady && readiness is! TransportUnknown;
```

- [ ] **Step 2: Render the strip when `notReady`**

Above the existing input bar's outer container, wrap the input + strip in a single `Column` so they share rounded edges. Strip widget:

```dart
Widget _buildReadinessStrip(BuildContext context, TransportReadiness r) {
  final c = AppColors.of(context);
  final (label, command, tone) = switch (r) {
    TransportSignedOut(:final provider, :final signInCommand) =>
      (_signedOutLabel(provider), signInCommand, _StripTone.warning),
    TransportNotInstalled(:final provider) =>
      ('${_providerName(provider)} CLI isn\'t installed.', null, _StripTone.error),
    TransportHttpKeyMissing(:final provider) =>
      ('${_providerName(provider)} API key not configured.', null, _StripTone.error),
    TransportReady() || TransportUnknown() => ('', null, _StripTone.warning), // unreachable; guarded by caller
  };
  final bg = tone == _StripTone.warning ? c.warningTintBg : c.errorTintBg;
  final fg = tone == _StripTone.warning ? c.warning : c.error;
  return Semantics(
    liveRegion: true,
    container: true,
    child: Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: fg.withValues(alpha: 0.5)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: fg),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: TextStyle(color: fg, fontSize: 12))),
          if (command != null) ...[
            const SizedBox(width: 8),
            _IconButton(
              tooltip: 'Copy command',
              icon: AppIcons.copy,
              tone: fg,
              onPressed: () => _copyCommand(context, command),
            ),
            const SizedBox(width: 4),
            _IconButton(
              tooltip: 'Copy + open in your terminal app',
              icon: AppIcons.terminal,
              tone: fg,
              onPressed: () => _copyAndOpenTerminal(context, command),
            ),
          ] else ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _openProvidersScreen(context),
              child: const Text('Open providers screen'),
            ),
          ],
        ],
      ),
    ),
  );
}

enum _StripTone { warning, error }

String _signedOutLabel(String provider) => switch (provider) {
  'claude-cli' => 'Claude isn\'t signed in — run claude auth login',
  'codex' => 'Codex isn\'t signed in — run codex login',
  _ => '$provider isn\'t signed in',
};

String _providerName(String id) => switch (id) {
  'claude-cli' => 'Claude',
  'codex' => 'Codex',
  _ => id,
};
```

- [ ] **Step 3: Implement `_copyCommand` and `_copyAndOpenTerminal`**

```dart
Future<void> _copyCommand(BuildContext context, String command) async {
  try {
    await Clipboard.setData(ClipboardData(text: command));
  } catch (e) {
    dLog('[chat_input_bar] clipboard write failed: $e');
  }
  if (!context.mounted) return;
  AppSnackBar.show(context, '"$command" copied — paste in your terminal',
      type: AppSnackBarType.success);
}

Future<void> _copyAndOpenTerminal(BuildContext context, String command) async {
  try {
    await Clipboard.setData(ClipboardData(text: command));
  } catch (e) {
    dLog('[chat_input_bar] clipboard write failed: $e');
  }
  final project = ref.read(activeProjectProvider);
  if (project == null) {
    if (context.mounted) {
      AppSnackBar.show(context, 'No active project — paste in your terminal manually.',
          type: AppSnackBarType.warning);
    }
    return;
  }
  await ref.read(ideLaunchActionsProvider.notifier).openInTerminal(project.path);
  if (!context.mounted) return;
  // ideLaunchActions surfaces its own errors via state.error; check for it.
  final err = ref.read(ideLaunchActionsProvider).error;
  if (err != null) {
    AppSnackBar.show(context, '$err', type: AppSnackBarType.error);
  } else {
    AppSnackBar.show(context, 'Opened terminal — paste to sign in',
        type: AppSnackBarType.success);
  }
}
```

(`_openProvidersScreen` reuses whatever existing nav helper the app uses to push the providers screen — match the call style used elsewhere when navigating from chat.)

- [ ] **Step 4: Add the `_IconButton` helper**

```dart
class _IconButton extends StatelessWidget {
  const _IconButton({required this.tooltip, required this.icon, required this.tone, required this.onPressed});
  final String tooltip;
  final IconData icon;
  final Color tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 28, height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: tone.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, size: 14, color: tone),
      ),
    ),
  );
}
```

- [ ] **Step 5: Wire the strip into the existing input bar layout**

The current `build` method (around line 448) returns a `Container` at line 492 that wraps an inner `Container` (line 495) containing a `Column` (line 507) that holds the input row and any other vertical children. Insert the strip as the first child of that `Column`, conditional on `notReady`:

```dart
// Inside the Column children list at ~line 507:
children: [
  if (notReady) _buildReadinessStrip(context, readiness),
  // ... existing children unchanged ...
],
```

The inner `Container` (line 495) currently has `BorderRadius.circular(...)`. When `notReady`, switch it to `BorderRadius.only(bottomLeft: ..., bottomRight: ...)` so the strip's rounded top + the input bar's rounded bottom read as one container:

```dart
// existing styled inner container
Container(
  decoration: BoxDecoration(
    border: ...,
    borderRadius: notReady
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          )
        : BorderRadius.circular(8), // existing radius value
    color: ...,
  ),
  child: Column(...),
),
```

(Use whatever radius value the existing code already uses — keep the same numeric.)

In the existing input row, when `notReady`:
- Disable the Send button by passing `onPressed: null` or whatever boolean drives the existing `disabled` look. Find the button construction (one of the inner `Row`s at line 541/613/651) and condition its `onPressed` on `!notReady`.
- Change the placeholder text *only if the controller is empty* — keep non-empty drafts intact.
- Keep the `TextField` editable (do not set `enabled: false`).
- Add a `Tooltip` on the Send button: `notReady ? 'Sign in to send' : null`.

- [ ] **Step 6: Add the `AgentTransportNotReady` arm to the existing send-error switch**

Locate the `switch (sendError)` block (around line 220) and add:

```dart
case AgentTransportNotReady(:final readiness):
  // The strip is the primary surface; this passive snackbar is a fallback
  // for paths that bypass the strip (continueAgenticTurn etc.).
  showErrorSnackBar(context, _readinessSnackbarText(readiness));
```

Plus a helper:

```dart
String _readinessSnackbarText(TransportReadiness r) => switch (r) {
  TransportSignedOut(:final provider, :final signInCommand) =>
    '${_providerName(provider)} isn\'t signed in — run $signInCommand',
  TransportNotInstalled(:final provider) => '${_providerName(provider)} CLI isn\'t installed.',
  TransportHttpKeyMissing(:final provider) => '${_providerName(provider)} API key not configured.',
  TransportReady() || TransportUnknown() => 'Transport not ready.',
};
```

- [ ] **Step 7: Verify exhaustive switches still compile**

Run: `flutter analyze`
Expected: any other call site that switches on `AgentFailure` now exhaustively matches `AgentTransportNotReady` — fix by adding a no-op arm or matching the appropriate behaviour.

- [ ] **Step 8: Run all tests**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 9: Manual smoke test**

Run: `flutter run -d macos`
- Sign out of Codex (`codex logout`); reopen the chat.
  - Verify warning strip appears above the input.
  - Send button is dimmed.
  - Field is still editable.
  - Click "copy" icon → snackbar confirms copy.
  - Click "terminal" icon → terminal app opens at project cwd, snackbar confirms.
- Sign back in (`codex login`); click "Recheck" on providers screen.
- Click Send on the same session — works (pre-send fresh probe re-validates).
- Repeat with `claude logout` / `claude auth login` for Claude CLI.

- [ ] **Step 10: Format + commit**

```bash
dart format lib/
git add lib/features/chat/widgets/chat_input_bar.dart
git commit -m "feat(chat-input): proactive transport readiness gate

When the active transport isn't ready (signed out, not installed,
API key missing), a warning strip appears above the input with two CTA
buttons (copy command, copy + open in terminal app). Send button is
dimmed; the text field stays editable. Reuses ideLaunchActions for the
open-in-terminal flow so the user's configured terminal app
preference (Settings -> General) is honoured."
```

---

## Self-Review Checklist (run after all tasks committed)

- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart format lib/ test/` — no changes (or all changes formatted)
- [ ] `flutter analyze` — no new issues vs. main
- [ ] `flutter test` — all green
- [ ] Manual smoke test: providers screen pills update correctly; chat input strip appears/disappears as you sign in/out externally; copy + open-in-terminal both work; pre-send fresh probe lets a "I just signed in" send proceed without clicking Recheck.
- [ ] Confirm no `// TODO: Task N` comments remain (they were temporary in Task 3).

## Notes for the implementer

- **TDD discipline:** for every task that has a test, write the test first and watch it fail before implementing. The plan's step ordering enforces this — don't shortcut.
- **Frequent commits:** every task ends with a commit. Don't batch.
- **Generated files:** `*.g.dart` and `*.freezed.dart` go in git per the project's "generated files must be committed" memory.
- **Architecture line you must not cross:** no widget may import a service or datasource directly. The chat input bar reaches `IdeLaunchActions` (a notifier), not `IdeService` directly.
- **Auth state cache:** there is intentionally no probe-result cache TTL. If profiling later shows a hotspot, the spec documents the 60s-TTL implementation sketch.
- **External tool dependency:** the Codex `codex login status` and Claude `claude auth status --json` subcommands were verified on 2026-05-06 against `claude` v0.5.7 and `codex` v0.128.0. If a future CLI release breaks the parser contract, the parser tests in Tasks 4 and 5 are the regression net.
