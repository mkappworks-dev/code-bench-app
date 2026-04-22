# Tool-Output Truncation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cap every tool result at 50 KB before it reaches the Anthropic API wire payload, appending a truncation notice when cut.

**Architecture:** A `@visibleForTesting static` method `capContent` is added to `AgentService`. It is called from `_buildWireMessages` at the two `content:` assembly points (history-replay and in-flight loops). `ToolEvent` storage and UI display are untouched — only the wire payload is capped.

**Tech Stack:** Dart, Flutter (`package:flutter/foundation.dart` for `@visibleForTesting`), `flutter_test`

---

## File Map

| Action | File | What changes |
|---|---|---|
| Modify | `lib/services/agent/agent_service.dart` | Add `import 'package:flutter/foundation.dart'`, `_kToolOutputCap` constant, `capContent` static method, two call-site updates in `_buildWireMessages` |
| Create | `test/services/agent/agent_service_cap_test.dart` | Four pure unit tests for `AgentService.capContent` |

---

## Task 1: Write failing tests for `capContent`

**Files:**
- Create: `test/services/agent/agent_service_cap_test.dart`

- [ ] **Step 1: Create the test file**

```dart
import 'package:code_bench_app/services/agent/agent_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cap = 50 * 1024;

  group('AgentService.capContent', () {
    test('returns string unchanged when under cap', () {
      final s = 'a' * (cap - 1);
      expect(AgentService.capContent(s), equals(s));
    });

    test('returns string unchanged when exactly at cap', () {
      final s = 'a' * cap;
      expect(AgentService.capContent(s), equals(s));
    });

    test('truncates and appends notice when over cap (output path)', () {
      final s = 'a' * (cap + 100);
      final result = AgentService.capContent(s);
      expect(result.substring(0, cap), equals('a' * cap));
      expect(
        result,
        contains('[Output truncated at 50 KB. Use grep to search for specific content or read a narrower file range.]'),
      );
      expect(result.length, lessThan(s.length));
    });

    test('truncates and appends notice when over cap (error path)', () {
      final s = 'e' * (cap + 1);
      final result = AgentService.capContent(s);
      expect(result.substring(0, cap), equals('e' * cap));
      expect(
        result,
        contains('[Output truncated at 50 KB. Use grep to search for specific content or read a narrower file range.]'),
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/services/agent/agent_service_cap_test.dart --reporter expanded
```

Expected: compilation error — `AgentService.capContent` is not yet defined.

---

## Task 2: Implement `capContent` in `AgentService`

**Files:**
- Modify: `lib/services/agent/agent_service.dart`

- [ ] **Step 1: Add `package:flutter/foundation.dart` import**

In `lib/services/agent/agent_service.dart`, add after the existing `dart:` imports and before the package imports:

```dart
import 'package:flutter/foundation.dart';
```

Full import block at top of file becomes:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
```

- [ ] **Step 2: Add the constant and method**

After `_isTerminal` (line 370) — or any point inside the `AgentService` class body before the closing `}` — add:

```dart
  static const int _kToolOutputCap = 50 * 1024;

  @visibleForTesting
  static String capContent(String s) {
    if (s.length <= _kToolOutputCap) return s;
    return '${s.substring(0, _kToolOutputCap)}'
        '\n[Output truncated at 50 KB. '
        'Use grep to search for specific content or read a narrower file range.]';
  }
```

- [ ] **Step 3: Run tests to verify they pass**

```bash
flutter test test/services/agent/agent_service_cap_test.dart --reporter expanded
```

Expected output:
```
00:00 +4: All tests passed!
```

- [ ] **Step 4: Commit**

```bash
dart format lib/services/agent/agent_service.dart test/services/agent/agent_service_cap_test.dart
git add lib/services/agent/agent_service.dart test/services/agent/agent_service_cap_test.dart
git commit -m "feat(agent): add capContent helper for 50 KB tool-output cap"
```

---

## Task 3: Wire `capContent` into `_buildWireMessages`

**Files:**
- Modify: `lib/services/agent/agent_service.dart:339-363`

- [ ] **Step 1: Update the history-replay loop call site (line 341)**

Find:
```dart
        for (final te in msg.toolEvents) {
          if (_isTerminal(te.status)) {
            wire.add({'role': 'tool', 'tool_call_id': te.id, 'content': te.output ?? te.error ?? ''});
          }
        }
```

Replace with:
```dart
        for (final te in msg.toolEvents) {
          if (_isTerminal(te.status)) {
            wire.add({'role': 'tool', 'tool_call_id': te.id, 'content': capContent(te.output ?? te.error ?? '')});
          }
        }
```

- [ ] **Step 2: Update the in-flight loop call site (line 363)**

Find:
```dart
      for (final te in currentEvents) {
        if (_isTerminal(te.status)) {
          wire.add({'role': 'tool', 'tool_call_id': te.id, 'content': te.output ?? te.error ?? ''});
        }
      }
```

Replace with:
```dart
      for (final te in currentEvents) {
        if (_isTerminal(te.status)) {
          wire.add({'role': 'tool', 'tool_call_id': te.id, 'content': capContent(te.output ?? te.error ?? '')});
        }
      }
```

- [ ] **Step 3: Run full test suite**

```bash
flutter test --reporter expanded
```

Expected: all tests pass with no new failures.

- [ ] **Step 4: Analyze and format**

```bash
flutter analyze
dart format lib/ test/
```

Expected: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/services/agent/agent_service.dart
git commit -m "feat(agent): apply 50 KB cap to tool outputs in wire messages"
```

---

## Task 4: Update roadmap

**Files:**
- Modify: `docs/superpowers/roadmap/agentic-executor-roadmap.md`

- [ ] **Step 1: Mark Phase 3 as done in the status table**

Find:
```markdown
| 3 | Tool-output truncation | ⬜ Not started |
```

Replace with (fill in the actual PR number and commit hash after merging):
```markdown
| 3 | Tool-output truncation | ✅ Done — PR #XX, commit `XXXXXXX` |
```

- [ ] **Step 2: Update the Phase 3 section heading and body**

Find:
```markdown
## Phase 3 — Tool-output Truncation

**Status:** Not started. No spec or plan yet.
```

Replace with:
```markdown
## Phase 3 — Tool-output Truncation ✅

**Spec:** `docs/superpowers/specs/2026-04-22-tool-output-truncation-design.md`
**Plan:** `docs/superpowers/plans/2026-04-22-tool-output-truncation.md`
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/roadmap/agentic-executor-roadmap.md
git commit -m "doc: mark Phase 3 tool-output truncation as done"
```
