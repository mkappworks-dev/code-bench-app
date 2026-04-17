# Settings Domain Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the monolithic `settings` domain into `settings`, `providers`, `integrations`, and `archive` across the features, data, and service layers — and extract private widgets into `widgets/` subfolders.

**Architecture:** New `providers` domain gets its own data/service/feature layers. `integrations` and `archive` become standalone top-level features reusing existing data/service layers. `SettingsService.wipeAllData()` calls `ProvidersService.deleteAll()` (service-to-service dependency). Tasks 1–5 are purely additive (no deletions). Task 6 does all cleanup in one coordinated sweep so nothing breaks between tasks.

**Tech Stack:** Flutter/Dart, Riverpod (`riverpod_annotation`, `build_runner`), Freezed.

---

## File map

| Action | File |
|--------|------|
| Create | `lib/data/providers/repository/providers_repository.dart` |
| Create | `lib/data/providers/repository/providers_repository_impl.dart` |
| Create | `lib/services/providers/providers_service.dart` |
| Create | `lib/features/providers/providers_screen.dart` |
| Create | `lib/features/providers/notifiers/providers_notifier.dart` |
| Create | `lib/features/providers/notifiers/providers_actions.dart` |
| Create | `lib/features/providers/notifiers/providers_actions_failure.dart` |
| Create | `lib/features/providers/widgets/provider_card_helpers.dart` |
| Create | `lib/features/providers/widgets/api_key_card.dart` |
| Create | `lib/features/providers/widgets/ollama_card.dart` |
| Create | `lib/features/providers/widgets/custom_endpoint_card.dart` |
| Create | `lib/features/integrations/integrations_screen.dart` |
| Create | `lib/features/integrations/widgets/github_connected_card.dart` |
| Create | `lib/features/integrations/widgets/github_disconnected_card.dart` |
| Create | `lib/features/archive/archive_screen.dart` |
| Create | `lib/features/archive/notifiers/archive_actions.dart` |
| Create | `lib/features/archive/notifiers/archive_failure.dart` |
| Create | `lib/features/archive/widgets/archive_error_view.dart` |
| Create | `lib/features/archive/widgets/archived_session_card.dart` |
| Modify | `lib/data/settings/repository/settings_repository.dart` |
| Modify | `lib/data/settings/repository/settings_repository_impl.dart` |
| Modify | `lib/services/settings/settings_service.dart` |
| Modify | `lib/features/settings/settings_screen.dart` |
| Modify | `lib/features/settings/notifiers/settings_actions.dart` |
| Modify | `lib/features/settings/general_screen.dart` |
| Create | `lib/features/settings/widgets/app_dropdown.dart` |
| Delete | `lib/features/settings/providers_screen.dart` |
| Delete | `lib/features/settings/integrations_screen.dart` |
| Delete | `lib/features/settings/archive_screen.dart` |
| Delete | `lib/features/settings/notifiers/providers_notifier.dart` |
| Delete | `lib/features/settings/notifiers/providers_notifier.g.dart` |
| Delete | `lib/features/settings/notifiers/archive_actions.dart` |
| Delete | `lib/features/settings/notifiers/archive_actions.g.dart` |
| Delete | `lib/features/settings/notifiers/archive_failure.dart` |
| Delete | `lib/features/settings/notifiers/archive_failure.freezed.dart` |

---

## Background: What changes and why

**Current problem:** Every screen in settings (`general`, `providers`, `integrations`, `archive`) lives under one `features/settings/` folder. All notifiers share one `notifiers/` sub-folder. Private widgets are inlined into screen files. The data and service layers mirror this — a single `SettingsRepository` and `SettingsService` carry API-key I/O, general prefs, and onboarding all in one place.

**New structure after split:**

```
lib/features/
  settings/          ← general screen + container + settings_actions (onboarding/wipe)
    widgets/         ← section_label, settings_group, app_dropdown (extracted)
  providers/         ← API key cards screen + notifiers
    widgets/         ← api_key_card, ollama_card, custom_endpoint_card, provider_card_helpers
  integrations/      ← GitHub auth screen
    widgets/         ← github_connected_card, github_disconnected_card
  archive/           ← archived sessions screen + notifiers
    widgets/         ← archived_session_card, archive_error_view

lib/data/
  settings/          ← general prefs + onboarding only (slim)
  providers/         ← NEW: API key + Ollama + custom endpoint storage

lib/services/
  settings/          ← general prefs + onboarding + wipeAllData coordinator
  providers/         ← NEW: API key CRUD (delegates to ProvidersRepository)
```

**Widget extraction rule:** Private classes (prefixed `_`) that are widgets get extracted to their feature's `widgets/` subfolder and made public (drop `_` prefix). State classes keep `_` prefix since they stay in the same file as their widget class.

**Import depth:** Widget files at `lib/features/<feature>/widgets/` are one level deeper than screen files, so they use `../../../core/...` instead of `../../core/...`.

---

## Task 1: Create `data/providers/` layer

**Files:**
- Create: `lib/data/providers/repository/providers_repository.dart`
- Create: `lib/data/providers/repository/providers_repository_impl.dart`

- [ ] **Step 1: Create the repository interface**

```dart
// lib/data/providers/repository/providers_repository.dart
abstract interface class ProvidersRepository {
  Future<String?> readApiKey(String provider);
  Future<void> writeApiKey(String provider, String key);
  Future<void> deleteApiKey(String provider);
  Future<String?> readOllamaUrl();
  Future<void> writeOllamaUrl(String url);
  Future<void> deleteOllamaUrl();
  Future<String?> readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url);
  Future<void> deleteCustomEndpoint();
  Future<String?> readCustomApiKey();
  Future<void> writeCustomApiKey(String key);
  Future<void> deleteCustomApiKey();
  Future<void> deleteAllSecureStorage();
}
```

- [ ] **Step 2: Create the repository implementation**

```dart
// lib/data/providers/repository/providers_repository_impl.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/_core/secure_storage.dart';
import 'providers_repository.dart';

part 'providers_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ProvidersRepository providersRepository(Ref ref) => ProvidersRepositoryImpl(ref);

class ProvidersRepositoryImpl implements ProvidersRepository {
  ProvidersRepositoryImpl(this._ref);

  final Ref _ref;

  SecureStorage get _storage => _ref.read(secureStorageProvider);

  @override
  Future<String?> readApiKey(String provider) => _storage.readApiKey(provider);

  @override
  Future<void> writeApiKey(String provider, String key) =>
      _storage.writeApiKey(provider, key);

  @override
  Future<void> deleteApiKey(String provider) => _storage.deleteApiKey(provider);

  @override
  Future<String?> readOllamaUrl() => _storage.readOllamaUrl();

  @override
  Future<void> writeOllamaUrl(String url) => _storage.writeOllamaUrl(url);

  @override
  Future<void> deleteOllamaUrl() => _storage.deleteOllamaUrl();

  @override
  Future<String?> readCustomEndpoint() => _storage.readCustomEndpoint();

  @override
  Future<void> writeCustomEndpoint(String url) => _storage.writeCustomEndpoint(url);

  @override
  Future<void> deleteCustomEndpoint() => _storage.deleteCustomEndpoint();

  @override
  Future<String?> readCustomApiKey() => _storage.readCustomApiKey();

  @override
  Future<void> writeCustomApiKey(String key) => _storage.writeCustomApiKey(key);

  @override
  Future<void> deleteCustomApiKey() => _storage.deleteCustomApiKey();

  @override
  Future<void> deleteAllSecureStorage() => _storage.deleteAll();
}
```

- [ ] **Step 3: Run build_runner**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -10
```

Expected: generates `providers_repository_impl.g.dart`. No errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && git add lib/data/providers/ && git commit -m "feat: add ProvidersRepository — extract API key storage from SettingsRepository"
```

---

## Task 2: Create `services/providers/` layer

**Files:**
- Create: `lib/services/providers/providers_service.dart`

- [ ] **Step 1: Create the service**

