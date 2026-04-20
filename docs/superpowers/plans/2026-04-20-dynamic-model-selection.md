# Dynamic Model Selection — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded `"model": "custom"` bug by fetching real model IDs from Ollama (`/api/tags`) and Custom (`/models`) endpoints and surfacing them in the chat model picker, grouped by provider.

**Architecture:** A new `AvailableModelsNotifier` (`AsyncNotifier<List<AIModel>>`, `keepAlive: true`) watches `aiRepositoryProvider` in `build()`. Because `ProvidersActions` already invalidates `aiRepositoryProvider` after every endpoint save, the models list rebuilds automatically. The chat model picker reads from this notifier instead of `AIModels.defaults`. `SessionSettingsActions._loadForSession` is updated to also search dynamic models when resolving a persisted model ID.

**Tech Stack:** Flutter/Dart, Riverpod (`riverpod_annotation`), `flutter_test`, `build_runner`

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Modify | `lib/data/shared/ai_model.dart` | Remove `customModel` from `defaults` |
| Create | `lib/features/chat/notifiers/available_models_notifier.dart` | Fetch + merge static/dynamic models |
| Create | `lib/features/chat/notifiers/available_models_notifier.g.dart` | Generated — do not edit |
| Modify | `lib/features/chat/notifiers/session_settings_actions.dart` | Fix `_loadForSession` dynamic model lookup |
| Modify | `lib/features/chat/widgets/chat_input_bar.dart` | Grouped picker, loading/refresh states |
| Create | `test/features/chat/notifiers/available_models_notifier_test.dart` | Unit tests for notifier |

---

## Task 1: Remove `customModel` from `AIModels.defaults`

**Files:**
- Modify: `lib/data/shared/ai_model.dart`

- [ ] **Step 1: Remove `customModel` from the `defaults` list**

In `lib/data/shared/ai_model.dart`, change:

```dart
static List<AIModel> get defaults => [gpt4o, gpt4oMini, claude35Sonnet, claude3Haiku, geminiFlash, customModel];
```

to:

```dart
static List<AIModel> get defaults => [gpt4o, gpt4oMini, claude35Sonnet, claude3Haiku, geminiFlash];
```

Keep the `customModel` constant itself — it may be used as a fallback sentinel elsewhere. Just remove it from the public list.

- [ ] **Step 2: Check for broken references**

```bash
flutter analyze
```

Expected: no errors. If any file references `AIModels.customModel` or `AIModels.defaults` in a way that now breaks, fix it (e.g. a test that expected 6 models now expects 5).

- [ ] **Step 3: Commit**

```bash
git add lib/data/shared/ai_model.dart
git commit -m "feat(models): remove customModel sentinel from AIModels.defaults"
```

---

## Task 2: Write failing tests for `AvailableModelsNotifier`

**Files:**
- Create: `test/features/chat/notifiers/available_models_notifier_test.dart`

- [ ] **Step 1: Create the test file**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/data/ai/repository/ai_repository.dart';
import 'package:code_bench_app/data/ai/repository/ai_repository_impl.dart';
import 'package:code_bench_app/services/providers/providers_service.dart';
import 'package:code_bench_app/features/chat/notifiers/available_models_notifier.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeAIRepository extends Fake implements AIRepository {
  final Map<AIProvider, List<AIModel>> models;
  final Map<AIProvider, Exception> errors;

  _FakeAIRepository({this.models = const {}, this.errors = const {}});

  @override
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) async {
    final err = errors[provider];
    if (err != null) throw err;
    return models[provider] ?? [];
  }

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) => const Stream.empty();

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async => true;
}

class _FakeProvidersService extends Fake implements ProvidersService {
  final String ollamaUrl;
  final String customEndpoint;
  final String customApiKey;

  const _FakeProvidersService({
    this.ollamaUrl = '',
    this.customEndpoint = '',
    this.customApiKey = '',
  });

  @override
  Future<String?> readOllamaUrl() async => ollamaUrl.isEmpty ? null : ollamaUrl;

  @override
  Future<String?> readCustomEndpoint() async => customEndpoint.isEmpty ? null : customEndpoint;

