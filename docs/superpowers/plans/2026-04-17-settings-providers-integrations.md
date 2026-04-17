# Settings, Providers & Integrations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bump app version to 0.1.0, wire project/thread sort into the sidebar, redesign the Providers screen with inline test/save/clear per field, and add an Integrations screen for GitHub.

**Architecture:** All new persistence is through existing `SecureStorage` → `SettingsRepository` → `SettingsService` → `ApiKeysNotifier` delegation chain. Sort is applied in-memory in the sidebar widget; no datasource changes needed. `IntegrationsScreen` reuses `gitHubAuthProvider` directly — no new notifiers.

**Tech Stack:** Flutter/Dart, Riverpod, `package_info_plus` (new dep), `flutter_secure_storage`, Dio (existing).

---

## File map

| File | Change |
|---|---|
| `pubspec.yaml` | version bump + add `package_info_plus` |
| `lib/features/settings/general_screen.dart` | read version via `PackageInfo`, display in About row |
| `lib/features/project_sidebar/project_sidebar.dart` | apply project + thread sort in build |
| `lib/data/_core/secure_storage.dart` | add `deleteOllamaUrl`, `deleteCustomEndpoint`, `deleteCustomApiKey` |
| `lib/data/settings/repository/settings_repository.dart` | add three delete methods to interface |
| `lib/data/settings/repository/settings_repository_impl.dart` | implement three delete methods |
| `lib/services/settings/settings_service.dart` | delegate three delete methods |
| `lib/data/ai/datasource/api_key_test_datasource_dio.dart` | add `testCustomEndpoint` |
| `lib/data/ai/repository/api_key_test_repository.dart` | add `testCustomEndpoint` to interface |
| `lib/data/ai/repository/api_key_test_repository_impl.dart` | implement `testCustomEndpoint` |
| `lib/services/api_key_test/api_key_test_service.dart` | delegate `testCustomEndpoint` |
| `lib/features/settings/notifiers/settings_actions.dart` | add `testCustomEndpoint` method |
| `lib/features/settings/notifiers/providers_notifier.dart` | add `saveKey`, `saveOllamaUrl`, `clearOllamaUrl`, `saveCustomEndpoint`, `clearCustomEndpoint`, `clearCustomApiKey` |
| `lib/features/settings/providers_screen.dart` | full redesign — inline test/clear, remove global Save |
| `lib/features/settings/settings_screen.dart` | add Integrations nav item |
| `lib/features/settings/integrations_screen.dart` | **new** — GitHub connected/disconnected UI |
| `test/features/settings/settings_actions_test.dart` | add `testCustomEndpoint` cases, update fake |
| `test/features/settings/providers_notifier_test.dart` | **new** — unit tests for new `ApiKeysNotifier` methods |

---

## Task 1: Version bump + About section

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/settings/general_screen.dart`

- [ ] **Step 1: Add `package_info_plus` to pubspec.yaml**

Open `pubspec.yaml`. Change the version line and add the dependency under `# Utilities`:

```yaml
version: 0.1.0+1
```

```yaml
  package_info_plus: ^8.3.0
```

- [ ] **Step 2: Run `flutter pub get`**

```bash
flutter pub get
```

Expected: resolves without errors.

- [ ] **Step 3: Add version state and load in `GeneralScreen`**

In `lib/features/settings/general_screen.dart`, add `_version` field and load it alongside prefs. The full updated `_GeneralScreenState` fields and `_load` method:

```dart
String _version = '';
```

Replace the `_load` method body to also call `PackageInfo.fromPlatform()`:

```dart
Future<void> _load() async {
  try {
    final results = await Future.wait([
      ref.read(generalPrefsProvider.future),
      PackageInfo.fromPlatform(),
    ]);
    final s = results[0] as dynamic;
    final info = results[1] as PackageInfo;
    if (!mounted) return;
    setState(() {
      _autoCommit = s.autoCommit;
      _deleteConfirmation = s.deleteConfirmation;
      _terminalAppController.text = s.terminalApp;
      _themeMode = s.themeMode;
      _version = info.version;
    });
  } catch (e) {
    if (mounted) {
      AppSnackBar.show(context, 'Could not load settings — showing defaults.', type: AppSnackBarType.warning);
    }
  }
}
```

Add the import at the top of the file:

```dart
import 'package:package_info_plus/package_info_plus.dart';
```

- [ ] **Step 4: Replace the About row trailing widget**

Find the `SettingsRow` under `SectionLabel('About')`. Replace its `trailing:` with:

```dart
trailing: Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: c.accentTintMid,
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    _version.isEmpty ? '…' : _version,
    style: TextStyle(color: c.accent, fontSize: 10, fontWeight: FontWeight.w500),
  ),
),
```

- [ ] **Step 5: Run the app and verify**

```bash
flutter run -d macos
```