```dart
// lib/services/providers/providers_service.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers/repository/providers_repository.dart';
import '../../data/providers/repository/providers_repository_impl.dart';

part 'providers_service.g.dart';

@Riverpod(keepAlive: true)
ProvidersService providersService(Ref ref) =>
    ProvidersService(providers: ref.watch(providersRepositoryProvider));

class ProvidersService {
  ProvidersService({required ProvidersRepository providers})
      : _providers = providers;

  final ProvidersRepository _providers;

  Future<String?> readApiKey(String provider) => _providers.readApiKey(provider);
  Future<void> writeApiKey(String provider, String key) =>
      _providers.writeApiKey(provider, key);
  Future<void> deleteApiKey(String provider) => _providers.deleteApiKey(provider);
  Future<String?> readOllamaUrl() => _providers.readOllamaUrl();
  Future<void> writeOllamaUrl(String url) => _providers.writeOllamaUrl(url);
  Future<void> deleteOllamaUrl() => _providers.deleteOllamaUrl();
  Future<String?> readCustomEndpoint() => _providers.readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url) =>
      _providers.writeCustomEndpoint(url);
  Future<void> deleteCustomEndpoint() => _providers.deleteCustomEndpoint();
  Future<String?> readCustomApiKey() => _providers.readCustomApiKey();
  Future<void> writeCustomApiKey(String key) => _providers.writeCustomApiKey(key);
  Future<void> deleteCustomApiKey() => _providers.deleteCustomApiKey();

  /// Wipes all provider-owned secure storage entries. Called by
  /// SettingsService.wipeAllData() — not directly from widgets or notifiers.
  Future<void> deleteAll() => _providers.deleteAllSecureStorage();
}
```

- [ ] **Step 2: Run build_runner**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -10
```

Expected: generates `providers_service.g.dart`. No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && git add lib/services/providers/ && git commit -m "feat: add ProvidersService — extract API key CRUD from SettingsService"
```

---

## Task 3: Create `features/providers/`

**Files:**
- Create: `lib/features/providers/notifiers/providers_actions_failure.dart`
- Create: `lib/features/providers/notifiers/providers_actions.dart`
- Create: `lib/features/providers/notifiers/providers_notifier.dart`
- Create: `lib/features/providers/widgets/provider_card_helpers.dart`
- Create: `lib/features/providers/widgets/api_key_card.dart`
- Create: `lib/features/providers/widgets/ollama_card.dart`
- Create: `lib/features/providers/widgets/custom_endpoint_card.dart`
- Create: `lib/features/providers/providers_screen.dart`

- [ ] **Step 1: Create `providers_actions_failure.dart`**

```dart
// lib/features/providers/notifiers/providers_actions_failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'providers_actions_failure.freezed.dart';

@freezed
sealed class ProvidersActionsFailure with _$ProvidersActionsFailure {
  const factory ProvidersActionsFailure.storageFailed(String providerName) =
      ProvidersStorageFailed;
  const factory ProvidersActionsFailure.unknown(Object error) =
      ProvidersUnknownError;
}
```

- [ ] **Step 2: Create `providers_actions.dart`**

```dart
// lib/features/providers/notifiers/providers_actions.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/api_key_test/api_key_test_service.dart';
import '../../../services/providers/providers_service.dart';
import 'providers_actions_failure.dart';

part 'providers_actions.g.dart';

@Riverpod(keepAlive: true)
class ProvidersActions extends _$ProvidersActions {
  @override
  FutureOr<void> build() {}

  ProvidersActionsFailure _asFailure(Object e, String providerName) => switch (e) {
    StorageException() => ProvidersActionsFailure.storageFailed(providerName),
    _ => ProvidersActionsFailure.unknown(e),
  };

  /// Returns `true` when [key] is valid for [provider]. Never throws.
  Future<bool> testApiKey(AIProvider provider, String key) async {
    try {
      return await ref.read(apiKeyTestServiceProvider).testApiKey(provider, key);
    } catch (e, st) {
      dLog('[ProvidersActions] testApiKey failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` when [url] is reachable as a custom OpenAI-compatible
  /// endpoint. Never throws.
  Future<bool> testCustomEndpoint(String url, String apiKey) async {
    try {
      return await ref
          .read(apiKeyTestServiceProvider)
          .testCustomEndpoint(url, apiKey);
    } catch (e, st) {
      dLog('[ProvidersActions] testCustomEndpoint failed: $e\n$st');
      return false;
    }
  }

  /// Returns `true` when [url] is reachable as an Ollama endpoint. Never throws.
  Future<bool> testOllamaUrl(String url) async {
    try {
      return await ref.read(apiKeyTestServiceProvider).testOllamaUrl(url);
    } catch (e, st) {
      dLog('[ProvidersActions] testOllamaUrl failed: $e\n$st');
      return false;
    }
  }

  /// Persists [key] for [provider]. Emits [ProvidersStorageFailed] on error.
  /// Invalidates [aiRepositoryProvider] on success so the live datasource
  /// picks up the new key immediately.
  Future<void> saveApiKey(String provider, String key) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(providersServiceProvider).writeApiKey(provider, key);
        ref.invalidate(aiRepositoryProvider);
      } catch (e, st) {
        dLog('[ProvidersActions] saveApiKey failed: $e');
        Error.throwWithStackTrace(_asFailure(e, provider), st);
      }
    });
  }
}
```

- [ ] **Step 3: Create `providers_notifier.dart`**

This is the existing `lib/features/settings/notifiers/providers_notifier.dart` with two changes:
1. `import '../../../services/settings/settings_service.dart'` → `import '../../../services/providers/providers_service.dart'`
2. Every `ref.read(settingsServiceProvider)` → `ref.read(providersServiceProvider)`

```dart
// lib/features/providers/notifiers/providers_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/providers/providers_service.dart';

part 'providers_notifier.g.dart';

class ApiKeysNotifierState {
  const ApiKeysNotifierState({
    required this.openai,
    required this.anthropic,
    required this.gemini,
    required this.ollamaUrl,
    required this.customEndpoint,
    required this.customApiKey,
  });

  final String openai;
  final String anthropic;
  final String gemini;
  final String ollamaUrl;
  final String customEndpoint;
  final String customApiKey;

  ApiKeysNotifierState copyWith({
    String? openai,
    String? anthropic,
    String? gemini,
    String? ollamaUrl,
    String? customEndpoint,
    String? customApiKey,
  }) => ApiKeysNotifierState(
    openai: openai ?? this.openai,
    anthropic: anthropic ?? this.anthropic,
    gemini: gemini ?? this.gemini,
    ollamaUrl: ollamaUrl ?? this.ollamaUrl,
    customEndpoint: customEndpoint ?? this.customEndpoint,
    customApiKey: customApiKey ?? this.customApiKey,
  );
}

@riverpod
class ApiKeysNotifier extends _$ApiKeysNotifier {
  @override
  Future<ApiKeysNotifierState> build() async {
    final svc = ref.read(providersServiceProvider);
    return ApiKeysNotifierState(
      openai: await svc.readApiKey('openai') ?? '',
      anthropic: await svc.readApiKey('anthropic') ?? '',
      gemini: await svc.readApiKey('gemini') ?? '',
      ollamaUrl: await svc.readOllamaUrl() ?? ApiConstants.ollamaDefaultBaseUrl,
      customEndpoint: await svc.readCustomEndpoint() ?? '',
      customApiKey: await svc.readCustomApiKey() ?? '',
    );
  }

