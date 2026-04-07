# Onboarding API Keys Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make API key entry optional during onboarding (skip writes a permanent flag), and add explicit delete buttons to the Settings screen.

**Architecture:** A new `OnboardingPreferences` service wraps `SharedPreferences` to store a `onboarding_completed` boolean. The router guard reads this flag instead of checking for API keys. The onboarding screen is rewritten with an expandable, picker-driven provider list. Settings gets per-key `×` delete buttons.

**Tech Stack:** Flutter, Riverpod (`riverpod_annotation`), `shared_preferences ^2.3.3`, `go_router`, `flutter_secure_storage`

**Spec:** `docs/superpowers/specs/2026-04-07-onboarding-api-keys-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/data/datasources/local/onboarding_preferences.dart` | OnboardingPreferences service + Riverpod provider |
| Generate | `lib/data/datasources/local/onboarding_preferences.g.dart` | Auto-generated provider (build_runner) |
| Create | `test/data/datasources/local/onboarding_preferences_test.dart` | Unit tests for OnboardingPreferences |
| Modify | `lib/router/app_router.dart` | Swap hasAnyApiKey() guard for isCompleted() |
| Modify | `lib/features/onboarding/onboarding_screen.dart` | Full rewrite: expandable list, picker dialog |
| Modify | `lib/features/settings/settings_screen.dart` | Add × delete button per API key field |

---

## Task 1: Git Worktree and Branch

**Files:** none (git only) — **already complete**

Worktree created at `./feat/2026-04-07-onboarding-api-keys`, branch `feat/2026-04-07-onboarding-api-keys`. Baseline tests pass (1/1).

- [x] **Step 1: Worktree created**

```bash
git worktree add ./feat/2026-04-07-onboarding-api-keys -b feat/2026-04-07-onboarding-api-keys
```

- [x] **Step 2: Baseline tests pass**

```bash
cd feat/2026-04-07-onboarding-api-keys && flutter test
# 00:00 +1: All tests passed!
```