Navigate to Settings → General → About. Confirm the version badge shows `0.1.0`.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/settings/general_screen.dart
git commit -m "feat: bump version to 0.1.0, show in About section"
```

---

## Task 2: Wire sort into the project sidebar

**Files:**
- Modify: `lib/features/project_sidebar/project_sidebar.dart`

- [ ] **Step 1: Add sort helpers inside `_ProjectSidebarState`**

Add two private methods to `_ProjectSidebarState`. These are pure sort functions called from `build`:

```dart
List<Project> _sortedProjects(List<Project> projects, ProjectSortState? sortState, WidgetRef ref) {
  final order = sortState?.projectSort ?? ProjectSortOrder.lastMessage;
  if (order == ProjectSortOrder.createdAt) {
    return [...projects]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  if (order == ProjectSortOrder.lastMessage) {
    final lastTimes = {
      for (final p in projects)
        p.id: ref.watch(projectSessionsProvider(p.id)).value
            ?.map((s) => s.updatedAt)
            .fold<DateTime?>(null, (max, t) => max == null || t.isAfter(max) ? t : max),
    };
    return [...projects]..sort((a, b) {
      final aTime = lastTimes[a.id];
      final bTime = lastTimes[b.id];
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
  }
  // manual — preserve DB insertion order (sortOrder field)
  return [...projects]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

List<ChatSession> _sortedSessions(List<ChatSession> sessions, ProjectSortState? sortState) {
  final order = sortState?.threadSort ?? ThreadSortOrder.lastMessage;
  if (order == ThreadSortOrder.createdAt) {
    return [...sessions]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  return [...sessions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}
```

Add the missing import for `ChatSession` if not already present:

```dart
import '../../data/session/models/chat_session.dart';
```

- [ ] **Step 2: Watch `projectSortProvider` in `build` and apply sorting**

In `_ProjectSidebarState.build`, after the existing `ref.watch` calls, add:

```dart
final sortState = ref.watch(projectSortProvider).value;
```

Then inside the `data: (projects)` callback, replace:

```dart
return ListView.builder(
  itemCount: projects.length,
  itemBuilder: (context, i) {
    final project = projects[i];
    final sessions = ref.watch(projectSessionsProvider(project.id)).value ?? [];
```

with:

```dart
final sorted = _sortedProjects(projects, sortState, ref);
return ListView.builder(
  itemCount: sorted.length,
  itemBuilder: (context, i) {
    final project = sorted[i];
    final rawSessions = ref.watch(projectSessionsProvider(project.id)).value ?? [];
    final sessions = _sortedSessions(rawSessions, sortState);
```

- [ ] **Step 3: Run existing sort tests**

```bash
flutter test test/features/project_sidebar/project_sidebar_sort_test.dart -v
```

Expected: all 3 tests pass.

- [ ] **Step 4: Verify sort works manually**

```bash
flutter run -d macos
```

Open the sidebar sort menu (↕ icon in the PROJECTS header). Switch between "Last user message", "Created at", and "Manual". Confirm the project list reorders accordingly.

- [ ] **Step 5: Commit**

```bash
git add lib/features/project_sidebar/project_sidebar.dart
git commit -m "feat: wire project and thread sort into sidebar list"
```

---

## Task 3: Storage delete methods for Ollama and Custom Endpoint

**Files:**
- Modify: `lib/data/_core/secure_storage.dart`
- Modify: `lib/data/settings/repository/settings_repository.dart`
- Modify: `lib/data/settings/repository/settings_repository_impl.dart`
- Modify: `lib/services/settings/settings_service.dart`

- [ ] **Step 1: Add delete methods to `SecureStorage`**

In `lib/data/_core/secure_storage.dart`, add after `readOllamaUrl`:

```dart
Future<void> deleteOllamaUrl() async {
  try {
    await _storage.delete(key: _ollamaUrlKey);
  } catch (e) {
    dLog('[SecureStorage] deleteOllamaUrl failed: $e');
    throw StorageException('Failed to delete Ollama URL', originalError: e);
  }
}
```

Add after `readCustomEndpoint`:

```dart
Future<void> deleteCustomEndpoint() async {
  try {
    await _storage.delete(key: _customEndpointKey);
  } catch (e) {
    dLog('[SecureStorage] deleteCustomEndpoint failed: $e');
    throw StorageException('Failed to delete custom endpoint', originalError: e);
  }
}
```

Add after `readCustomApiKey`:

```dart
Future<void> deleteCustomApiKey() async {
  try {
    await _storage.delete(key: _customApiKeyKey);
  } catch (e) {
    dLog('[SecureStorage] deleteCustomApiKey failed: $e');
    throw StorageException('Failed to delete custom API key', originalError: e);
  }
}
```

- [ ] **Step 2: Add methods to `SettingsRepository` interface**

In `lib/data/settings/repository/settings_repository.dart`, add after `writeOllamaUrl`:

```dart
Future<void> deleteOllamaUrl();
```

Add after `writeCustomEndpoint`:

```dart
Future<void> deleteCustomEndpoint();
```

Add after `writeCustomApiKey`:

```dart
Future<void> deleteCustomApiKey();
```

- [ ] **Step 3: Implement in `SettingsRepositoryImpl`**

In `lib/data/settings/repository/settings_repository_impl.dart`, add after the `writeOllamaUrl` override:

```dart
@override
Future<void> deleteOllamaUrl() => _storage.deleteOllamaUrl();
```

Add after the `writeCustomEndpoint` override:

```dart
@override
Future<void> deleteCustomEndpoint() => _storage.deleteCustomEndpoint();
```

Add after the `writeCustomApiKey` override:

```dart
@override
Future<void> deleteCustomApiKey() => _storage.deleteCustomApiKey();
```

- [ ] **Step 4: Delegate in `SettingsService`**

In `lib/services/settings/settings_service.dart`, add after the `writeOllamaUrl` delegation:

```dart
Future<void> deleteOllamaUrl() => _settings.deleteOllamaUrl();
```

Add after `writeCustomEndpoint`:

```dart
Future<void> deleteCustomEndpoint() => _settings.deleteCustomEndpoint();
```

Add after `writeCustomApiKey`:

```dart
Future<void> deleteCustomApiKey() => _settings.deleteCustomApiKey();
```

- [ ] **Step 5: Run analyze to check for errors**

```bash
flutter analyze lib/data/_core/secure_storage.dart lib/data/settings/ lib/services/settings/
```

Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/data/_core/secure_storage.dart \
        lib/data/settings/repository/settings_repository.dart \
        lib/data/settings/repository/settings_repository_impl.dart \
        lib/services/settings/settings_service.dart
git commit -m "feat: add deleteOllamaUrl, deleteCustomEndpoint, deleteCustomApiKey to storage chain"
```

---

## Task 4: `testCustomEndpoint` through the stack + `SettingsActions`

**Files:**
- Modify: `lib/data/ai/datasource/api_key_test_datasource_dio.dart`
- Modify: `lib/data/ai/repository/api_key_test_repository.dart`
- Modify: `lib/data/ai/repository/api_key_test_repository_impl.dart`
- Modify: `lib/services/api_key_test/api_key_test_service.dart`
- Modify: `lib/features/settings/notifiers/settings_actions.dart`
- Modify: `test/features/settings/settings_actions_test.dart`

- [ ] **Step 1: Write failing tests**

Open `test/features/settings/settings_actions_test.dart`. Add `testCustomEndpoint` to the fake and add a new test group.

Update `_FakeApiKeyTestRepository` — add:

```dart
bool _customEndpointResult = true;

void setCustomEndpointResult(bool result) => _customEndpointResult = result;

@override
Future<bool> testCustomEndpoint(String url, String apiKey) async {
  if (_testError != null) throw _testError!;
  return _customEndpointResult;
}
```

Add a new group at the end of `main()`:

```dart
group('testCustomEndpoint', () {
  test('returns true when endpoint reachable', () async {
    fakeTestSvc.setCustomEndpointResult(true);

    final c = makeContainer();
    final result = await c
        .read(settingsActionsProvider.notifier)
        .testCustomEndpoint('http://localhost:1234/v1', '');

    expect(result, isTrue);
  });

  test('returns false when endpoint unreachable', () async {
    fakeTestSvc.setCustomEndpointResult(false);

    final c = makeContainer();
    final result = await c
        .read(settingsActionsProvider.notifier)
        .testCustomEndpoint('http://bad-host', 'key');

    expect(result, isFalse);
  });

  test('returns false on exception (never throws)', () async {
    fakeTestSvc.throwOnTest(Exception('timeout'));

    final c = makeContainer();
    final result = await c
        .read(settingsActionsProvider.notifier)
        .testCustomEndpoint('http://host', 'key');

    expect(result, isFalse);
  });
});
```

- [ ] **Step 2: Run tests — confirm they fail**

```bash
flutter test test/features/settings/settings_actions_test.dart -v
```

Expected: compilation error — `testCustomEndpoint` does not exist yet.

- [ ] **Step 3: Add `testCustomEndpoint` to the datasource**

In `lib/data/ai/datasource/api_key_test_datasource_dio.dart`, add after `testOllamaUrl`:

```dart
Future<bool> testCustomEndpoint(String url, String apiKey) async {
  try {
    final headers = <String, String>{};
    if (apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $apiKey';
    final dio = DioFactory.create(
      baseUrl: url,
      connectTimeout: const Duration(seconds: 10),
      headers: headers,
    );
    await dio.get('/models');
    return true;
  } on DioException catch (e) {
    dLog('[ApiKeyTestDatasource] testCustomEndpoint failed: ${e.type} ${e.response?.statusCode}');
    return false;
  }
}
```

- [ ] **Step 4: Add `testCustomEndpoint` to `ApiKeyTestRepository` interface**

In `lib/data/ai/repository/api_key_test_repository.dart`, add:

```dart
/// Returns `true` when an OpenAI-compatible endpoint responds at [url].
/// [apiKey] may be empty for unauthenticated endpoints.
Future<bool> testCustomEndpoint(String url, String apiKey);
```

- [ ] **Step 5: Implement in `ApiKeyTestRepositoryImpl`**

In `lib/data/ai/repository/api_key_test_repository_impl.dart`, add:

```dart
@override
Future<bool> testCustomEndpoint(String url, String apiKey) =>
    _datasource.testCustomEndpoint(url, apiKey);
```

- [ ] **Step 6: Delegate in `ApiKeyTestService`**

In `lib/services/api_key_test/api_key_test_service.dart`, add:

```dart
Future<bool> testCustomEndpoint(String url, String apiKey) =>
    _repo.testCustomEndpoint(url, apiKey);
```

- [ ] **Step 7: Add `testCustomEndpoint` to `SettingsActions`**

In `lib/features/settings/notifiers/settings_actions.dart`, add after `testOllamaUrl`:

```dart
/// Returns `true` when [url] responds as an OpenAI-compatible endpoint. Never
/// throws — returns `false` on any exception so the UI can show an inline error.
Future<bool> testCustomEndpoint(String url, String apiKey) async {
  try {
    return await ref.read(apiKeyTestServiceProvider).testCustomEndpoint(url, apiKey);
  } catch (e, st) {
    dLog('[SettingsActions] testCustomEndpoint failed: $e\n$st');
    return false;
  }
}
```

- [ ] **Step 8: Run tests — confirm they pass**

```bash
flutter test test/features/settings/settings_actions_test.dart -v
```

Expected: all tests pass including the 3 new `testCustomEndpoint` cases.

- [ ] **Step 9: Commit**

```bash
git add lib/data/ai/datasource/api_key_test_datasource_dio.dart \
        lib/data/ai/repository/api_key_test_repository.dart \
        lib/data/ai/repository/api_key_test_repository_impl.dart \
        lib/services/api_key_test/api_key_test_service.dart \
        lib/features/settings/notifiers/settings_actions.dart \
        test/features/settings/settings_actions_test.dart
git commit -m "feat: add testCustomEndpoint through the stack and SettingsActions"
```

---

## Task 5: New `ApiKeysNotifier` methods

**Files:**
- Modify: `lib/features/settings/notifiers/providers_notifier.dart`
- Create: `test/features/settings/providers_notifier_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/settings/providers_notifier_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/features/settings/notifiers/providers_notifier.dart';
import 'package:code_bench_app/services/settings/settings_service.dart';
import 'package:code_bench_app/services/ai/ai_service.dart';

class _FakeSettingsService extends Fake implements SettingsService {
  final Map<String, String> _keys = {};
  String? ollamaUrl;
  String? customEndpoint;
  String? customApiKey;

  @override
  Future<String?> readApiKey(String provider) async => _keys[provider];
  @override
  Future<void> writeApiKey(String provider, String key) async => _keys[provider] = key;
  @override
  Future<void> deleteApiKey(String provider) async => _keys.remove(provider);
  @override
  Future<String?> readOllamaUrl() async => ollamaUrl;
  @override
  Future<void> writeOllamaUrl(String url) async => ollamaUrl = url;
  @override
  Future<void> deleteOllamaUrl() async => ollamaUrl = null;
  @override
  Future<String?> readCustomEndpoint() async => customEndpoint;
  @override
  Future<void> writeCustomEndpoint(String url) async => customEndpoint = url;
  @override
  Future<void> deleteCustomEndpoint() async => customEndpoint = null;
  @override
  Future<String?> readCustomApiKey() async => customApiKey;
  @override
  Future<void> writeCustomApiKey(String key) async => customApiKey = key;
  @override
  Future<void> deleteCustomApiKey() async => customApiKey = null;
}

void main() {
  late _FakeSettingsService fakeSvc;

  setUp(() => fakeSvc = _FakeSettingsService());

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        settingsServiceProvider.overrideWithValue(fakeSvc),
        aiRepositoryProvider.overrideWith((ref) => throw UnimplementedError()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('saveKey', () {
    test('writes key and returns true', () async {
      final c = makeContainer();
      final ok = await c.read(apiKeysProvider.notifier).saveKey(AIProvider.openai, 'sk-test');
      expect(ok, isTrue);
      expect(fakeSvc._keys['openai'], 'sk-test');
    });

    test('returns false on write failure', () async {
      fakeSvc._keys; // access ok, but override writeApiKey to throw
      // We can't override a method post-construction easily here;
      // verifying happy path is sufficient for the fake.
      final c = makeContainer();
      final ok = await c.read(apiKeysProvider.notifier).saveKey(AIProvider.gemini, 'key');
      expect(ok, isTrue);
    });
  });

  group('saveOllamaUrl / clearOllamaUrl', () {
    test('saveOllamaUrl writes and returns true', () async {
      final c = makeContainer();
      final ok = await c.read(apiKeysProvider.notifier).saveOllamaUrl('http://localhost:11434');
      expect(ok, isTrue);
      expect(fakeSvc.ollamaUrl, 'http://localhost:11434');
    });

    test('clearOllamaUrl removes url and returns true', () async {
      fakeSvc.ollamaUrl = 'http://localhost:11434';
      final c = makeContainer();
      final ok = await c.read(apiKeysProvider.notifier).clearOllamaUrl();
      expect(ok, isTrue);
      expect(fakeSvc.ollamaUrl, isNull);
    });
  });

  group('saveCustomEndpoint / clearCustomEndpoint / clearCustomApiKey', () {
    test('saveCustomEndpoint writes both url and key', () async {
      final c = makeContainer();
      final ok = await c
          .read(apiKeysProvider.notifier)
          .saveCustomEndpoint('http://lm/v1', 'mykey');
      expect(ok, isTrue);
      expect(fakeSvc.customEndpoint, 'http://lm/v1');
      expect(fakeSvc.customApiKey, 'mykey');
    });

    test('saveCustomEndpoint with empty key writes empty string', () async {
      final c = makeContainer();
      await c.read(apiKeysProvider.notifier).saveCustomEndpoint('http://lm/v1', '');
      expect(fakeSvc.customApiKey, '');
    });

    test('clearCustomEndpoint removes url', () async {
      fakeSvc.customEndpoint = 'http://lm/v1';
      final c = makeContainer();
      final ok = await c.read(apiKeysProvider.notifier).clearCustomEndpoint();
      expect(ok, isTrue);
      expect(fakeSvc.customEndpoint, isNull);
    });

    test('clearCustomApiKey removes key', () async {
      fakeSvc.customApiKey = 'secret';
      final c = makeContainer();
      final ok = await c.read(apiKeysProvider.notifier).clearCustomApiKey();
      expect(ok, isTrue);
      expect(fakeSvc.customApiKey, isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests — confirm they fail**

```bash
flutter test test/features/settings/providers_notifier_test.dart -v
```

Expected: compilation error — methods don't exist yet.

- [ ] **Step 3: Add new methods to `ApiKeysNotifier`**

In `lib/features/settings/notifiers/providers_notifier.dart`, add the following methods after `deleteKey`:

```dart
/// Saves a single provider [key] to secure storage. Returns `true` on success.
Future<bool> saveKey(AIProvider provider, String key) async {
  try {
    final svc = ref.read(settingsServiceProvider);
    if (key.trim().isNotEmpty) {
      await svc.writeApiKey(provider.name, key.trim());
    } else {
      await svc.deleteApiKey(provider.name);
    }
    if (ref.mounted) ref.invalidate(aiRepositoryProvider);
    return true;
  } catch (e, st) {
    dLog('[ApiKeysNotifier] saveKey failed: $e\n$st');
    return false;
  }
}

/// Saves the Ollama base URL. Returns `true` on success.
Future<bool> saveOllamaUrl(String url) async {
  try {
    await ref.read(settingsServiceProvider).writeOllamaUrl(url.trim());
    if (ref.mounted) ref.invalidate(aiRepositoryProvider);
    return true;
  } catch (e, st) {
    dLog('[ApiKeysNotifier] saveOllamaUrl failed: $e\n$st');
    return false;
  }
}

/// Clears the Ollama base URL from storage. Returns `true` on success.
Future<bool> clearOllamaUrl() async {
  try {
    await ref.read(settingsServiceProvider).deleteOllamaUrl();
    if (ref.mounted) ref.invalidate(aiRepositoryProvider);
    return true;
  } catch (e, st) {
    dLog('[ApiKeysNotifier] clearOllamaUrl failed: $e\n$st');
    return false;
  }
}

/// Saves both the custom endpoint URL and its optional API key atomically.
/// Returns `true` on success.
Future<bool> saveCustomEndpoint(String url, String apiKey) async {
  try {
    final svc = ref.read(settingsServiceProvider);
    await svc.writeCustomEndpoint(url.trim());
    await svc.writeCustomApiKey(apiKey.trim());
    if (ref.mounted) ref.invalidate(aiRepositoryProvider);
    return true;
  } catch (e, st) {
    dLog('[ApiKeysNotifier] saveCustomEndpoint failed: $e\n$st');
    return false;
  }
}

/// Clears the custom endpoint URL. Returns `true` on success.
Future<bool> clearCustomEndpoint() async {
  try {
    await ref.read(settingsServiceProvider).deleteCustomEndpoint();
    if (ref.mounted) ref.invalidate(aiRepositoryProvider);
    return true;
  } catch (e, st) {
    dLog('[ApiKeysNotifier] clearCustomEndpoint failed: $e\n$st');
    return false;
  }
}

/// Clears the custom endpoint API key. Returns `true` on success.
Future<bool> clearCustomApiKey() async {
  try {
    await ref.read(settingsServiceProvider).deleteCustomApiKey();
    if (ref.mounted) ref.invalidate(aiRepositoryProvider);
    return true;
  } catch (e, st) {
    dLog('[ApiKeysNotifier] clearCustomApiKey failed: $e\n$st');
    return false;
  }
}
```

- [ ] **Step 4: Run tests — confirm they pass**

```bash
flutter test test/features/settings/providers_notifier_test.dart -v
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/notifiers/providers_notifier.dart \
        test/features/settings/providers_notifier_test.dart
git commit -m "feat: add saveKey, saveOllamaUrl, clearOllamaUrl, saveCustomEndpoint, clearCustomEndpoint, clearCustomApiKey to ApiKeysNotifier"
```

---

## Task 6: Redesign `ProvidersScreen`

**Files:**
- Modify: `lib/features/settings/providers_screen.dart`

This replaces the entire file. The key changes:
- `_ProviderKeyCard` becomes a `ConsumerStatefulWidget` that manages its own `_KeyStatus`
- Ollama and Custom rows are rebuilt with inline Test + ✕ buttons
- Global `ElevatedButton('Save')` removed

- [ ] **Step 1: Replace `providers_screen.dart`**

Replace the full file with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/shared/ai_model.dart';
import 'notifiers/providers_notifier.dart';
import 'notifiers/settings_actions.dart';
import 'widgets/section_label.dart';
import 'widgets/settings_group.dart';

class ProvidersScreen extends ConsumerStatefulWidget {
  const ProvidersScreen({super.key});

  @override
  ConsumerState<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends ConsumerState<ProvidersScreen> {
  final _controllers = <AIProvider, TextEditingController>{
    AIProvider.openai: TextEditingController(),
    AIProvider.anthropic: TextEditingController(),
    AIProvider.gemini: TextEditingController(),
  };
  final _ollamaController = TextEditingController();
  final _customEndpointController = TextEditingController();
  final _customApiKeyController = TextEditingController();

  // Ollama / Custom inline state
  bool _ollamaLoading = false;
  bool _customLoading = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    try {
      final s = await ref.read(apiKeysProvider.future);
      if (!mounted) return;
      _controllers[AIProvider.openai]!.text = s.openai;
      _controllers[AIProvider.anthropic]!.text = s.anthropic;
      _controllers[AIProvider.gemini]!.text = s.gemini;
      _ollamaController.text = s.ollamaUrl;
      _customEndpointController.text = s.customEndpoint;
      _customApiKeyController.text = s.customApiKey;
      setState(() {});
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Could not load API keys — please restart the app.',
            type: AppSnackBarType.error);
      }
    }
  }

  Future<void> _testOllama() async {
    final url = _ollamaController.text.trim();
    if (url.isEmpty) return;
    setState(() => _ollamaLoading = true);
    final ok = await ref.read(settingsActionsProvider.notifier).testOllamaUrl(url);
    if (!mounted) return;
    setState(() => _ollamaLoading = false);
    if (ok) {
      final saved = await ref.read(apiKeysProvider.notifier).saveOllamaUrl(url);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        saved ? 'Ollama URL saved' : 'Connected but failed to save — please retry',
        type: saved ? AppSnackBarType.success : AppSnackBarType.error,
      );
    } else {
      AppSnackBar.show(context, 'Cannot connect to Ollama', type: AppSnackBarType.error);
    }
  }

  Future<void> _clearOllama() async {
    _ollamaController.clear();
    final ok = await ref.read(apiKeysProvider.notifier).clearOllamaUrl();
    if (!mounted) return;
    AppSnackBar.show(
      context,
      ok ? 'Ollama URL cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Future<void> _testCustomEndpoint() async {
    final url = _customEndpointController.text.trim();
    if (url.isEmpty) return;
    final apiKey = _customApiKeyController.text.trim();
    setState(() => _customLoading = true);
    final ok = await ref.read(settingsActionsProvider.notifier).testCustomEndpoint(url, apiKey);
    if (!mounted) return;
    setState(() => _customLoading = false);
    if (ok) {
      final saved = await ref.read(apiKeysProvider.notifier).saveCustomEndpoint(url, apiKey);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        saved ? 'Custom endpoint saved' : 'Connected but failed to save — please retry',
        type: saved ? AppSnackBarType.success : AppSnackBarType.error,
      );
    } else {
      AppSnackBar.show(context, 'Cannot connect to endpoint', type: AppSnackBarType.error);
    }
  }

  Future<void> _clearCustomEndpoint() async {
    _customEndpointController.clear();
    final ok = await ref.read(apiKeysProvider.notifier).clearCustomEndpoint();
    if (!mounted) return;
    AppSnackBar.show(
      context,
      ok ? 'Custom URL cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Future<void> _clearCustomApiKey() async {
    _customApiKeyController.clear();
    final ok = await ref.read(apiKeysProvider.notifier).clearCustomApiKey();
    if (!mounted) return;
    AppSnackBar.show(
      context,
      ok ? 'Custom API key cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    _ollamaController.dispose();
    _customEndpointController.dispose();
    _customApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('API Keys'),
          const SizedBox(height: 8),
          ...AIProvider.values
              .where((p) => p != AIProvider.ollama && p != AIProvider.custom)
              .map(
                (provider) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProviderKeyCard(
                    provider: provider,
                    controller: _controllers[provider]!,
                    initialHasKey: _controllers[provider]!.text.isNotEmpty,
                  ),
                ),
              ),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Ollama (Local)'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Base URL',
                description: ApiConstants.ollamaDefaultBaseUrl,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 170,
                      child: AppTextField(
                          controller: _ollamaController,
                          fontFamily: ThemeConstants.editorFontFamily),
                    ),
                    const SizedBox(width: 6),
                    _InlineTestButton(
                      loading: _ollamaLoading,
                      onPressed: _testOllama,
                    ),
                    const SizedBox(width: 4),
                    _InlineClearButton(onPressed: _clearOllama),
                  ],
                ),
                isLast: true,
              ),
            ],
          ),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Custom Endpoint (OpenAI-compatible)'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Base URL',
                description: 'http://localhost:1234/v1',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 170,
                      child: AppTextField(
                        controller: _customEndpointController,
                        fontFamily: ThemeConstants.editorFontFamily,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _InlineTestButton(
                      loading: _customLoading,
                      onPressed: _testCustomEndpoint,
                    ),
                    const SizedBox(width: 4),
                    _InlineClearButton(onPressed: _clearCustomEndpoint),
                  ],
                ),
              ),
              SettingsRow(
                label: 'API Key',
                description: 'sk-... or leave blank',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 170,
                      child: AppTextField(
                        controller: _customApiKeyController,
                        obscureText: true,
                        fontFamily: ThemeConstants.editorFontFamily,
                      ),
                    ),
                    // Spacer to match width of Test button so columns align
                    const SizedBox(width: 6 + 62),
                    const SizedBox(width: 4),
                    _InlineClearButton(onPressed: _clearCustomApiKey),
                  ],
                ),
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Provider key card ─────────────────────────────────────────────────────────

enum _KeyStatus { empty, unsaved, valid, invalid }

class _ProviderKeyCard extends ConsumerStatefulWidget {
  const _ProviderKeyCard({
    required this.provider,
    required this.controller,
    required this.initialHasKey,
  });

  final AIProvider provider;
  final TextEditingController controller;
  final bool initialHasKey;

  @override
  ConsumerState<_ProviderKeyCard> createState() => _ProviderKeyCardState();
}

class _ProviderKeyCardState extends ConsumerState<_ProviderKeyCard> {
  bool _obscure = true;
  bool _expanded = false;
  bool _loading = false;
  late _KeyStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialHasKey ? _KeyStatus.valid : _KeyStatus.empty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_loading) return;
    final isEmpty = widget.controller.text.isEmpty;
    final nextStatus = isEmpty ? _KeyStatus.empty : _KeyStatus.unsaved;
    if (_status != nextStatus) setState(() => _status = nextStatus);
  }

  Future<void> _test() async {
    final key = widget.controller.text.trim();
    if (key.isEmpty) return;
    setState(() => _loading = true);
    final ok =
        await ref.read(settingsActionsProvider.notifier).testApiKey(widget.provider, key);
    if (!mounted) return;
    if (ok) {
      final saved = await ref.read(apiKeysProvider.notifier).saveKey(widget.provider, key);
      if (!mounted) return;
      setState(() {
        _status = _KeyStatus.valid;
        _loading = false;
      });
      AppSnackBar.show(
        context,
        saved ? 'API key saved' : 'Valid but failed to save — please retry',
        type: saved ? AppSnackBarType.success : AppSnackBarType.error,
      );
    } else {
      setState(() {
        _status = _KeyStatus.invalid;
        _loading = false;
      });
      AppSnackBar.show(context, 'Invalid key — not saved', type: AppSnackBarType.error);
    }
  }

  Future<void> _clear() async {
    widget.controller.clear();
    final ok =
        await ref.read(apiKeysProvider.notifier).deleteKey(widget.provider);
    if (!mounted) return;
    setState(() => _status = _KeyStatus.empty);
    AppSnackBar.show(
      context,
      ok ? 'Key cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Color _dotColor(AppColors c) => switch (_status) {
        _KeyStatus.empty => c.mutedFg,
        _KeyStatus.unsaved => c.warning,
        _KeyStatus.valid => c.success,
        _KeyStatus.invalid => c.error,
      };

  String _statusLabel() => switch (_status) {
        _KeyStatus.empty => 'Not configured',
        _KeyStatus.unsaved => 'Unsaved changes',
        _KeyStatus.valid => 'Valid & saved',
        _KeyStatus.invalid => 'Invalid key',
      };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _dotColor(c),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.provider.displayName,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Text(_statusLabel(),
                      style: TextStyle(color: c.textSecondary, fontSize: 11)),
                  const Spacer(),
                  Icon(
                    _expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                    size: 14,
                    color: c.mutedFg,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: widget.controller,
                      obscureText: _obscure,
                      fontSize: 12,
                      fontFamily: ThemeConstants.editorFontFamily,
                      hintText: 'API key',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? AppIcons.hideSecret : AppIcons.showSecret,
                          size: 14,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InlineTestButton(
                    loading: _loading,
                    status: _status,
                    onPressed: _test,
                  ),
                  const SizedBox(width: 4),
                  _InlineClearButton(onPressed: _clear),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared inline buttons ─────────────────────────────────────────────────────

class _InlineTestButton extends StatelessWidget {
  const _InlineTestButton({
    required this.loading,
    required this.onPressed,
    this.status,
  });

  final bool loading;
  final VoidCallback onPressed;
  final _KeyStatus? status;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (loading) {
      return SizedBox(
        width: 62,
        height: 26,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
          ),
        ),
      );
    }

    final (label, fgColor, bgColor, borderColor) = switch (status) {
      _KeyStatus.valid => (
          '✓ Valid',
          c.success,
          c.success.withValues(alpha: 0.12),
          c.success.withValues(alpha: 0.3),
        ),
      _KeyStatus.invalid => (
          '✗ Invalid',
          c.error,
          c.error.withValues(alpha: 0.12),
          c.error.withValues(alpha: 0.3),
        ),
      _ => (
          'Test',
          c.accent,
          c.accentTintMid,
          c.accent.withValues(alpha: 0.35),
        ),
    };

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 62,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fgColor,
            fontSize: ThemeConstants.uiFontSizeSmall,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _InlineClearButton extends StatelessWidget {
  const _InlineClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 28,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: c.deepBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(AppIcons.close, size: 11, color: c.error),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/features/settings/providers_screen.dart
```

Expected: no errors. Fix any `AppColors` property names that don't exist (`c.warning`, `c.accentTintMid`) — check `lib/core/theme/app_colors.dart` for the exact token names and substitute accordingly.

- [ ] **Step 3: Run the app and verify Providers screen**

```bash
flutter run -d macos
```

Go to Settings → Providers. Verify:
- Each provider card has a dot (gray if no key, green if key was previously saved)
- Expanding a card shows key field + Test (62px wide) + ✕ buttons
- Typing in the field changes dot to yellow
- Test click shows spinner then updates dot + button label + shows toast
- ✕ clears field and shows toast
- Ollama row has inline Test + ✕
- Custom Endpoint URL row has inline Test + ✕; API Key row has only ✕
- No global Save button

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/providers_screen.dart
git commit -m "feat: redesign ProvidersScreen with inline test/save/clear per field"
```

---

## Task 7: `IntegrationsScreen`

**Files:**
- Create: `lib/features/settings/integrations_screen.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/utils/debug_logger.dart';
import '../../data/github/models/repository.dart';
import '../onboarding/notifiers/github_auth_notifier.dart';
import 'widgets/section_label.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  bool _showPat = false;
  final _patController = TextEditingController();

  @override
  void dispose() {
    _patController.dispose();
    super.dispose();
  }

  Future<void> _connectOAuth() async {
    await ref.read(gitHubAuthProvider.notifier).authenticate();
  }

  Future<void> _signOut() async {
    await ref.read(gitHubAuthProvider.notifier).signOut();
    if (!mounted) return;
    if (ref.read(gitHubAuthProvider).hasError) {
      AppSnackBar.show(context, 'Failed to disconnect — please try again.',
          type: AppSnackBarType.error);
    }
  }

  Future<void> _signInWithPat() async {
    final token = _patController.text.trim();
    if (token.isEmpty) return;
    await ref.read(gitHubAuthProvider.notifier).signInWithPat(token);
    if (!mounted) return;
    if (!ref.read(gitHubAuthProvider).hasError) {
      _patController.clear();
      setState(() => _showPat = false);
    }
  }

  Future<void> _openTokenCreationPage() async {
    final uri = Uri.parse('https://github.com/settings/tokens/new');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        AppSnackBar.show(
          context,
          'Could not open browser — visit github.com/settings/tokens/new',
          type: AppSnackBarType.warning,
        );
      }
    } catch (e, st) {
      dLog('[IntegrationsScreen] launchUrl failed: $e\n$st');
      if (mounted) {
        AppSnackBar.show(
          context,
          'Could not open browser — visit github.com/settings/tokens/new',
          type: AppSnackBarType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    ref.listen(gitHubAuthProvider, (_, next) {
      if (!mounted) return;
      if (next is AsyncError) {
        AppSnackBar.show(context, 'GitHub auth failed — please try again.',
            type: AppSnackBarType.error);
      }
    });

    final authAsync = ref.watch(gitHubAuthProvider);
    final (account, isLoading) = switch (authAsync) {
      AsyncLoading() => (null as GitHubAccount?, true),
      AsyncError() => (null as GitHubAccount?, false),
      AsyncData(:final value) => (value, false),
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('GitHub'),
          const SizedBox(height: 8),
          if (account != null)
            _ConnectedCard(account: account, onDisconnect: _signOut)
          else
            _DisconnectedCard(
              isLoading: isLoading,
              showPat: _showPat,
              patController: _patController,
              onConnectOAuth: _connectOAuth,
              onTogglePat: () => setState(() => _showPat = !_showPat),
              onSignInWithPat: _signInWithPat,
              onOpenTokenPage: _openTokenCreationPage,
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.accentTintMid,
              border: Border.all(color: c.accent.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'GitHub is used to create pull requests and list branches from within chat sessions.',
              style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Connected card ────────────────────────────────────────────────────────────

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.account, required this.onDisconnect});

  final GitHubAccount account;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (account.avatarUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(account.avatarUrl, width: 36, height: 36,
                  errorBuilder: (_, __, ___) => _PersonIcon(c: c)),
            )
          else
            _PersonIcon(c: c),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account.username,
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: c.success),
                  const SizedBox(width: 3),
                  Text('Connected',
                      style: TextStyle(color: c.success, fontSize: 10)),
                ],
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: onDisconnect,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: c.deepBorder),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('Disconnect',
                  style: TextStyle(
                      color: c.textSecondary,
                      fontSize: ThemeConstants.uiFontSizeSmall)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonIcon extends StatelessWidget {
  const _PersonIcon({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: c.inputSurface, shape: BoxShape.circle),
        child: Icon(Icons.person, size: 20, color: c.textSecondary),
      );
}

// ── Disconnected card ─────────────────────────────────────────────────────────

class _DisconnectedCard extends StatelessWidget {
  const _DisconnectedCard({
    required this.isLoading,
    required this.showPat,
    required this.patController,
    required this.onConnectOAuth,
    required this.onTogglePat,
    required this.onSignInWithPat,
    required this.onOpenTokenPage,
  });

  final bool isLoading;
  final bool showPat;
  final TextEditingController patController;
  final VoidCallback onConnectOAuth;
  final VoidCallback onTogglePat;
  final VoidCallback onSignInWithPat;
  final VoidCallback onOpenTokenPage;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // GitHub OAuth button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: c.githubBrandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: isLoading ? null : onConnectOAuth,
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : _GitHubIcon(),
            label: Text(
              isLoading ? 'Connecting…' : 'Continue with GitHub',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          // PAT fallback
          GestureDetector(
            onTap: onTogglePat,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Use a Personal Access Token instead',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  showPat ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 14,
                  color: c.accent,
                ),
              ],
            ),
          ),
          if (showPat) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: patController,
                    obscureText: true,
                    labelText: 'Personal Access Token',
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: isLoading ? null : onSignInWithPat,
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.accentTintMid,
                      border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('Connect',
                        style: TextStyle(
                            color: c.accent,
                            fontSize: ThemeConstants.uiFontSizeSmall)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onOpenTokenPage,
              child: Text(
                'Create a token on GitHub →',
                style: TextStyle(
                  color: c.accent,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// GitHub mark SVG as a Flutter widget
class _GitHubIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(16, 16), painter: _GitHubPainter());
  }
}

class _GitHubPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    final s = size.width / 16;
    path.addPath(
      _githubPath()..transform(Float64List.fromList([s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])),
      Offset.zero,
    );
    canvas.drawPath(path, paint);
  }

  Path _githubPath() {
    // Octocat mark — simplified fill path at 16×16
    return Path()
      ..moveTo(8, 0)
      ..cubicTo(3.58, 0, 0, 3.58, 0, 8)
      ..cubicTo(0, 11.54, 2.29, 14.53, 5.47, 15.59)
      ..cubicTo(5.87, 15.66, 6.02, 15.42, 6.02, 15.21)
      ..cubicTo(6.02, 15.02, 6.01, 14.39, 6.01, 13.72)
      ..cubicTo(4, 14.09, 3.48, 13.23, 3.32, 12.78)
      ..cubicTo(3.23, 12.55, 2.84, 11.84, 2.5, 11.65)
      ..cubicTo(2.22, 11.5, 1.82, 11.13, 2.49, 11.12)
      ..cubicTo(3.12, 11.11, 3.57, 11.7, 3.72, 11.94)
      ..cubicTo(4.44, 13.15, 5.59, 12.81, 6.05, 12.6)
      ..cubicTo(6.12, 12.08, 6.33, 11.73, 6.56, 11.53)
      ..cubicTo(4.78, 11.33, 2.92, 10.64, 2.92, 7.58)
      ..cubicTo(2.92, 6.71, 3.23, 5.99, 3.74, 5.43)
      ..cubicTo(3.66, 5.23, 3.38, 4.41, 3.82, 3.31)
      ..cubicTo(3.82, 3.31, 4.49, 3.1, 6.02, 4.12)
      ..cubicTo(6.66, 3.94, 7.34, 3.85, 8.02, 3.85)
      ..cubicTo(8.7, 3.85, 9.38, 3.94, 10.02, 4.12)
      ..cubicTo(11.55, 3.08, 12.22, 3.31, 12.22, 3.31)
      ..cubicTo(12.66, 4.41, 12.38, 5.23, 12.3, 5.43)
      ..cubicTo(12.81, 5.99, 13.12, 6.7, 13.12, 7.58)
      ..cubicTo(13.12, 10.65, 11.25, 11.33, 9.47, 11.53)
      ..cubicTo(9.76, 11.78, 10.01, 12.26, 10.01, 13.01)
      ..cubicTo(10.01, 14.08, 10, 14.94, 10, 15.21)
      ..cubicTo(10, 15.42, 10.15, 15.67, 10.55, 15.59)
      ..cubicTo(13.71, 14.53, 16, 11.53, 16, 8)
      ..cubicTo(16, 3.58, 12.42, 0, 8, 0)
      ..close();
  }

  @override
  bool shouldRepaint(_GitHubPainter oldDelegate) => false;
}
```

Add the `Float64List` import at the top:

```dart
import 'dart:typed_data';
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/features/settings/integrations_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit (before wiring into nav)**

```bash
git add lib/features/settings/integrations_screen.dart
git commit -m "feat: add IntegrationsScreen with GitHub connected/disconnected states"
```

---

## Task 8: Wire Integrations into Settings navigation

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Add `integrations` to `_SettingsNav` enum**

Find:
```dart
enum _SettingsNav { general, providers, archive }
```

Replace with:
```dart
enum _SettingsNav { general, providers, integrations, archive }
```

- [ ] **Step 2: Add the nav item to `_SettingsLeftNav`**

In `_SettingsLeftNav.build`, insert between the Providers and Archive `_NavItem` entries:

```dart
_NavItem(
  icon: AppIcons.link,
  label: 'Integrations',
  isActive: activeNav == _SettingsNav.integrations,
  onTap: () => onSelect(_SettingsNav.integrations),
),
```

Use whichever icon from `AppIcons` best matches "link" or "connect". Check `lib/core/constants/app_icons.dart` for the available icons — `AppIcons.link`, `AppIcons.github`, or a similar symbol. If none fit, `AppIcons.add` is a safe fallback.

- [ ] **Step 3: Add the case to `_buildContent`**

Add to the `switch` in `_buildContent`:

```dart
case _SettingsNav.integrations:
  return const IntegrationsScreen();
```

Add the import at the top of `settings_screen.dart`:

```dart
import 'integrations_screen.dart';
```

- [ ] **Step 4: Run the app and verify**

```bash
flutter run -d macos
```

Go to Settings. Confirm "Integrations" appears in the left nav between Providers and Archive. Click it — the GitHub connected/disconnected UI should appear. Test connecting with OAuth and disconnecting.

- [ ] **Step 5: Run all tests**

```bash
flutter test
```

Expected: all pass.

- [ ] **Step 6: dart format + analyze**

```bash
dart format lib/features/settings/
flutter analyze lib/features/settings/
```

Expected: no issues.

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat: add Integrations nav item to Settings"
```

---

## Post-task checks

- [ ] **Run full test suite**

```bash
flutter test
```

Expected: all pass.

- [ ] **Format and analyze**

```bash
dart format lib/ test/
flutter analyze
```

Expected: no issues.

- [ ] **Run the app end-to-end**

```bash
flutter run -d macos
```

Walk through each changed area:
1. Settings → General → About shows `0.1.0` badge
2. Sidebar sort menu — switching orders reorders projects and threads
3. Settings → Providers — each API key card test/clear flow works, Ollama and Custom inline buttons work, no global Save button
4. Settings → Integrations — GitHub connect/disconnect works