  Future<bool> saveAll({
    required Map<AIProvider, String> providerKeys,
    required String ollamaUrl,
    required String customEndpoint,
    required String customApiKey,
  }) async {
    try {
      final svc = ref.read(providersServiceProvider);
      for (final entry in providerKeys.entries) {
        final key = entry.value.trim();
        if (key.isNotEmpty) {
          await svc.writeApiKey(entry.key.name, key);
        } else {
          await svc.deleteApiKey(entry.key.name);
        }
      }
      if (ollamaUrl.trim().isNotEmpty) await svc.writeOllamaUrl(ollamaUrl.trim());
      await svc.writeCustomEndpoint(customEndpoint.trim());
      await svc.writeCustomApiKey(customApiKey.trim());
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] saveAll failed: $e\n$st');
      return false;
    }
  }

  Future<bool> deleteKey(AIProvider provider) async {
    try {
      await ref.read(providersServiceProvider).deleteApiKey(provider.name);
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] deleteKey failed: $e\n$st');
      return false;
    }
  }

  Future<bool> saveKey(AIProvider provider, String key) async {
    try {
      final svc = ref.read(providersServiceProvider);
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

  Future<bool> saveOllamaUrl(String url) async {
    try {
      await ref.read(providersServiceProvider).writeOllamaUrl(url.trim());
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] saveOllamaUrl failed: $e\n$st');
      return false;
    }
  }

  Future<bool> clearOllamaUrl() async {
    try {
      await ref.read(providersServiceProvider).deleteOllamaUrl();
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] clearOllamaUrl failed: $e\n$st');
      return false;
    }
  }

  Future<bool> saveCustomEndpoint(String url, String apiKey) async {
    try {
      final svc = ref.read(providersServiceProvider);
      await svc.writeCustomEndpoint(url.trim());
      await svc.writeCustomApiKey(apiKey.trim());
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] saveCustomEndpoint failed: $e\n$st');
      return false;
    }
  }

  Future<bool> clearCustomEndpoint() async {
    try {
      await ref.read(providersServiceProvider).deleteCustomEndpoint();
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] clearCustomEndpoint failed: $e\n$st');
      return false;
    }
  }

  Future<bool> clearCustomApiKey() async {
    try {
      await ref.read(providersServiceProvider).deleteCustomApiKey();
      if (ref.mounted) ref.invalidate(aiRepositoryProvider);
      return true;
    } catch (e, st) {
      dLog('[ApiKeysNotifier] clearCustomApiKey failed: $e\n$st');
      return false;
    }
  }
}
```

- [ ] **Step 4: Create `widgets/provider_card_helpers.dart`**

Contains the shared `DotStatus` enum (renamed from `_DotStatus`) and four shared inline button widgets (renamed from their `_`-prefixed versions).

```dart
// lib/features/providers/widgets/provider_card_helpers.dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';

enum DotStatus { empty, unsaved, savedVerified, savedUnverified }

class InlineTestButton extends StatelessWidget {
  const InlineTestButton({
    super.key,
    required this.loading,
    required this.onPressed,
    this.testPassed = false,
    this.passedLabel = '✓ Valid',
  });

  final bool loading;
  final VoidCallback onPressed;
  final bool testPassed;
  final String passedLabel;

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