  @override
  Future<String?> readCustomApiKey() async => customApiKey.isEmpty ? null : customApiKey;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer({
  required _FakeAIRepository repo,
  required _FakeProvidersService svc,
}) {
  return ProviderContainer(
    overrides: [
      aiRepositoryProvider.overrideWith((ref) async => repo),
      providersServiceProvider.overrideWith((ref) => svc),
    ],
  );
}

AIModel _ollamaModel(String name) => AIModel(
  id: 'ollama_$name',
  provider: AIProvider.ollama,
  name: name,
  modelId: name,
  supportsStreaming: true,
);

AIModel _customModel(String id) => AIModel(
  id: id,
  provider: AIProvider.custom,
  name: id,
  modelId: id,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AvailableModelsNotifier', () {
    test('returns only static defaults when no endpoints configured', () async {
      final container = _makeContainer(
        repo: _FakeAIRepository(),
        svc: const _FakeProvidersService(),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, equals(AIModels.defaults));
      expect(models.any((m) => m.provider == AIProvider.ollama), isFalse);
      expect(models.any((m) => m.provider == AIProvider.custom), isFalse);
    });

    test('includes ollama models when ollama URL is configured', () async {
      final ollamaModels = [_ollamaModel('llama3.2'), _ollamaModel('mistral')];
      final container = _makeContainer(
        repo: _FakeAIRepository(models: {AIProvider.ollama: ollamaModels}),
        svc: const _FakeProvidersService(ollamaUrl: 'http://localhost:11434'),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, containsAll(AIModels.defaults));
      expect(models, containsAll(ollamaModels));
    });

    test('includes custom models when custom endpoint is configured', () async {
      final customModels = [_customModel('mistral-7b-instruct'), _customModel('codestral-22b')];
      final container = _makeContainer(
        repo: _FakeAIRepository(models: {AIProvider.custom: customModels}),
        svc: const _FakeProvidersService(customEndpoint: 'http://localhost:1234/v1'),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, containsAll(AIModels.defaults));
      expect(models, containsAll(customModels));
    });

    test('includes models from both dynamic providers when both configured', () async {
      final ollamaModels = [_ollamaModel('llama3.2')];
      final customModels = [_customModel('mistral-7b-instruct')];
      final container = _makeContainer(
        repo: _FakeAIRepository(models: {
          AIProvider.ollama: ollamaModels,
          AIProvider.custom: customModels,
        }),
        svc: const _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, containsAll(AIModels.defaults));
      expect(models, containsAll(ollamaModels));
      expect(models, containsAll(customModels));
    });

    test('ollama fetch failure does not affect static or custom models', () async {
      final customModels = [_customModel('mistral-7b-instruct')];
      final container = _makeContainer(
        repo: _FakeAIRepository(
          models: {AIProvider.custom: customModels},
          errors: {AIProvider.ollama: Exception('connection refused')},
        ),
        svc: const _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, containsAll(AIModels.defaults));
      expect(models, containsAll(customModels));
      expect(models.any((m) => m.provider == AIProvider.ollama), isFalse);
    });

    test('custom fetch failure does not affect static or ollama models', () async {
      final ollamaModels = [_ollamaModel('llama3.2')];
      final container = _makeContainer(
        repo: _FakeAIRepository(
          models: {AIProvider.ollama: ollamaModels},
          errors: {AIProvider.custom: Exception('connection refused')},
        ),
        svc: const _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final models = await container.read(availableModelsProvider.future);
      expect(models, containsAll(AIModels.defaults));
      expect(models, containsAll(ollamaModels));
      expect(models.any((m) => m.provider == AIProvider.custom), isFalse);
    });

    test('notifier resolves to AsyncData even when both fetches fail', () async {
      final container = _makeContainer(
        repo: _FakeAIRepository(
          errors: {
            AIProvider.ollama: Exception('offline'),
            AIProvider.custom: Exception('offline'),
          },
        ),
        svc: const _FakeProvidersService(
          ollamaUrl: 'http://localhost:11434',
          customEndpoint: 'http://localhost:1234/v1',
        ),
      );
      addTearDown(container.dispose);

      final result = await container.read(availableModelsProvider.future);
      expect(result, equals(AIModels.defaults));
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/features/chat/notifiers/available_models_notifier_test.dart
```

Expected: compilation error — `availableModelsProvider` does not exist yet. This confirms the test is wired correctly.

---

## Task 3: Implement `AvailableModelsNotifier`

**Files:**
- Create: `lib/features/chat/notifiers/available_models_notifier.dart`
- Create: `lib/features/chat/notifiers/available_models_notifier.g.dart` (generated)

- [ ] **Step 1: Create the notifier**

```dart
// lib/features/chat/notifiers/available_models_notifier.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/ai/repository/ai_repository_impl.dart';
import '../../../data/shared/ai_model.dart';
import '../../../services/providers/providers_service.dart';

part 'available_models_notifier.g.dart';

@Riverpod(keepAlive: true)
class AvailableModelsNotifier extends _$AvailableModelsNotifier {
  @override
  Future<List<AIModel>> build() async {
    final repo = await ref.watch(aiRepositoryProvider.future);
    final svc = ref.read(providersServiceProvider);
    final ollamaUrl = await svc.readOllamaUrl() ?? '';
    final customEndpoint = await svc.readCustomEndpoint() ?? '';
    final customApiKey = await svc.readCustomApiKey() ?? '';

    final result = List<AIModel>.from(AIModels.defaults);

    final futures = <Future<List<AIModel>>>[];

    if (ollamaUrl.isNotEmpty) {
      futures.add(
        repo
            .fetchAvailableModels(AIProvider.ollama, '')
            .catchError((Object e) {
          dLog('[AvailableModelsNotifier] Ollama fetch failed: $e');
          return <AIModel>[];
        }),
      );
    }

    if (customEndpoint.isNotEmpty) {
      futures.add(
        repo
            .fetchAvailableModels(AIProvider.custom, customApiKey)
            .catchError((Object e) {
          dLog('[AvailableModelsNotifier] Custom fetch failed: $e');
          return <AIModel>[];
        }),
      );
    }

    if (futures.isNotEmpty) {
      final dynamic = await Future.wait(futures);
      result.addAll(dynamic.expand((list) => list));
    }

    return result;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
```

- [ ] **Step 2: Run build_runner to generate the `.g.dart` file**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/features/chat/notifiers/available_models_notifier.g.dart` is created.

- [ ] **Step 3: Run the tests**

```bash
flutter test test/features/chat/notifiers/available_models_notifier_test.dart
```

Expected: all 7 tests pass.

- [ ] **Step 4: Run full test suite to check for regressions**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/notifiers/available_models_notifier.dart \
        lib/features/chat/notifiers/available_models_notifier.g.dart \
        test/features/chat/notifiers/available_models_notifier_test.dart
git commit -m "feat(models): add AvailableModelsNotifier for dynamic Ollama + Custom model fetching"
```

---

## Task 4: Fix `_loadForSession` to resolve dynamic model IDs

`SessionSettingsActions._loadForSession` uses `AIModels.fromId()` which only searches the static list. A session saved with `modelId: 'llama3.2'` would silently fall back to Claude on restore. Fix this by also searching `availableModelsProvider`.

**Files:**
- Modify: `lib/features/chat/notifiers/session_settings_actions.dart`

- [ ] **Step 1: Add a private `_resolveModel` helper and update `_loadForSession`**

In `lib/features/chat/notifiers/session_settings_actions.dart`, add the import at the top:

```dart
import 'available_models_notifier.dart';
```

Then add the helper method and update `_loadForSession`. Replace the current model-resolution line:

```dart
final AIModel model =
    (session.modelId.isNotEmpty ? AIModels.fromId(session.modelId) : null) ?? ref.read(selectedModelProvider);
```

With a call to a new private helper placed after `_asFailure`:

```dart
AIModel _resolveModel(String modelId) {
  if (modelId.isEmpty) return ref.read(selectedModelProvider);
  return AIModels.fromId(modelId) ??
      ref.read(availableModelsProvider).value?.firstWhereOrNull((m) => m.modelId == modelId) ??
      ref.read(selectedModelProvider);
}
```

And in `_loadForSession`, replace the model line with:

```dart
final model = _resolveModel(session.modelId);
```

- [ ] **Step 2: Run `flutter analyze`**

```bash
flutter analyze
```

Expected: no issues. The `firstWhereOrNull` extension is already imported via `collection` (already a dependency in `session_settings_actions.dart`).

- [ ] **Step 3: Run tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/notifiers/session_settings_actions.dart
git commit -m "fix(models): resolve dynamic model IDs in session settings restore"
```

---

## Task 5: Update `_showModelPicker` with grouped sections

**Files:**
- Modify: `lib/features/chat/widgets/chat_input_bar.dart`

- [ ] **Step 1: Add a refresh sentinel constant and section order list at the top of `_ChatInputBarState`**

In `lib/features/chat/widgets/chat_input_bar.dart`, inside `_ChatInputBarState`, add:

```dart
// Sentinel value returned when the user taps "Refresh models" in the picker.
// Distinct from null (dismissed without picking) via identity check.
static final _refreshSentinel = AIModel(
  id: '_refresh_sentinel',
  provider: AIProvider.custom,
  name: '',
  modelId: '',
);

static const _pickerSectionOrder = [
  AIProvider.anthropic,
  AIProvider.openai,
  AIProvider.gemini,
  AIProvider.ollama,
  AIProvider.custom,
];
```

- [ ] **Step 2: Add import for `available_models_notifier.dart`**

Add to the import block in `chat_input_bar.dart`:

```dart
import '../notifiers/available_models_notifier.dart';
```

- [ ] **Step 3: Replace `_showModelPicker` with the grouped implementation**

Replace the entire `_showModelPicker` method:

```dart
void _showModelPicker(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return;
  final c = AppColors.of(context);
  final selected = ref.read(selectedModelProvider);

  // Use last-known value so the picker opens instantly even during a re-fetch.
  final allModels =
      ref.read(availableModelsProvider).value ?? AIModels.defaults;
  final isRefreshing = ref.read(availableModelsProvider).isLoading;

  // Group by provider.
  final grouped = <AIProvider, List<AIModel>>{};
  for (final m in allModels) {
    grouped.putIfAbsent(m.provider, () => []).add(m);
  }

  final items = <PopupMenuEntry<AIModel>>[];

  for (final provider in _pickerSectionOrder) {
    final models = grouped[provider];
    if (models == null || models.isEmpty) continue;

    items.add(
      PopupMenuItem<AIModel>(
        enabled: false,
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          provider.displayName.toUpperCase(),
          style: TextStyle(
            color: c.mutedFg,
            fontSize: 9,
            letterSpacing: 0.06,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    for (final m in models) {
      items.add(
        PopupMenuItem<AIModel>(
          value: m,
          height: 32,
          child: Text(
            m.name,
            style: TextStyle(
              color: m == selected ? c.textPrimary : c.textSecondary,
              fontSize: ThemeConstants.uiFontSizeSmall,
            ),
          ),
        ),
      );
    }
  }

  if (isRefreshing) {
    items.add(
      PopupMenuItem<AIModel>(
        enabled: false,
        height: 28,
        child: Text(
          'Refreshing…',
          style: TextStyle(
            color: c.mutedFg,
            fontSize: ThemeConstants.uiFontSizeSmall,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  items.add(const PopupMenuDivider<AIModel>());
  items.add(
    PopupMenuItem<AIModel>(
      value: _refreshSentinel,
      height: 28,
      child: Text(
        '↺  Refresh models',
        style: TextStyle(
          color: c.mutedFg,
          fontSize: ThemeConstants.uiFontSizeSmall,
        ),
      ),
    ),
  );

  showInstantMenu<AIModel>(
    context: context,
    position: _menuAbove(context, box),
    color: c.panelBackground,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(7),
      side: BorderSide(color: c.subtleBorder),
    ),
    items: items,
  ).then((value) {
    if (identical(value, _refreshSentinel)) {
      ref.read(availableModelsProvider.notifier).refresh();
      return;
    }
    if (value != null) {
      ref
          .read(sessionSettingsActionsProvider.notifier)
          .updateModel(widget.sessionId, value);
    }
  });
}
```

- [ ] **Step 4: Run `flutter analyze`**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 5: Run tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Format and commit**

```bash
dart format lib/features/chat/widgets/chat_input_bar.dart
git add lib/features/chat/widgets/chat_input_bar.dart
git commit -m "feat(models): grouped model picker with dynamic Ollama/Custom sections"
```

---

## Task 6: Final checks

- [ ] **Step 1: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 2: Run analyzer**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 3: Format all touched files**

```bash
dart format lib/ test/
```

- [ ] **Step 4: Launch the app and smoke-test the picker**

```bash
flutter run -d macos
```

Verify:
1. Open the chat input bar model chip — picker shows provider sections (Anthropic, OpenAI, Gemini)
2. No Ollama or Custom sections shown when neither is configured
3. Configure a Custom endpoint in Settings → Providers — after saving, reopen picker — Custom section appears with real model IDs
4. Configure Ollama — after saving, Ollama section appears
5. Tap "↺ Refresh models" — picker closes, reopening it shows fresh models
6. Select a custom/ollama model — chip updates to show the selected model name
7. Start a new session — model chip reflects the selected model; sending a message uses the real `modelId` (not `"custom"`)

- [ ] **Step 5: Commit if any formatting-only changes**

```bash
git add -p  # only stage formatting changes if any
git commit -m "style: dart format after dynamic model selection"
```