- [ ] **Step 3: All remaining tasks run inside the worktree**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/feat/2026-04-07-onboarding-api-keys
```

---

## Task 2: OnboardingPreferences Service

**Files:**
- Create: `lib/data/datasources/local/onboarding_preferences.dart`
- Create: `test/data/datasources/local/onboarding_preferences_test.dart`
- Generate: `lib/data/datasources/local/onboarding_preferences.g.dart` (build_runner)

- [ ] **Step 1: Write the failing tests**

Create `test/data/datasources/local/onboarding_preferences_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:code_bench_app/data/datasources/local/onboarding_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingPreferences', () {
    test('isCompleted returns false when never set', () async {
      final prefs = OnboardingPreferences();
      expect(await prefs.isCompleted(), false);
    });

    test('isCompleted returns true after markCompleted', () async {
      final prefs = OnboardingPreferences();
      await prefs.markCompleted();
      expect(await prefs.isCompleted(), true);
    });

    test('markCompleted is idempotent', () async {
      final prefs = OnboardingPreferences();
      await prefs.markCompleted();
      await prefs.markCompleted();
      expect(await prefs.isCompleted(), true);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure (import not found)**

```bash
flutter test test/data/datasources/local/onboarding_preferences_test.dart
```

Expected: compilation error — `onboarding_preferences.dart` does not exist yet.

- [ ] **Step 3: Create the service**

Create `lib/data/datasources/local/onboarding_preferences.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_preferences.g.dart';

@Riverpod(keepAlive: true)
OnboardingPreferences onboardingPreferences(Ref ref) =>
    OnboardingPreferences();

class OnboardingPreferences {
  static const _key = 'onboarding_completed';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
```

- [ ] **Step 4: Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `lib/data/datasources/local/onboarding_preferences.g.dart` with `onboardingPreferencesProvider`.

- [ ] **Step 5: Run tests — expect all pass**

```bash
flutter test test/data/datasources/local/onboarding_preferences_test.dart
```

Expected:
```
00:00 +3: All tests passed!
```

- [ ] **Step 6: Commit**

```bash
git add lib/data/datasources/local/onboarding_preferences.dart \
        lib/data/datasources/local/onboarding_preferences.g.dart \
        test/data/datasources/local/onboarding_preferences_test.dart
git commit -m "feat: add OnboardingPreferences service with SharedPreferences flag"
```

---

## Task 3: Router Guard Swap

**Files:**
- Modify: `lib/router/app_router.dart`

- [ ] **Step 1: Update the router redirect**

Open `lib/router/app_router.dart`. Replace the entire `redirect` callback (lines 21–28):

```dart
// BEFORE
redirect: (context, state) async {
  final storage = ref.read(secureStorageSourceProvider);
  final hasKey = await storage.hasAnyApiKey();
  if (!hasKey && state.matchedLocation != '/onboarding') {
    return '/onboarding';
  }
  return null;
},

// AFTER
redirect: (context, state) async {
  final prefs = ref.read(onboardingPreferencesProvider);
  final done = await prefs.isCompleted();
  if (!done && state.matchedLocation != '/onboarding') {
    return '/onboarding';
  }
  return null;
},
```

- [ ] **Step 2: Update the import at the top of `app_router.dart`**

Remove the unused `secureStorageSourceProvider` import and add the new one:

```dart
// Remove this line (no longer needed in router):
import '../data/datasources/local/secure_storage_source.dart';

// Add this line:
import '../data/datasources/local/onboarding_preferences.dart';
```

- [ ] **Step 3: Analyze — no errors**

```bash
flutter analyze lib/router/app_router.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Run smoke test**

```bash
flutter test test/widget_test.dart
```

Expected: `+1: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/router/app_router.dart
git commit -m "feat: replace hasAnyApiKey router guard with onboarding_completed flag"
```

---

## Task 4: Onboarding Screen Rewrite

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`

The screen is rewritten with:
- `List<AIProvider> _addedProviders` starts as `[AIProvider.anthropic]`
- Each entry is a `_ProviderRow` (one line: label + field + show/hide + Test + ×)
- "Add another provider" opens a `showDialog` picker of remaining providers
- Skip → `markCompleted()` + navigate; Save & Continue → save non-empty fields + `markCompleted()` + navigate

- [ ] **Step 1: Rewrite `onboarding_screen.dart`**

Replace the entire file content:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/datasources/local/onboarding_preferences.dart';
import '../../data/datasources/local/secure_storage_source.dart';
import '../../data/models/ai_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final List<AIProvider> _addedProviders = [AIProvider.anthropic];
  final Map<AIProvider, TextEditingController> _controllers = {
    AIProvider.anthropic: TextEditingController(),
  };
  final Map<AIProvider, bool?> _testResults = {};
  final Map<AIProvider, bool> _testing = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addProvider(AIProvider provider) {
    setState(() {
      _addedProviders.add(provider);
      _controllers[provider] = TextEditingController();
    });
  }

  void _removeProvider(AIProvider provider) {
    setState(() {
      _addedProviders.remove(provider);
      _controllers[provider]?.dispose();
      _controllers.remove(provider);
      _testResults.remove(provider);
      _testing.remove(provider);
    });
  }

  Future<void> _showProviderPicker() async {
    final available = AIProvider.values
        .where((p) => !_addedProviders.contains(p))
        .toList();
    if (available.isEmpty) return;

    final picked = await showDialog<AIProvider>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: ThemeConstants.panelBackground,
        title: const Text(
          'Add a provider',
          style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14),
        ),
        children: [
          ...available.map(
            (p) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Text(
                p.displayName,
                style: const TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );

    if (picked != null) _addProvider(picked);
  }

  Future<void> _testConnection(AIProvider provider) async {
    final key = _controllers[provider]!.text.trim();
    if (key.isEmpty) return;
    setState(() => _testing[provider] = true);
    try {
      bool success = false;
      switch (provider) {
        case AIProvider.openai:
          success = await _testOpenAI(key);
        case AIProvider.anthropic:
          success = await _testAnthropic(key);
        case AIProvider.gemini:
          success = await _testGemini(key);
        default:
          success = false;
      }
      setState(() => _testResults[provider] = success);
    } catch (_) {
      setState(() => _testResults[provider] = false);
    } finally {
      setState(() => _testing[provider] = false);
    }
  }

  Future<bool> _testOpenAI(String key) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        connectTimeout: const Duration(seconds: 10),
        headers: {'Authorization': 'Bearer $key'},
      ));
      await dio.get('/models');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _testAnthropic(String key) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.anthropic.com/v1',
        connectTimeout: const Duration(seconds: 10),
        headers: {
          'x-api-key': key,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
      ));
      await dio.post('/messages', data: {
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 1,
        'messages': [
          {'role': 'user', 'content': 'hi'},
        ],
      });
      return true;
    } catch (e) {
      if (e.toString().contains('400')) return true;
      return false;
    }
  }

  Future<bool> _testGemini(String key) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        connectTimeout: const Duration(seconds: 10),
      ));
      await dio.get('/models?key=$key');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _skip() async {
    final prefs = ref.read(onboardingPreferencesProvider);
    await prefs.markCompleted();
    if (mounted) context.go('/dashboard');
  }

  Future<void> _saveAndContinue() async {
    setState(() => _saving = true);
    try {
      final storage = ref.read(secureStorageSourceProvider);
      final prefs = ref.read(onboardingPreferencesProvider);

      for (final entry in _controllers.entries) {
        final key = entry.value.text.trim();
        if (key.isNotEmpty) {
          await storage.writeApiKey(entry.key.name, key);
        }
      }

      await prefs.markCompleted();
      if (mounted) context.go('/dashboard');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAdded = _addedProviders.length == AIProvider.values.length;

    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Row(
        children: [
          // ── Left panel (38%) — branding ──────────────────────────────
          FractionallySizedBox(
            widthFactor: 0.38,
            heightFactor: 1.0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                  colors: [Color(0xFF111111), Color(0xFF0A0A0A), Color(0xFF050505)],
                ),
                border: Border(
                  right: BorderSide(color: Color(0xFF2A2A2A)),
                ),
              ),
              padding: const EdgeInsets.all(36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + title inline, vertically centred
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007ACC), Color(0xFF004F85)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x99000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Code Bench',
                        style: TextStyle(
                          color: Color(0xFFF0F0F0),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tagline below
                  const Text(
                    'AI-powered coding workspace',
                    style: TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Feature cards
                  _FeatureCard(
                    icon: '⚡',
                    title: 'Multi-provider AI',
                    subtitle: 'OpenAI · Anthropic · Gemini · Ollama',
                  ),
                  const SizedBox(height: 8),
                  _FeatureCard(
                    icon: '🖊',
                    title: 'Smart Code Editor',
                    subtitle: 'AI apply · diff view · file explorer',
                  ),
                  const SizedBox(height: 8),
                  _FeatureCard(
                    icon: '🐙',
                    title: 'GitHub Integration',
                    subtitle: 'PRs · commits · repo browser',
                  ),
                  const Spacer(),
                  // Keychain note pinned to bottom
                  const Text(
                    '🔒 Keys stored in your OS keychain',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right panel — form ────────────────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFF141414),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add API Keys',
                    style: TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add now or any time in Settings.',
                    style: TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ..._addedProviders.map(
                    (provider) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProviderRow(
                        provider: provider,
                        controller: _controllers[provider]!,
                        testResult: _testResults[provider],
                        isTesting: _testing[provider] ?? false,
                        canRemove: _addedProviders.length > 1,
                        onTest: () => _testConnection(provider),
                        onRemove: () => _removeProvider(provider),
                      ),
                    ),
                  ),
                  if (!allAdded) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _showProviderPicker,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add another provider'),
                      style: TextButton.styleFrom(
                        foregroundColor: ThemeConstants.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _skip,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: ThemeConstants.borderColor),
                            foregroundColor: ThemeConstants.textSecondary,
                          ),
                          child: const Text('Skip'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveAndContinue,
                          child: _saving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save & Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon  $title',
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderRow extends StatefulWidget {
  const _ProviderRow({
    required this.provider,
    required this.controller,
    required this.testResult,
    required this.isTesting,
    required this.canRemove,
    required this.onTest,
    required this.onRemove,
  });

  final AIProvider provider;
  final TextEditingController controller;
  final bool? testResult;
  final bool isTesting;
  final bool canRemove;
  final VoidCallback onTest;
  final VoidCallback onRemove;

  @override
  State<_ProviderRow> createState() => _ProviderRowState();
}

class _ProviderRowState extends State<_ProviderRow> {
  bool _obscure = true;

  bool get _isUrlProvider =>
      widget.provider == AIProvider.ollama ||
      widget.provider == AIProvider.custom;

  bool get _supportsTest =>
      widget.provider == AIProvider.openai ||
      widget.provider == AIProvider.anthropic ||
      widget.provider == AIProvider.gemini;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            widget.provider.displayName.toUpperCase(),
            style: const TextStyle(
              color: ThemeConstants.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: widget.controller,
            obscureText: !_isUrlProvider && _obscure,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 13,
              fontFamily: ThemeConstants.editorFontFamily,
            ),
            decoration: InputDecoration(
              hintText: _isUrlProvider ? 'http://localhost:11434' : 'API key...',
            ),
          ),
        ),
        if (!_isUrlProvider) ...[
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              size: 16,
              color: ThemeConstants.textSecondary,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
        if (_supportsTest) ...[
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: widget.isTesting ? null : widget.onTest,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: widget.testResult == true
                    ? ThemeConstants.success
                    : ThemeConstants.borderColor,
              ),
              foregroundColor: widget.testResult == true
                  ? ThemeConstants.success
                  : ThemeConstants.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: widget.isTesting
                ? const SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.testResult == true ? '✓ OK' : 'Test',
                    style: const TextStyle(fontSize: 11),
                  ),
          ),
        ],
        const SizedBox(width: 6),
        IconButton(
          icon: Icon(
            Icons.close,
            size: 14,
            color: widget.canRemove
                ? ThemeConstants.textSecondary
                : ThemeConstants.borderColor,
          ),
          onPressed: widget.canRemove ? widget.onRemove : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
          tooltip: widget.canRemove ? 'Remove' : null,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/onboarding/onboarding_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/onboarding_screen.dart
git commit -m "feat: rewrite onboarding with expandable provider list and skip flow"
```

---

## Task 5: Settings Screen — Explicit Delete Button

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

Add a `×` `IconButton` to `_ApiKeyField`. Tapping it clears the controller, immediately deletes the key from storage, invalidates `aiServiceProvider`, and shows a SnackBar.

- [ ] **Step 1: Add `onDelete` callback to `_ApiKeyField`**

In `lib/features/settings/settings_screen.dart`, find the `_ApiKeyField` widget (line ~219) and add an `onDelete` parameter:

```dart
class _ApiKeyField extends StatefulWidget {
  const _ApiKeyField({
    required this.provider,
    required this.controller,
    required this.onDelete,  // ADD THIS
  });

  final AIProvider provider;
  final TextEditingController controller;
  final VoidCallback onDelete;  // ADD THIS

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}
```

- [ ] **Step 2: Add the `×` button inside `_ApiKeyFieldState.build`**

Replace the `_LabeledField` call inside `_ApiKeyFieldState.build` so the row includes a delete button:

```dart
@override
Widget build(BuildContext context) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: _LabeledField(
          label: widget.provider.displayName,
          hint: 'API key',
          controller: widget.controller,
          obscureText: _obscure,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              size: 16,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: IconButton(
          icon: const Icon(Icons.close, size: 16),
          color: ThemeConstants.textSecondary,
          tooltip: 'Remove key',
          onPressed: widget.onDelete,
        ),
      ),
    ],
  );
}
```

- [ ] **Step 3: Implement `_deleteKey` in `_SettingsScreenState` and wire it up**

In `_SettingsScreenState`, add a `_deleteKey` method:

```dart
Future<void> _deleteKey(AIProvider provider) async {
  final storage = ref.read(secureStorageSourceProvider);
  await storage.deleteApiKey(provider.name);
  _controllers[provider]!.clear();
  ref.invalidate(aiServiceProvider);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${provider.displayName} key removed'),
        backgroundColor: ThemeConstants.success,
      ),
    );
  }
}
```

Then in the `build` method, update the `.map(...)` that renders `_ApiKeyField` to pass `onDelete`:

```dart
...AIProvider.values
    .where((p) => p != AIProvider.ollama && p != AIProvider.custom)
    .map(
      (provider) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _ApiKeyField(
          provider: provider,
          controller: _controllers[provider]!,
          onDelete: () => _deleteKey(provider),  // ADD THIS
        ),
      ),
    ),
```

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/features/settings/settings_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat: add explicit delete button per API key in settings screen"
```

---

## Task 6: Final Check

- [ ] **Step 1: Full analyze**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 2: Format**

```bash
dart format lib/ test/
```

Re-stage any files reformatted.

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Manual smoke test on macOS**

```bash
flutter run -d macos
```

Verify:
1. First launch → redirected to onboarding.
2. "Skip" → goes to dashboard, never redirected again on relaunch.
3. "Add another provider" → picker shows only unselected providers.
4. Selecting a provider → row appears inline.
5. `×` on first row is disabled (grey); `×` on second+ rows removes the row.
6. "Save & Continue" with no keys → goes to dashboard.
7. Settings → `×` button on a key → key is deleted, SnackBar shown, AI service invalidated.

- [ ] **Step 5: Final commit if any formatting changes**

```bash
git add -p
git commit -m "style: apply dart format"
```