    final fgColor = testPassed ? c.success : c.accent;
    final bgColor = testPassed ? c.success.withValues(alpha: 0.12) : c.accentTintMid;
    final borderColor =
        testPassed ? c.success.withValues(alpha: 0.3) : c.accent.withValues(alpha: 0.35);
    final label = testPassed ? passedLabel : 'Test';

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

class InlineSaveButton extends StatelessWidget {
  const InlineSaveButton({super.key, required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (loading) {
      return SizedBox(
        width: 54,
        height: 26,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 54,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(5)),
        child: Text(
          'Save',
          style: TextStyle(
            color: Colors.white,
            fontSize: ThemeConstants.uiFontSizeSmall,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class InlineErrorRow extends StatelessWidget {
  const InlineErrorRow({super.key, required this.message, required this.onSaveAnyway});

  final String message;
  final VoidCallback onSaveAnyway;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.errorTintBg,
        border: Border.all(color: c.error.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ),
          InkWell(
            onTap: onSaveAnyway,
            borderRadius: BorderRadius.circular(2),
            child: Text(
              'Save anyway',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InlineClearButton extends StatelessWidget {
  const InlineClearButton({super.key, required this.onPressed, this.label});

  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasLabel = label != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        constraints: hasLabel ? null : const BoxConstraints(minWidth: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: c.deepBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: hasLabel
            ? Text(
                label!,
                style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
              )
            : Icon(AppIcons.close, size: 11, color: c.error),
      ),
    );
  }
}
```

- [ ] **Step 5: Create `widgets/api_key_card.dart`**

Extracted from `lib/features/settings/providers_screen.dart` lines 129–352. Renames: `_ApiKeyCard` → `ApiKeyCard`, `_DotStatus.*` → `DotStatus.*`, `_InlineTestButton/SaveButton/ClearButton` → public names, `settingsActionsProvider` → `providersActionsProvider`. State class `_ApiKeyCardState` stays private (same file). Import depth uses `../../../` to reach `lib/`.

```dart
// lib/features/providers/widgets/api_key_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/shared/ai_model.dart';
import '../notifiers/providers_actions.dart';
import '../notifiers/providers_notifier.dart';
import 'provider_card_helpers.dart';

class ApiKeyCard extends ConsumerStatefulWidget {
  const ApiKeyCard({
    super.key,
    required this.provider,
    required this.controller,
    required this.initialValue,
  });

  final AIProvider provider;
  final TextEditingController controller;
  final String initialValue;

  @override
  ConsumerState<ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends ConsumerState<ApiKeyCard> {
  bool _obscure = true;
  bool _expanded = false;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _saveTriggered = false;
  late DotStatus _dotStatus;
  late String _savedValue;

  @override
  void initState() {
    super.initState();
    _savedValue = widget.initialValue;
    _dotStatus = _savedValue.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(ApiKeyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _savedValue = widget.initialValue;
        _dotStatus = _savedValue.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
      });
    }
  }

  void _onTextChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    final text = widget.controller.text.trim();
    final next = text == _savedValue
        ? (_savedValue.isEmpty ? DotStatus.empty : DotStatus.savedVerified)
        : DotStatus.unsaved;
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final key = widget.controller.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _saveLoading = true;
      _testPassed = false;
    });
    final ok = await ref.read(providersActionsProvider.notifier).testApiKey(widget.provider, key);
    if (!mounted) return;
    setState(() => _saveLoading = false);
    if (ok) {
      setState(() => _testPassed = true);
      AppSnackBar.show(context, 'Key is valid — click Save to persist', type: AppSnackBarType.success);
    } else {
      AppSnackBar.show(context, 'Invalid key', type: AppSnackBarType.error);
    }
  }

  Future<void> _save() async {
    final key = widget.controller.text.trim();
    if (key.isEmpty || _saveTriggered) return;
    _saveTriggered = true;
    setState(() => _saveLoading = true);
    final ok = await ref.read(providersActionsProvider.notifier).testApiKey(widget.provider, key);
    if (!mounted) {
      _saveTriggered = false;
      return;
    }
    if (ok) {
      final saved = await ref.read(apiKeysProvider.notifier).saveKey(widget.provider, key);
      if (!mounted) {
        _saveTriggered = false;
        return;
      }
      if (saved) {
        _savedValue = key;
        setState(() {
          _dotStatus = DotStatus.savedVerified;
          _testPassed = false;
          _saveLoading = false;
        });
        AppSnackBar.show(context, 'API key saved', type: AppSnackBarType.success);
      } else {
        setState(() => _saveLoading = false);
        AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
      }
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Invalid key — not saved', type: AppSnackBarType.error);
    }
    _saveTriggered = false;
  }

  Future<void> _clear() async {
    widget.controller.clear();
    final ok = await ref.read(apiKeysProvider.notifier).deleteKey(widget.provider);
    if (!mounted) return;
    _savedValue = '';
    setState(() {
      _dotStatus = DotStatus.empty;
      _testPassed = false;
    });
    AppSnackBar.show(
      context,
      ok ? 'Key cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Color _dotColor(AppColors c) => switch (_dotStatus) {
    DotStatus.empty => c.mutedFg,
    DotStatus.unsaved => c.warning,
    DotStatus.savedVerified => c.success,
    DotStatus.savedUnverified => c.success.withValues(alpha: 0.45),
  };

  String _statusLabel() => switch (_dotStatus) {
    DotStatus.empty => 'Not configured',
    DotStatus.unsaved => 'Unsaved changes',
    DotStatus.savedVerified => 'Valid & saved',
    DotStatus.savedUnverified => 'Saved (unverified)',
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
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) _testPassed = false;
            }),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: _dotColor(c), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.provider.displayName,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(),
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                    ),
                  ),
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
              child: Column(
                children: [
                  Row(
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InlineTestButton(
                        loading: _saveLoading,
                        testPassed: _testPassed,
                        onPressed: _test,
                      ),
                      const SizedBox(width: 4),
                      InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 4),
                      InlineClearButton(onPressed: _clear),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Create `widgets/ollama_card.dart`**

Extracted from `lib/features/settings/providers_screen.dart` lines 356–597. Same renames as Step 5: `DotStatus`, public helper names, `providersActionsProvider`.

```dart
// lib/features/providers/widgets/ollama_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../notifiers/providers_actions.dart';
import '../notifiers/providers_notifier.dart';
import 'provider_card_helpers.dart';

class OllamaCard extends ConsumerStatefulWidget {
  const OllamaCard({super.key, required this.controller, required this.initialValue});

  final TextEditingController controller;
  final String initialValue;

  @override
  ConsumerState<OllamaCard> createState() => _OllamaCardState();
}

class _OllamaCardState extends ConsumerState<OllamaCard> {
  bool _expanded = false;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _showSaveAnyway = false;
  bool _saveTriggered = false;
  late DotStatus _dotStatus;
  late String _savedValue;

  @override
  void initState() {
    super.initState();
    _savedValue = widget.initialValue;
    _dotStatus = _savedValue.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(OllamaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _savedValue = widget.initialValue;
        _dotStatus = _savedValue.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
      });
    }
  }

  void _onTextChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    if (_showSaveAnyway) setState(() => _showSaveAnyway = false);
    final text = widget.controller.text.trim();
    final next = text == _savedValue
        ? (_savedValue.isEmpty ? DotStatus.empty : DotStatus.savedVerified)
        : DotStatus.unsaved;
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final url = widget.controller.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _saveLoading = true;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    final ok = await ref.read(providersActionsProvider.notifier).testOllamaUrl(url);
    if (!mounted) return;
    setState(() => _saveLoading = false);
    if (ok) {
      setState(() => _testPassed = true);
      AppSnackBar.show(
        context,
        'Ollama is reachable — click Save to persist',
        type: AppSnackBarType.success,
      );
    } else {
      AppSnackBar.show(context, 'Cannot connect to Ollama', type: AppSnackBarType.error);
    }
  }

  Future<void> _save() async {
    final url = widget.controller.text.trim();
    if (url.isEmpty || _saveTriggered) return;
    _saveTriggered = true;
    setState(() {
      _saveLoading = true;
      _showSaveAnyway = false;
    });
    final ok = await ref.read(providersActionsProvider.notifier).testOllamaUrl(url);
    if (!mounted) {
      _saveTriggered = false;
      return;
    }
    if (ok) {
      await _persist(url, verified: true);
    } else {
      setState(() {
        _saveLoading = false;
        _showSaveAnyway = true;
      });
    }
    _saveTriggered = false;
  }

  Future<void> _saveAnyway() async {
    final url = widget.controller.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _saveLoading = true;
      _showSaveAnyway = false;
    });
    await _persist(url, verified: false);
  }

  Future<void> _persist(String url, {required bool verified}) async {
    final saved = await ref.read(apiKeysProvider.notifier).saveOllamaUrl(url);
    if (!mounted) return;
    if (saved) {
      _savedValue = url;
      setState(() {
        _dotStatus = verified ? DotStatus.savedVerified : DotStatus.savedUnverified;
        _testPassed = false;
        _saveLoading = false;
      });
      AppSnackBar.show(
        context,
        verified ? 'Ollama URL saved' : 'Saved (unverified)',
        type: AppSnackBarType.success,
      );
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
    }
  }

  Future<void> _clear() async {
    widget.controller.clear();
    final ok = await ref.read(apiKeysProvider.notifier).clearOllamaUrl();
    if (!mounted) return;
    _savedValue = '';
    setState(() {
      _dotStatus = DotStatus.empty;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    AppSnackBar.show(
      context,
      ok ? 'Ollama URL cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Color _dotColor(AppColors c) => switch (_dotStatus) {
    DotStatus.empty => c.mutedFg,
    DotStatus.unsaved => c.warning,
    DotStatus.savedVerified => c.success,
    DotStatus.savedUnverified => c.success.withValues(alpha: 0.45),
  };

  String _statusLabel() => switch (_dotStatus) {
    DotStatus.empty => 'Not configured',
    DotStatus.unsaved => 'Unsaved changes',
    DotStatus.savedVerified => 'Connected & saved',
    DotStatus.savedUnverified => 'Saved (unverified)',
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
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) {
                _testPassed = false;
                _showSaveAnyway = false;
              }
            }),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: _dotColor(c), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ollama',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(),
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                    ),
                  ),
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
              child: Column(
                children: [
                  AppTextField(
                    controller: widget.controller,
                    fontFamily: ThemeConstants.editorFontFamily,
                    hintText: 'http://localhost:11434',
                  ),
                  if (_showSaveAnyway) ...[
                    const SizedBox(height: 6),
                    InlineErrorRow(
                      message: 'Cannot connect to Ollama',
                      onSaveAnyway: _saveAnyway,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InlineTestButton(
                        loading: _saveLoading,
                        testPassed: _testPassed,
                        passedLabel: '✓ Connected',
                        onPressed: _test,
                      ),
                      const SizedBox(width: 4),
                      InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 4),
                      InlineClearButton(onPressed: _clear),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Create `widgets/custom_endpoint_card.dart`**

Extracted from `lib/features/settings/providers_screen.dart` lines 601–878. Same renames.

```dart
// lib/features/providers/widgets/custom_endpoint_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../notifiers/providers_actions.dart';
import '../notifiers/providers_notifier.dart';
import 'provider_card_helpers.dart';

class CustomEndpointCard extends ConsumerStatefulWidget {
  const CustomEndpointCard({
    super.key,
    required this.urlController,
    required this.apiKeyController,
    required this.initialUrl,
    required this.initialApiKey,
  });

  final TextEditingController urlController;
  final TextEditingController apiKeyController;
  final String initialUrl;
  final String initialApiKey;

  @override
  ConsumerState<CustomEndpointCard> createState() => _CustomEndpointCardState();
}

class _CustomEndpointCardState extends ConsumerState<CustomEndpointCard> {
  bool _expanded = false;
  bool _obscureKey = true;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _showSaveAnyway = false;
  bool _saveTriggered = false;
  late DotStatus _dotStatus;
  late String _savedUrl;
  late String _savedApiKey;

  @override
  void initState() {
    super.initState();
    _savedUrl = widget.initialUrl;
    _savedApiKey = widget.initialApiKey;
    _dotStatus = _savedUrl.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
    widget.urlController.addListener(_onFieldChanged);
    widget.apiKeyController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    widget.urlController.removeListener(_onFieldChanged);
    widget.apiKeyController.removeListener(_onFieldChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomEndpointCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUrl != widget.initialUrl ||
        oldWidget.initialApiKey != widget.initialApiKey) {
      setState(() {
        _savedUrl = widget.initialUrl;
        _savedApiKey = widget.initialApiKey;
        _dotStatus = _savedUrl.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
      });
    }
  }

  bool get _isUnsaved =>
      widget.urlController.text.trim() != _savedUrl ||
      widget.apiKeyController.text.trim() != _savedApiKey;

  void _onFieldChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    if (_showSaveAnyway) setState(() => _showSaveAnyway = false);
    final DotStatus next;
    if (!_isUnsaved) {
      next = _savedUrl.isEmpty ? DotStatus.empty : _dotStatus;
    } else {
      next = DotStatus.unsaved;
    }
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final url = widget.urlController.text.trim();
    if (url.isEmpty) return;
    final apiKey = widget.apiKeyController.text.trim();
    setState(() {
      _saveLoading = true;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    final ok =
        await ref.read(providersActionsProvider.notifier).testCustomEndpoint(url, apiKey);
    if (!mounted) return;
    setState(() => _saveLoading = false);
    if (ok) {
      setState(() => _testPassed = true);
      AppSnackBar.show(
        context,
        'Endpoint reachable — click Save to persist',
        type: AppSnackBarType.success,
      );
    } else {
      AppSnackBar.show(context, 'Cannot connect to endpoint', type: AppSnackBarType.error);
    }
  }

  Future<void> _save() async {
    final url = widget.urlController.text.trim();
    if (url.isEmpty || _saveTriggered) return;
    _saveTriggered = true;
    final apiKey = widget.apiKeyController.text.trim();
    setState(() {
      _saveLoading = true;
      _showSaveAnyway = false;
    });
    final ok =
        await ref.read(providersActionsProvider.notifier).testCustomEndpoint(url, apiKey);
    if (!mounted) {
      _saveTriggered = false;
      return;
    }
    if (ok) {
      await _persist(url, apiKey, verified: true);
    } else {
      setState(() {
        _saveLoading = false;
        _showSaveAnyway = true;
      });
    }
    _saveTriggered = false;
  }

  Future<void> _saveAnyway() async {
    final url = widget.urlController.text.trim();
    if (url.isEmpty) return;
    final apiKey = widget.apiKeyController.text.trim();
    setState(() {
      _saveLoading = true;
      _showSaveAnyway = false;
    });
    await _persist(url, apiKey, verified: false);
  }

  Future<void> _persist(String url, String apiKey, {required bool verified}) async {
    final saved =
        await ref.read(apiKeysProvider.notifier).saveCustomEndpoint(url, apiKey);
    if (!mounted) return;
    if (saved) {
      _savedUrl = url;
      _savedApiKey = apiKey;
      setState(() {
        _dotStatus = verified ? DotStatus.savedVerified : DotStatus.savedUnverified;
        _testPassed = false;
        _saveLoading = false;
      });
      AppSnackBar.show(
        context,
        verified ? 'Custom endpoint saved' : 'Saved (unverified)',
        type: AppSnackBarType.success,
      );
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
    }
  }

  Future<void> _clearAll() async {
    widget.urlController.clear();
    widget.apiKeyController.clear();
    await ref.read(apiKeysProvider.notifier).clearCustomEndpoint();
    await ref.read(apiKeysProvider.notifier).clearCustomApiKey();
    if (!mounted) return;
    _savedUrl = '';
    _savedApiKey = '';
    setState(() {
      _dotStatus = DotStatus.empty;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    AppSnackBar.show(context, 'Custom endpoint cleared', type: AppSnackBarType.success);
  }

  Color _dotColor(AppColors c) => switch (_dotStatus) {
    DotStatus.empty => c.mutedFg,
    DotStatus.unsaved => c.warning,
    DotStatus.savedVerified => c.success,
    DotStatus.savedUnverified => c.success.withValues(alpha: 0.45),
  };

  String _statusLabel() => switch (_dotStatus) {
    DotStatus.empty => 'Not configured',
    DotStatus.unsaved => 'Unsaved changes',
    DotStatus.savedVerified => 'Connected & saved',
    DotStatus.savedUnverified => 'Saved (unverified)',
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
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) {
                _testPassed = false;
                _showSaveAnyway = false;
              }
            }),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: _dotColor(c), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Custom',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(),
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                    ),
                  ),
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
              child: Column(
                children: [
                  AppTextField(
                    controller: widget.urlController,
                    fontFamily: ThemeConstants.editorFontFamily,
                    hintText: 'http://localhost:1234/v1',
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: widget.apiKeyController,
                    obscureText: _obscureKey,
                    fontFamily: ThemeConstants.editorFontFamily,
                    hintText: 'API Key (optional)',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey ? AppIcons.hideSecret : AppIcons.showSecret,
                        size: 14,
                      ),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                  if (_showSaveAnyway) ...[
                    const SizedBox(height: 6),
                    InlineErrorRow(
                      message: 'Cannot connect to endpoint',
                      onSaveAnyway: _saveAnyway,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InlineTestButton(
                        loading: _saveLoading,
                        testPassed: _testPassed,
                        passedLabel: '✓ Connected',
                        onPressed: _test,
                      ),
                      const SizedBox(width: 4),
                      InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 4),
                      InlineClearButton(label: '✕ All', onPressed: _clearAll),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Create slim `providers_screen.dart`**

The screen itself is only lines 1–121 of the original. Import changes:
- `import 'notifiers/settings_actions.dart'` → removed (not needed in screen)
- `import 'widgets/section_label.dart'` → `import '../settings/widgets/section_label.dart'`
- Add: `import 'widgets/api_key_card.dart'`, `import 'widgets/ollama_card.dart'`, `import 'widgets/custom_endpoint_card.dart'`
- Remove: `import '../../core/constants/app_icons.dart'`, `import '../../core/widgets/app_text_field.dart'` (no longer used in screen itself)
- In `build()`: `_ApiKeyCard(` → `ApiKeyCard(`, `_OllamaCard(` → `OllamaCard(`, `_CustomEndpointCard(` → `CustomEndpointCard(`

```dart
// lib/features/providers/providers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/shared/ai_model.dart';
import '../settings/widgets/section_label.dart';
import 'notifiers/providers_notifier.dart';
import 'widgets/api_key_card.dart';
import 'widgets/custom_endpoint_card.dart';
import 'widgets/ollama_card.dart';

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

  String _initialOpenAi = '';
  String _initialAnthropic = '';
  String _initialGemini = '';
  String _initialOllamaUrl = '';
  String _initialCustomEndpoint = '';
  String _initialCustomApiKey = '';

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
      setState(() {
        _initialOpenAi = s.openai;
        _initialAnthropic = s.anthropic;
        _initialGemini = s.gemini;
        _initialOllamaUrl = s.ollamaUrl;
        _initialCustomEndpoint = s.customEndpoint;
        _initialCustomApiKey = s.customApiKey;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Could not load API keys — please restart the app.',
          type: AppSnackBarType.error,
        );
      }
    }
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
          ApiKeyCard(
            provider: AIProvider.openai,
            controller: _controllers[AIProvider.openai]!,
            initialValue: _initialOpenAi,
          ),
          const SizedBox(height: 6),
          ApiKeyCard(
            provider: AIProvider.anthropic,
            controller: _controllers[AIProvider.anthropic]!,
            initialValue: _initialAnthropic,
          ),
          const SizedBox(height: 6),
          ApiKeyCard(
            provider: AIProvider.gemini,
            controller: _controllers[AIProvider.gemini]!,
            initialValue: _initialGemini,
          ),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Ollama (Local)'),
          const SizedBox(height: 8),
          OllamaCard(controller: _ollamaController, initialValue: _initialOllamaUrl),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Custom Endpoint (OpenAI-compatible)'),
          const SizedBox(height: 8),
          CustomEndpointCard(
            urlController: _customEndpointController,
            apiKeyController: _customApiKeyController,
            initialUrl: _initialCustomEndpoint,
            initialApiKey: _initialCustomApiKey,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 9: Run build_runner**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -10
```

Expected: generates `providers_actions.g.dart`, `providers_actions_failure.freezed.dart`, `providers_notifier.g.dart`. No errors.

- [ ] **Step 10: Run analyze on the new feature folder**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && flutter analyze lib/features/providers/ 2>&1
```

Expected: No issues.

- [ ] **Step 11: Commit**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && git add lib/features/providers/ && git commit -m "feat: add features/providers — screen, notifiers, and extracted widgets"
```

---

## Task 4: Create `features/integrations/`

**Files:**
- Create: `lib/features/integrations/widgets/github_connected_card.dart`
- Create: `lib/features/integrations/widgets/github_disconnected_card.dart`
- Create: `lib/features/integrations/integrations_screen.dart`

- [ ] **Step 1: Create `widgets/github_connected_card.dart`**

Extracted from `lib/features/settings/integrations_screen.dart` lines 139–233. Renames: `_ConnectedCard` → `GithubConnectedCard`, `_PersonIcon` → `PersonIcon` (both public, same file).

```dart
// lib/features/integrations/widgets/github_connected_card.dart
import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/github/models/repository.dart';

class GithubConnectedCard extends StatefulWidget {
  const GithubConnectedCard({
    super.key,
    required this.account,
    required this.onDisconnect,
  });

  final GitHubAccount account;
  final VoidCallback onDisconnect;

  @override
  State<GithubConnectedCard> createState() => _GithubConnectedCardState();
}

class _GithubConnectedCardState extends State<GithubConnectedCard> {
  bool _disconnectHovered = false;

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
          if (widget.account.avatarUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.account.avatarUrl,
                width: 36,
                height: 36,
                errorBuilder: (_, _, _) => PersonIcon(c: c),
              ),
            )
          else
            PersonIcon(c: c),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.account.username,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: c.success),
                  const SizedBox(width: 3),
                  Text('Connected', style: TextStyle(color: c.success, fontSize: 10)),
                ],
              ),
            ],
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _disconnectHovered = true),
            onExit: (_) => setState(() => _disconnectHovered = false),
            child: GestureDetector(
              onTap: widget.onDisconnect,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _disconnectHovered ? c.deepBorder : Colors.transparent,
                  border: Border.all(color: c.deepBorder),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Disconnect',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonIcon extends StatelessWidget {
  const PersonIcon({super.key, required this.c});

  final AppColors c;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: c.inputSurface, shape: BoxShape.circle),
    child: Icon(Icons.person, size: 20, color: c.textSecondary),
  );
}
```

- [ ] **Step 2: Create `widgets/github_disconnected_card.dart`**

Extracted from `lib/features/settings/integrations_screen.dart` lines 235–422. Renames: `_DisconnectedCard` → `GithubDisconnectedCard`, `_GitHubIcon` → `GitHubIcon`, `_GitHubPainter` → `GitHubPainter`.

```dart
// lib/features/integrations/widgets/github_disconnected_card.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';

class GithubDisconnectedCard extends StatefulWidget {
  const GithubDisconnectedCard({
    super.key,
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
  State<GithubDisconnectedCard> createState() => _GithubDisconnectedCardState();
}

class _GithubDisconnectedCardState extends State<GithubDisconnectedCard> {
  bool _patConnectHovered = false;

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
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: c.githubBrandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: widget.isLoading ? null : widget.onConnectOAuth,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const GitHubIcon(),
            label: Text(
              widget.isLoading ? 'Connecting…' : 'Continue with GitHub',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onTogglePat,
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
                  widget.showPat ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 14,
                  color: c.accent,
                ),
              ],
            ),
          ),
          if (widget.showPat) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: widget.patController,
                    obscureText: true,
                    labelText: 'Personal Access Token',
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _patConnectHovered = true),
                  onExit: (_) => setState(() => _patConnectHovered = false),
                  child: GestureDetector(
                    onTap: widget.isLoading ? null : widget.onSignInWithPat,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _patConnectHovered
                            ? c.accent.withValues(alpha: 0.2)
                            : c.accentTintMid,
                        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Connect',
                        style: TextStyle(
                          color: c.accent,
                          fontSize: ThemeConstants.uiFontSizeSmall,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.onOpenTokenPage,
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

class GitHubIcon extends StatelessWidget {
  const GitHubIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(16, 16), painter: GitHubPainter());
  }
}

class GitHubPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    final s = size.width / 16;
    path.addPath(
      _githubPath()
        ..transform(Float64List.fromList([s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])),
      Offset.zero,
    );
    canvas.drawPath(path, paint);
  }

  Path _githubPath() {
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
  bool shouldRepaint(GitHubPainter oldDelegate) => false;
}
```

- [ ] **Step 3: Create slim `integrations_screen.dart`**

The screen keeps only `IntegrationsScreen` + `_IntegrationsScreenState` (lines 1–136 of the original). Import changes:
- `import 'widgets/section_label.dart'` → `import '../settings/widgets/section_label.dart'`
- Add: `import 'widgets/github_connected_card.dart'`, `import 'widgets/github_disconnected_card.dart'`
- `_ConnectedCard(` → `GithubConnectedCard(`
- `_DisconnectedCard(` → `GithubDisconnectedCard(`
- Remove: `import 'dart:typed_data'` (moved to disconnected card)

```dart
// lib/features/integrations/integrations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/github/models/repository.dart';
import '../onboarding/notifiers/github_auth_notifier.dart';
import '../settings/widgets/section_label.dart';
import 'widgets/github_connected_card.dart';
import 'widgets/github_disconnected_card.dart';

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
    if (!mounted) return;
    if (!ref.read(gitHubAuthProvider).hasError) {
      AppSnackBar.show(context, 'Connected to GitHub', type: AppSnackBarType.success);
    }
  }

  Future<void> _signOut() async {
    await ref.read(gitHubAuthProvider.notifier).signOut();
    if (!mounted) return;
    if (!ref.read(gitHubAuthProvider).hasError) {
      AppSnackBar.show(context, 'Disconnected from GitHub', type: AppSnackBarType.success);
    }
  }

  Future<void> _signInWithPat() async {
    final token = _patController.text.trim();
    if (token.isEmpty) return;
    await ref.read(gitHubAuthProvider.notifier).signInWithPat(token);
    if (!mounted) return;
    if (!ref.read(gitHubAuthProvider).hasError) {
      AppSnackBar.show(context, 'Connected to GitHub', type: AppSnackBarType.success);
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
        AppSnackBar.show(
          context,
          'GitHub auth failed — please try again.',
          type: AppSnackBarType.error,
        );
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
          const SectionLabel('GitHub'),
          const SizedBox(height: 8),
          if (account != null)
            GithubConnectedCard(account: account, onDisconnect: _signOut)
          else
            GithubDisconnectedCard(
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
              style: TextStyle(
                color: c.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

> **Note:** The slim screen above removes `import 'dart:typed_data'` and `import '../../core/widgets/app_text_field.dart'` — these have moved to the widget files. Verify no remaining imports become unused after removing `_ConnectedCard`/`_DisconnectedCard` and their dependencies from the screen file.

- [ ] **Step 4: Run analyze**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && flutter analyze lib/features/integrations/ 2>&1
```

Expected: No issues.

- [ ] **Step 5: Commit**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && git add lib/features/integrations/ && git commit -m "feat: add features/integrations — screen and extracted GitHub card widgets"
```

---

## Task 5: Create `features/archive/`

**Files:**
- Create: `lib/features/archive/notifiers/archive_failure.dart`
- Create: `lib/features/archive/notifiers/archive_actions.dart`
- Create: `lib/features/archive/widgets/archive_error_view.dart`
- Create: `lib/features/archive/widgets/archived_session_card.dart`
- Create: `lib/features/archive/archive_screen.dart`

- [ ] **Step 1: Create `archive_failure.dart`**

```dart
// lib/features/archive/notifiers/archive_failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'archive_failure.freezed.dart';

@freezed
sealed class ArchiveFailure with _$ArchiveFailure {
  const factory ArchiveFailure.storage([String? detail]) = ArchiveStorageError;
  const factory ArchiveFailure.unknown(Object error) = ArchiveUnknownError;
}
```

- [ ] **Step 2: Create `archive_actions.dart`**

Exact copy of `lib/features/settings/notifiers/archive_actions.dart`. All `../../../` import paths resolve identically from `lib/features/archive/notifiers/`.

```dart
// lib/features/archive/notifiers/archive_actions.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/session/session_service.dart';
import 'archive_failure.dart';

part 'archive_actions.g.dart';

@Riverpod(keepAlive: true)
class ArchiveActions extends _$ArchiveActions {
  @override
  FutureOr<void> build() {}

  ArchiveFailure _asFailure(Object e) => switch (e) {
    StorageException() => const ArchiveFailure.storage(),
    _ => ArchiveFailure.unknown(e),
  };

  Future<void> unarchiveSession(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(sessionServiceProvider).unarchiveSession(id);
      } catch (e, st) {
        dLog('[ArchiveActions] unarchiveSession failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
    });
  }
}
```

> **Note:** Read `lib/features/settings/notifiers/archive_actions.dart` and copy verbatim if its current content differs from above.

- [ ] **Step 3: Create `widgets/archive_error_view.dart`**

Extracted from `lib/features/settings/archive_screen.dart` lines 86–140. Renames: `_ArchiveErrorView` → `ArchiveErrorView`, `_ProjectHeader` → `ProjectHeader`.

```dart
// lib/features/archive/widgets/archive_error_view.dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';

class ArchiveErrorView extends StatelessWidget {
  const ArchiveErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load archived sessions.',
            style: TextStyle(color: c.error, fontSize: 11),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: c.textPrimary,
              side: BorderSide(color: c.borderColor),
              textStyle: const TextStyle(fontSize: 11),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class ProjectHeader extends StatelessWidget {
  const ProjectHeader({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          Icon(AppIcons.folder, size: 12, color: c.mutedFg),
          const SizedBox(width: 6),
          Text(
            name.toUpperCase(),
            style: TextStyle(
              color: c.mutedFg,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create `widgets/archived_session_card.dart`**

Extracted from `lib/features/settings/archive_screen.dart` lines 142–221. Rename: `_ArchivedSessionCard` → `ArchivedSessionCard`.

```dart
// lib/features/archive/widgets/archived_session_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_time.dart';
import '../../../data/session/models/chat_session.dart';
import '../notifiers/archive_actions.dart';

class ArchivedSessionCard extends ConsumerStatefulWidget {
  const ArchivedSessionCard({super.key, required this.session});

  final ChatSession session;

  @override
  ConsumerState<ArchivedSessionCard> createState() => _ArchivedSessionCardState();
}

class _ArchivedSessionCardState extends ConsumerState<ArchivedSessionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.background,
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Archived ${widget.session.updatedAt.relativeTime} · Created ${widget.session.createdAt.relativeTime}',
                  style: TextStyle(color: c.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: () => ref
                  .read(archiveActionsProvider.notifier)
                  .unarchiveSession(widget.session.sessionId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _hovered ? c.borderColor : Colors.transparent,
                  border: Border.all(color: c.borderColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.archiveRestore, size: 12, color: c.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      'Unarchive',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Create slim `archive_screen.dart`**

Keeps only `ArchiveScreen` + `_ArchiveScreenState`. Import changes:
- Add: `import 'widgets/archive_error_view.dart'`, `import 'widgets/archived_session_card.dart'`
- `import 'notifiers/archive_actions.dart'` stays (local)
- `_ArchiveErrorView(` → `ArchiveErrorView(`, `_ProjectHeader(` → `ProjectHeader(`, `_ArchivedSessionCard(` → `ArchivedSessionCard(`

```dart
// lib/features/archive/archive_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/project/models/project.dart';
import '../../data/session/models/chat_session.dart';
import '../chat/notifiers/chat_notifier.dart';
import '../project_sidebar/notifiers/project_sidebar_actions.dart';
import '../project_sidebar/notifiers/project_sidebar_notifier.dart';
import 'notifiers/archive_actions.dart';
import 'widgets/archive_error_view.dart';
import 'widgets/archived_session_card.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sessionsAsync = ref.watch(archivedSessionsProvider);
    final projectsAsync = ref.watch(projectsProvider);

    ref.listen(archiveActionsProvider, (prev, next) {
      if (!mounted) return;
      if (next is AsyncData && prev is AsyncLoading) {
        AppSnackBar.show(context, 'Session unarchived', type: AppSnackBarType.success);
      }
    });

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, st) {
        dLog('[archive] load failed: $e\n$st');
        return ArchiveErrorView(
          onRetry: () => ref
              .read(projectSidebarActionsProvider.notifier)
              .refreshArchivedSessions(),
        );
      },
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.archive, size: 32, color: c.mutedFg),
                const SizedBox(height: 12),
                Text(
                  'No archived conversations',
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final projects = switch (projectsAsync) {
          AsyncData(:final value) => value,
          _ => const <Project>[],
        };
        final projectMap = {for (final p in projects) p.id: p.name};

        final groups = <String?, List<ChatSession>>{};
        for (final s in sessions) {
          groups.putIfAbsent(s.projectId, () => []).add(s);
        }

        return ListView(
          children: [
            for (final entry in groups.entries) ...[
              ProjectHeader(name: projectMap[entry.key] ?? 'No Project'),
              for (final s in entry.value) ArchivedSessionCard(session: s),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 6: Run build_runner**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -10
```

Expected: generates `archive_actions.g.dart` and `archive_failure.freezed.dart` in `lib/features/archive/notifiers/`. No errors.

- [ ] **Step 7: Run analyze**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && flutter analyze lib/features/archive/ 2>&1
```

Expected: No issues.

- [ ] **Step 8: Commit**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && git add lib/features/archive/ && git commit -m "feat: add features/archive — screen, notifiers, and extracted widgets"
```

---

## Task 6: Slim and clean — update settings, delete old files, slim data/service, extract AppDropdown

All deletions and modifications happen in this task. Order matters: create new files first, then modify, then delete.

**Files to modify:** `settings_screen.dart`, `settings_actions.dart`, `settings_repository.dart`, `settings_repository_impl.dart`, `settings_service.dart`, `general_screen.dart`

**Files to create:** `lib/features/settings/widgets/app_dropdown.dart`

**Files to delete:** old screen/notifier files from `features/settings/`

- [ ] **Step 1: Create `widgets/app_dropdown.dart`**

Extracted from `lib/features/settings/general_screen.dart` lines 303–392. Rename: `_AppDropdown<T>` → `AppDropdown<T>`. Import path from `lib/features/settings/widgets/` uses `../../../core/...`.

```dart
// lib/features/settings/widgets/app_dropdown.dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/instant_menu.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    required this.context,
  });

  final T value;
  final List<T> items;
  final String Function(T) label;
  final void Function(T) onChanged;
  final BuildContext context;

  void _open() {
    final c = AppColors.of(context);
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    showInstantMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height + 4,
        overlay.size.width - origin.dx - box.size.width,
        0,
      ),
      color: c.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: c.faintFg),
      ),
      items: items
          .map(
            (item) => PopupMenuItem<T>(
              value: item,
              height: 30,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label(item),
                      style: TextStyle(
                        color: item == value ? c.textPrimary : c.textSecondary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                      ),
                    ),
                  ),
                  if (item == value) Icon(AppIcons.check, size: 11, color: c.accent),
                ],
              ),
            ),
          )
          .toList(),
    ).then((picked) {
      if (picked != null) onChanged(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.chipFill,
          border: Border.all(color: c.chipStroke),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label(value),
              style: TextStyle(
                color: c.textPrimary,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
            const SizedBox(width: 4),
            Icon(AppIcons.chevronDown, size: 10, color: c.mutedFg),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update `general_screen.dart` to use `AppDropdown`**

Two changes:
1. Add import: `import 'widgets/app_dropdown.dart';`
2. All `_AppDropdown<` usages → `AppDropdown<`  (grep for `_AppDropdown` to find all occurrences)
3. Delete the `_AppDropdown` class definition and the comment above it (lines 303–392 of the current file).

Read `lib/features/settings/general_screen.dart`, apply the changes, write it back. The class body that currently ends at line 392 (`}`) should be removed, along with the comment on line 303.

- [ ] **Step 3: Update `settings_screen.dart` imports**

Replace three screen imports in `lib/features/settings/settings_screen.dart`:

```dart
// OLD — remove these three lines:
import 'archive_screen.dart';
import 'integrations_screen.dart';
import 'providers_screen.dart';

// NEW — replace with:
import '../archive/archive_screen.dart';
import '../integrations/integrations_screen.dart';
import '../providers/providers_screen.dart';
```

- [ ] **Step 4: Slim `settings_actions.dart`**

Replace the entire `lib/features/settings/notifiers/settings_actions.dart` with the version below. Removes `testApiKey`, `testCustomEndpoint`, `testOllamaUrl`, `saveApiKey`, and `_asFailure` (moved to `ProvidersActions`).

```dart
// lib/features/settings/notifiers/settings_actions.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/settings/settings_service.dart';

part 'settings_actions.g.dart';

/// Imperative actions for onboarding and data wipe. API key test/save
/// methods have moved to ProvidersActions in features/providers/.
@Riverpod(keepAlive: true)
class SettingsActions extends _$SettingsActions {
  @override
  FutureOr<void> build() {}

  Future<void> markOnboardingCompleted() async {
    try {
      await ref.read(settingsServiceProvider).markOnboardingCompleted();
    } catch (e, st) {
      dLog('[SettingsActions] markOnboardingCompleted failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> replayOnboarding() =>
      ref.read(settingsServiceProvider).resetOnboarding();

  /// Wipes all user data in sequence. Returns a list of step names that
  /// failed (empty means full success).
  Future<List<String>> wipeAllData() async {
    final failures = await ref.read(settingsServiceProvider).wipeAllData();
    ref.invalidate(aiRepositoryProvider);
    return failures;
  }
}
```

- [ ] **Step 5: Delete old files from `features/settings/`**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && rm \
  lib/features/settings/providers_screen.dart \
  lib/features/settings/integrations_screen.dart \
  lib/features/settings/archive_screen.dart \
  lib/features/settings/notifiers/providers_notifier.dart \
  lib/features/settings/notifiers/providers_notifier.g.dart \
  lib/features/settings/notifiers/archive_actions.dart \
  lib/features/settings/notifiers/archive_actions.g.dart \
  lib/features/settings/notifiers/archive_failure.dart \
  lib/features/settings/notifiers/archive_failure.freezed.dart
```

- [ ] **Step 6: Replace `settings_repository.dart` with slim version**

```dart
// lib/data/settings/repository/settings_repository.dart
import '../models/app_theme_preference.dart';

abstract interface class SettingsRepository {
  // ── General preferences ───────────────────────────────────────────────────
  Future<bool> getAutoCommit();
  Future<void> setAutoCommit(bool value);
  Future<String> getTerminalApp();
  Future<void> setTerminalApp(String value);
  Future<bool> getDeleteConfirmation();
  Future<void> setDeleteConfirmation(bool value);
  Future<AppThemePreference> getThemeMode();
  Future<void> setThemeMode(AppThemePreference mode);

  // ── Onboarding ────────────────────────────────────────────────────────────
  Future<void> markOnboardingCompleted();
  Future<void> resetOnboarding();
}
```

- [ ] **Step 7: Replace `settings_repository_impl.dart` with slim version**

```dart
// lib/data/settings/repository/settings_repository_impl.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/_core/preferences/general_preferences.dart';
import '../../../data/_core/preferences/onboarding_preferences.dart';
import '../models/app_theme_preference.dart';
import 'settings_repository.dart';

part 'settings_repository_impl.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => SettingsRepositoryImpl(ref);

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._ref);

  final Ref _ref;

  GeneralPreferences get _generalPrefs => _ref.read(generalPreferencesProvider);
  OnboardingPreferences get _onboardingPrefs =>
      _ref.read(onboardingPreferencesProvider);

  @override
  Future<bool> getAutoCommit() => _generalPrefs.getAutoCommit();

  @override
  Future<void> setAutoCommit(bool value) => _generalPrefs.setAutoCommit(value);

  @override
  Future<String> getTerminalApp() => _generalPrefs.getTerminalApp();

  @override
  Future<void> setTerminalApp(String value) => _generalPrefs.setTerminalApp(value);

  @override
  Future<bool> getDeleteConfirmation() => _generalPrefs.getDeleteConfirmation();

  @override
  Future<void> setDeleteConfirmation(bool value) =>
      _generalPrefs.setDeleteConfirmation(value);

  @override
  Future<AppThemePreference> getThemeMode() => _generalPrefs.getThemeMode();

  @override
  Future<void> setThemeMode(AppThemePreference mode) =>
      _generalPrefs.setThemeMode(mode);

  @override
  Future<void> markOnboardingCompleted() => _onboardingPrefs.markCompleted();

  @override
  Future<void> resetOnboarding() => _onboardingPrefs.reset();
}
```

- [ ] **Step 8: Replace `settings_service.dart` with slim version**

```dart
// lib/services/settings/settings_service.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/debug_logger.dart';
import '../../data/project/repository/project_repository.dart';
import '../../data/project/repository/project_repository_impl.dart';
import '../../data/session/repository/session_repository.dart';
import '../../data/session/repository/session_repository_impl.dart';
import '../../data/settings/models/app_theme_preference.dart';
import '../../data/settings/repository/settings_repository.dart';
import '../../data/settings/repository/settings_repository_impl.dart';
import '../../services/providers/providers_service.dart';

part 'settings_service.g.dart';

@Riverpod(keepAlive: true)
SettingsService settingsService(Ref ref) {
  return SettingsService(
    settings: ref.watch(settingsRepositoryProvider),
    providers: ref.watch(providersServiceProvider),
    session: ref.watch(sessionRepositoryProvider),
    project: ref.watch(projectRepositoryProvider),
  );
}

class SettingsService {
  SettingsService({
    required SettingsRepository settings,
    required ProvidersService providers,
    required SessionRepository session,
    required ProjectRepository project,
  })  : _settings = settings,
        _providers = providers,
        _session = session,
        _project = project;

  final SettingsRepository _settings;
  final ProvidersService _providers;
  final SessionRepository _session;
  final ProjectRepository _project;

  Future<bool> getAutoCommit() => _settings.getAutoCommit();
  Future<void> setAutoCommit(bool value) => _settings.setAutoCommit(value);
  Future<String> getTerminalApp() => _settings.getTerminalApp();
  Future<void> setTerminalApp(String value) => _settings.setTerminalApp(value);
  Future<bool> getDeleteConfirmation() => _settings.getDeleteConfirmation();
  Future<void> setDeleteConfirmation(bool value) =>
      _settings.setDeleteConfirmation(value);
  Future<AppThemePreference> getThemeMode() => _settings.getThemeMode();
  Future<void> setThemeMode(AppThemePreference mode) =>
      _settings.setThemeMode(mode);

  Future<void> markOnboardingCompleted() => _settings.markOnboardingCompleted();
  Future<void> resetOnboarding() => _settings.resetOnboarding();

  /// Wipes all user data in sequence. Returns step names that failed
  /// (empty = full success). Each step is isolated so a keychain failure
  /// does not block the DB wipe.
  Future<List<String>> wipeAllData() async {
    final failures = <String>[];

    try {
      await _providers.deleteAll();
    } catch (e, st) {
      _logWipeFailure('secure storage', e, st);
      failures.add('secure storage');
    }

    try {
      await _session.deleteAllSessionsAndMessages();
    } catch (e, st) {
      _logWipeFailure('chat history', e, st);
      failures.add('chat history');
    }

    try {
      await _project.deleteAllProjects();
    } catch (e, st) {
      _logWipeFailure('projects', e, st);
      failures.add('projects');
    }

    try {
      await _settings.resetOnboarding();
    } catch (e, st) {
      _logWipeFailure('onboarding flag', e, st);
      failures.add('onboarding flag');
    }

    return failures;
  }

  void _logWipeFailure(String step, Object e, StackTrace st) {
    if (e is AppException && e.originalError != null) {
      dLog(
        '[SettingsService] wipe $step failed: ${e.message} (cause: ${e.originalError})\n$st',
      );
    } else {
      dLog('[SettingsService] wipe $step failed: $e\n$st');
    }
  }
}
```

- [ ] **Step 9: Run build_runner**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -15
```

Expected: regenerates `.g.dart` for `settings_repository_impl`, `settings_service`, `settings_actions`. No errors.

- [ ] **Step 10: dart format**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && dart format lib/features/settings/ lib/features/providers/ lib/features/integrations/ lib/features/archive/ lib/data/settings/ lib/data/providers/ lib/services/settings/ lib/services/providers/
```

- [ ] **Step 11: Full analyze**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && flutter analyze lib/ 2>&1
```

Expected: No issues. Fix any errors before continuing.

- [ ] **Step 12: Run tests**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && flutter test 2>&1 | tail -10
```

Expected: same pass count as before this task (pure structural refactor — no behavior changes).

- [ ] **Step 13: Commit**

```bash
cd /Users/mk/Downloads/app/Benchlabs/code-bench-app/.worktrees/feat/2026-04-17-settings-providers-integrations && git add -A && git commit -m "refactor: split settings domain — providers/integrations/archive as sibling features with widget subfolders"
```

---

## Post-task manual verification

- [ ] Launch the app and open Settings → General tab: all prefs load and save; dropdowns open correctly
- [ ] Open Settings → Providers tab: all three API key cards expand/test/save correctly
- [ ] Open Settings → Integrations tab: GitHub OAuth and PAT flows work
- [ ] Open Settings → Archive tab: archived sessions list and unarchive action work
- [ ] General → Wipe all data (debug only): completes without errors
