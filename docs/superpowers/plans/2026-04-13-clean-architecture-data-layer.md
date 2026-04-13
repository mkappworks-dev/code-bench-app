# Clean Architecture Data Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `lib/services/` into a three-layer clean architecture (datasource → repository → service/use-case) with typed interfaces at every layer, so all I/O boundaries are encapsulated behind abstractions.

**Architecture:** Datasources own raw I/O (Dio, `Process.run`, `dart:io`, Drift). Repositories compose datasources and expose domain-level APIs. Use-case services (only `apply_service.dart` and `api_key_test_service.dart`) remain in `lib/services/` for multi-repository orchestration. Notifiers consume repositories or use-case services only.

**Tech Stack:** Flutter/Dart, Riverpod (riverpod_annotation), Drift, Dio, dart:io, flutter_secure_storage, flutter_web_auth_2

---

## File Map

**Created (new files):**
- `lib/data/_core/app_database.dart` — Drift DB + provider (moved from `datasources/local/`)
- `lib/data/_core/secure_storage.dart` — SecureStorage class + provider (renamed from `secure_storage_source.dart`)
- `lib/data/_core/preferences/general_preferences.dart` — moved
- `lib/data/_core/preferences/onboarding_preferences.dart` — moved
- `lib/data/_core/http/dio_factory.dart` — NEW: centralised Dio builder
- `lib/data/ai/datasource/ai_remote_datasource.dart` — abstract interface
- `lib/data/ai/datasource/anthropic_remote_datasource_dio.dart`
- `lib/data/ai/datasource/openai_remote_datasource_dio.dart`
- `lib/data/ai/datasource/gemini_remote_datasource_dio.dart`
- `lib/data/ai/datasource/ollama_remote_datasource_dio.dart`
- `lib/data/ai/datasource/custom_remote_datasource_dio.dart`
- `lib/data/ai/repository/ai_repository.dart` — abstract interface
- `lib/data/ai/repository/ai_repository_impl.dart`
- `lib/data/github/datasource/github_api_datasource.dart` — abstract interface
- `lib/data/github/datasource/github_api_datasource_dio.dart`
- `lib/data/github/datasource/github_auth_datasource.dart` — abstract interface
- `lib/data/github/datasource/github_auth_datasource_web.dart`
- `lib/data/github/repository/github_repository.dart` — abstract interface
- `lib/data/github/repository/github_repository_impl.dart`
- `lib/data/git/datasource/git_datasource.dart` — abstract interface
- `lib/data/git/datasource/git_datasource_process.dart`
- `lib/data/git/datasource/git_live_state_datasource.dart` — abstract interface
- `lib/data/git/datasource/git_live_state_datasource_process.dart`
- `lib/data/git/repository/git_repository.dart` — abstract interface
- `lib/data/git/repository/git_repository_impl.dart`
- `lib/data/project/datasource/project_datasource.dart` — abstract interface (DB)
- `lib/data/project/datasource/project_datasource_drift.dart`
- `lib/data/project/datasource/project_fs_datasource.dart` — abstract interface (disk)
- `lib/data/project/datasource/project_fs_datasource_io.dart`
- `lib/data/project/datasource/git_detector_datasource.dart` — abstract interface
- `lib/data/project/datasource/git_detector_datasource_io.dart`
- `lib/data/project/datasource/project_file_scan_datasource.dart` — abstract interface
- `lib/data/project/datasource/project_file_scan_datasource_io.dart`
- `lib/data/project/repository/project_repository.dart` — abstract interface
- `lib/data/project/repository/project_repository_impl.dart`
- `lib/data/session/datasource/session_datasource.dart` — abstract interface
- `lib/data/session/datasource/session_datasource_drift.dart`
- `lib/data/session/repository/session_repository.dart` — abstract interface
- `lib/data/session/repository/session_repository_impl.dart`
- `lib/data/filesystem/datasource/filesystem_datasource.dart` — abstract interface
- `lib/data/filesystem/datasource/filesystem_datasource_io.dart`
- `lib/data/filesystem/repository/filesystem_repository.dart` — abstract interface
- `lib/data/filesystem/repository/filesystem_repository_impl.dart`
- `lib/data/ide/datasource/ide_launch_datasource.dart` — abstract interface
- `lib/data/ide/datasource/ide_launch_datasource_process.dart`
- `lib/data/ide/repository/ide_launch_repository.dart` — abstract interface
- `lib/data/ide/repository/ide_launch_repository_impl.dart`
- `lib/data/settings/repository/settings_repository.dart` — abstract interface
- `lib/data/settings/repository/settings_repository_impl.dart`
- `lib/services/api_key_test_service.dart` — moved from `services/ai/`
- `test/arch_test.dart` — architectural boundary test

**Deleted:**
- `lib/data/datasources/local/` (entire folder, after move in Task 1)
- `lib/services/ai/` (entire folder, after Task 2)
- `lib/services/github/` (after Task 3)
- `lib/services/git/` (after Task 4)
- `lib/services/project/` (after Task 5)
- `lib/services/session/` (after Task 6)
- `lib/services/filesystem/` (after Task 6)
- `lib/services/ide/` (after Task 6)
- `lib/services/settings/` (after Task 6)

---

## Task 1: Scaffold `lib/data/_core/` — move local datasources

**Files:**
- Create: `lib/data/_core/app_database.dart`
- Create: `lib/data/_core/secure_storage.dart`
- Create: `lib/data/_core/preferences/general_preferences.dart`
- Create: `lib/data/_core/preferences/onboarding_preferences.dart`
- Create: `lib/data/_core/http/dio_factory.dart`
- Delete: `lib/data/datasources/local/` (all 8 files after creating replacements)
- Modify: all files that import from `lib/data/datasources/local/`

- [ ] **Step 1: Create `lib/data/_core/app_database.dart`**

Copy the content of `lib/data/datasources/local/app_database.dart` verbatim, but change the `part` directive:

```dart
// Change this line:
part 'app_database.g.dart';
// The rest of the file is identical.
```

The provider at the bottom keeps the same name `appDatabaseProvider`. The `part` file name stays `app_database.g.dart` — it will be regenerated in the new location.

- [ ] **Step 2: Create `lib/data/_core/secure_storage.dart`**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/debug_logger.dart';

part 'secure_storage.g.dart';

@Riverpod(keepAlive: true)
SecureStorage secureStorage(Ref ref) => SecureStorage();

/// Renamed from SecureStorageSource. Provider renamed from
/// secureStorageSourceProvider → secureStorageProvider.
class SecureStorage {
  // Full implementation is identical to SecureStorageSource in
  // lib/data/datasources/local/secure_storage_source.dart —
  // copy that file's body here, only the class name changes.
}
```

Copy the full class body from `lib/data/datasources/local/secure_storage_source.dart`. Class name: `SecureStorage` (was `SecureStorageSource`). Provider function name: `secureStorage` (was `secureStorageSource`). Provider variable: `secureStorageProvider` (was `secureStorageSourceProvider`).

- [ ] **Step 3: Create `lib/data/_core/preferences/general_preferences.dart`**

Copy `lib/data/datasources/local/general_preferences.dart` verbatim into the new path. Update the `part` directive to `part 'general_preferences.g.dart';`. No other changes.

- [ ] **Step 4: Create `lib/data/_core/preferences/onboarding_preferences.dart`**

Copy `lib/data/datasources/local/onboarding_preferences.dart` verbatim into the new path. Update the `part` directive to `part 'onboarding_preferences.g.dart';`. No other changes.

- [ ] **Step 5: Create `lib/data/_core/http/dio_factory.dart`**

```dart
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

/// Centralised Dio builder. Keeps BaseOptions configuration in one place.
/// Datasource implementations call [DioFactory.create] rather than
/// constructing Dio inline.
class DioFactory {
  const DioFactory._();

  static Dio create({
    required String baseUrl,
    Map<String, dynamic>? headers,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: headers ?? const {},
        connectTimeout: connectTimeout ?? ApiConstants.connectTimeout,
        receiveTimeout: receiveTimeout ?? ApiConstants.receiveTimeout,
      ),
    );
  }
}
```

- [ ] **Step 6: Update import paths across the codebase**

Find every file importing from `lib/data/datasources/local/` and update:

| Old import | New import | Extra change |
|---|---|---|
| `...datasources/local/app_database.dart` | `...data/_core/app_database.dart` | none |
| `...datasources/local/secure_storage_source.dart` | `...data/_core/secure_storage.dart` | `SecureStorageSource` → `SecureStorage`; `secureStorageSourceProvider` → `secureStorageProvider` |
| `...datasources/local/general_preferences.dart` | `...data/_core/preferences/general_preferences.dart` | none |
| `...datasources/local/onboarding_preferences.dart` | `...data/_core/preferences/onboarding_preferences.dart` | none |

Files to update (adjust relative path depth as needed):
- `lib/services/ai/ai_service_factory.dart` — update secure_storage import + rename `secureStorageSourceProvider` → `secureStorageProvider` and `SecureStorageSource` → `SecureStorage`
- `lib/services/github/github_api_service.dart` — same
- `lib/services/github/github_auth_service.dart` — same
- `lib/services/settings/settings_service.dart` — update all three pref imports + rename
- `lib/services/project/project_service.dart` — update app_database import
- `lib/services/session/session_service.dart` — update app_database import
- `lib/services/ide/ide_launch_service.dart` — update general_preferences import

- [ ] **Step 7: Delete old datasources/local folder**

```bash
rm -rf lib/data/datasources/local/
```

- [ ] **Step 8: Run build_runner to regenerate**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: exits 0, generates new `.g.dart` files in `lib/data/_core/` and `lib/data/_core/preferences/`. Old `.g.dart` files in the deleted folder are gone.

- [ ] **Step 9: Verify**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 10: Commit**

```bash
git add lib/data/_core/ lib/services/ lib/features/
git add -u   # stage deletions
dart format lib/ test/
git add lib/ test/
git commit -m "$(cat <<'EOF'
refactor(_core): move local datasources to lib/data/_core/

Renames SecureStorageSource → SecureStorage and its provider.
Adds DioFactory for centralised Dio construction.
Regenerates build_runner outputs at new paths.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: AI feature — datasources + AIRepositoryImpl

**Files:**
- Create: `lib/data/ai/datasource/ai_remote_datasource.dart`
- Create: `lib/data/ai/datasource/anthropic_remote_datasource_dio.dart`
- Create: `lib/data/ai/datasource/openai_remote_datasource_dio.dart`
- Create: `lib/data/ai/datasource/gemini_remote_datasource_dio.dart`
- Create: `lib/data/ai/datasource/ollama_remote_datasource_dio.dart`
- Create: `lib/data/ai/datasource/custom_remote_datasource_dio.dart`
- Create: `lib/data/ai/repository/ai_repository.dart`
- Create: `lib/data/ai/repository/ai_repository_impl.dart`
- Create: `lib/services/api_key_test_service.dart` (moved + updated)
- Modify: `lib/services/session/session_service.dart`
- Modify: `lib/features/settings/notifiers/settings_actions.dart`
- Modify: `lib/features/settings/notifiers/providers_notifier.dart`
- Delete: `lib/services/ai/` (entire folder)

- [ ] **Step 1: Create `lib/data/ai/datasource/ai_remote_datasource.dart`**

```dart
import '../../../data/models/ai_model.dart';
import '../../../data/models/chat_message.dart';

/// Single-provider I/O boundary. Speaks wire protocol only — no persistence,
/// no retries, no provider-selection logic.
abstract interface class AIRemoteDatasource {
  AIProvider get provider;

  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });

  Future<bool> testConnection(AIModel model, String apiKey);

  Future<List<AIModel>> fetchAvailableModels(String apiKey);
}
```

- [ ] **Step 2: Create `lib/data/ai/datasource/anthropic_remote_datasource_dio.dart`**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/ai_model.dart';
import '../../../data/models/chat_message.dart';
import '../../_core/http/dio_factory.dart';
import 'ai_remote_datasource.dart';

class AnthropicRemoteDatasourceDio implements AIRemoteDatasource {
  AnthropicRemoteDatasourceDio(String apiKey)
      : _dio = DioFactory.create(
          baseUrl: ApiConstants.anthropicBaseUrl,
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': ApiConstants.anthropicVersion,
            'content-type': 'application/json',
          },
        );

  final Dio _dio;

  @override
  AIProvider get provider => AIProvider.anthropic;

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    // Implementation identical to AnthropicService.streamMessage() in
    // lib/services/ai/anthropic_service.dart — copy that body here,
    // removing the sendMessage + _buildMessages duplication.
    // The _buildMessages helper is private to this file.
    final messages = _buildMessages(history, prompt);
    final body = <String, dynamic>{
      'model': model.modelId,
      'max_tokens': 4096,
      'messages': messages,
      'stream': true,
    };
    if (systemPrompt != null) body['system'] = systemPrompt;

    try {
      final response = await _dio.post(
        ApiConstants.anthropicChatEndpoint,
        data: body,
        options: Options(responseType: ResponseType.stream),
      );
      final stream = response.data as ResponseBody;
      final buffer = StringBuffer();
      await for (final chunk in stream.stream) {
        buffer.write(utf8.decode(chunk));
        final raw = buffer.toString();
        buffer.clear();
        for (final line in raw.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('data: ')) {
            final data = trimmed.substring(6);
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              if (json['type'] == 'content_block_delta') {
                final delta = json['delta']?['text'];
                if (delta is String && delta.isNotEmpty) yield delta;
              }
            } catch (_) {}
          }
        }
      }
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Anthropic request failed',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async {
    // Identical to AnthropicService.testConnection() — copy body here.
    try {
      final testDio = DioFactory.create(
        baseUrl: ApiConstants.anthropicBaseUrl,
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': ApiConstants.anthropicVersion,
          'content-type': 'application/json',
        },
      );
      await testDio.post(
        ApiConstants.anthropicChatEndpoint,
        data: {
          'model': model.modelId,
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'hi'},
          ],
        },
      );
      return true;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) return true;
      return false;
    }
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) {
    return Future.value(
      AIModels.defaults.where((m) => m.provider == AIProvider.anthropic).toList(),
    );
  }

  List<Map<String, String>> _buildMessages(List<ChatMessage> history, String prompt) {
    final messages = <Map<String, String>>[];
    for (final msg in history.where((m) => m.role != MessageRole.system)) {
      messages.add({'role': msg.role.value, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': prompt});
    return messages;
  }
}
```

- [ ] **Step 3: Create the remaining four datasource files**

Create these files following the same pattern as the Anthropic datasource. Port `streamMessage`, `testConnection`, and `fetchAvailableModels` from their old service files. Remove `sendMessage` (it moves to `AIRepositoryImpl`). Replace inline `Dio(BaseOptions(...))` with `DioFactory.create(...)`.

**`lib/data/ai/datasource/openai_remote_datasource_dio.dart`**
- Port from `lib/services/ai/openai_service.dart`
- Constructor: `OpenAIRemoteDatasourceDio(String apiKey)`
- Provider: `AIProvider.openai`
- `DioFactory.create(baseUrl: ApiConstants.openAiBaseUrl, headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'})`
- `streamMessage`: copy from `OpenAIService.streamMessage()`
- `testConnection`: copy from `OpenAIService.testConnection()`
- `fetchAvailableModels`: copy from `OpenAIService.fetchAvailableModels()`

**`lib/data/ai/datasource/gemini_remote_datasource_dio.dart`**
- Port from `lib/services/ai/gemini_service.dart`
- Constructor: `GeminiRemoteDatasourceDio(String apiKey)` — Note: Gemini appends `?key=$apiKey` to endpoints, not a header. Store the key as a field, use `DioFactory.create(baseUrl: ApiConstants.geminiBaseUrl)`.
- `streamMessage`, `testConnection`, `fetchAvailableModels`: copy from `GeminiService`.

**`lib/data/ai/datasource/ollama_remote_datasource_dio.dart`**
- Port from `lib/services/ai/ollama_service.dart`
- Constructor: `OllamaRemoteDatasourceDio(String baseUrl)`
- `DioFactory.create(baseUrl: baseUrl)`

**`lib/data/ai/datasource/custom_remote_datasource_dio.dart`**
- Port from `lib/services/ai/custom_ai_service.dart`
- Constructor: `CustomRemoteDatasourceDio({required String endpoint, required String apiKey})`
- `DioFactory.create(baseUrl: endpoint, headers: {if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'})`

- [ ] **Step 4: Create `lib/data/ai/repository/ai_repository.dart`**

```dart
import '../../../data/models/ai_model.dart';
import '../../../data/models/chat_message.dart';

/// Domain-level AI API. Abstracts provider selection and stream buffering.
abstract interface class AIRepository {
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });

  /// Buffers [streamMessage] into a single [ChatMessage]. The buffering
  /// logic is implemented once here — not duplicated per provider.
  Future<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  });

  Future<bool> testConnection(AIModel model, String apiKey);

  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey);
}
```

- [ ] **Step 5: Create `lib/data/ai/repository/ai_repository_impl.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/models/ai_model.dart';
import '../../../data/models/chat_message.dart';
import '../../_core/secure_storage.dart';
import '../datasource/ai_remote_datasource.dart';
import '../datasource/anthropic_remote_datasource_dio.dart';
import '../datasource/openai_remote_datasource_dio.dart';
import '../datasource/gemini_remote_datasource_dio.dart';
import '../datasource/ollama_remote_datasource_dio.dart';
import '../datasource/custom_remote_datasource_dio.dart';
import 'ai_repository.dart';

part 'ai_repository_impl.g.dart';

/// Builds [AIRepositoryImpl] by reading stored keys from [SecureStorage].
/// Rebuilds (and creates fresh Dio clients) when [secureStorageProvider]
/// changes. Callers that save new API keys must call
/// `ref.invalidate(aiRepositoryProvider)` to pick up the new credentials.
@Riverpod(keepAlive: true)
Future<AIRepository> aiRepository(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return AIRepositoryImpl(sources: {
    AIProvider.anthropic: AnthropicRemoteDatasourceDio(
      await storage.readApiKey('anthropic') ?? '',
    ),
    AIProvider.openai: OpenAIRemoteDatasourceDio(
      await storage.readApiKey('openai') ?? '',
    ),
    AIProvider.gemini: GeminiRemoteDatasourceDio(
      await storage.readApiKey('gemini') ?? '',
    ),
    AIProvider.ollama: OllamaRemoteDatasourceDio(
      await storage.readOllamaUrl() ?? ApiConstants.ollamaDefaultBaseUrl,
    ),
    AIProvider.custom: CustomRemoteDatasourceDio(
      endpoint: await storage.readCustomEndpoint() ?? '',
      apiKey: await storage.readCustomApiKey() ?? '',
    ),
  });
}

class AIRepositoryImpl implements AIRepository {
  AIRepositoryImpl({required Map<AIProvider, AIRemoteDatasource> sources})
      : _sources = sources;

  final Map<AIProvider, AIRemoteDatasource> _sources;
  static const _uuid = Uuid();

  AIRemoteDatasource _source(AIProvider provider) {
    final src = _sources[provider];
    if (src == null) throw StateError('No datasource registered for $provider');
    return src;
  }

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) {
    return _source(model.provider).streamMessage(
      history: history,
      prompt: prompt,
      model: model,
      systemPrompt: systemPrompt,
    );
  }

  /// Buffers [streamMessage] — the single implementation shared by all providers.
  @override
  Future<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in streamMessage(
      history: history,
      prompt: prompt,
      model: model,
      systemPrompt: systemPrompt,
    )) {
      buffer.write(chunk);
    }
    return ChatMessage(
      id: _uuid.v4(),
      sessionId: history.isNotEmpty ? history.first.sessionId : '',
      role: MessageRole.assistant,
      content: buffer.toString(),
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) {
    return _source(model.provider).testConnection(model, apiKey);
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(AIProvider provider, String apiKey) {
    return _source(provider).fetchAvailableModels(apiKey);
  }
}
```

- [ ] **Step 6: Create `lib/services/api_key_test_service.dart`**

Move `lib/services/ai/api_key_test_service.dart` to this path and update the import:

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/_core/http/dio_factory.dart';
import '../data/models/ai_model.dart';

part 'api_key_test_service.g.dart';

@Riverpod(keepAlive: true)
ApiKeyTestService apiKeyTestService(Ref ref) => ApiKeyTestService();

/// Validates AI provider credentials via live HTTP probes using temporary
/// Dio instances — never uses the stored repository credentials.
class ApiKeyTestService {
  Future<bool> testApiKey(AIProvider provider, String key) {
    return switch (provider) {
      AIProvider.openai => _testOpenAI(key),
      AIProvider.anthropic => _testAnthropic(key),
      AIProvider.gemini => _testGemini(key),
      _ => Future.value(false),
    };
  }

  Future<bool> testOllamaUrl(String url) async {
    try {
      final dio = DioFactory.create(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 5),
      );
      await dio.get('/api/tags');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _testOpenAI(String key) async {
    // Identical body to ApiKeyTestService._testOpenAI() in old location —
    // replace inline Dio constructor with DioFactory.create().
    try {
      final dio = DioFactory.create(
        baseUrl: 'https://api.openai.com/v1',
        connectTimeout: const Duration(seconds: 10),
        headers: {'Authorization': 'Bearer $key'},
      );
      await dio.get('/models');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _testAnthropic(String key) async {
    // Identical body — replace inline Dio with DioFactory.create().
    try {
      final dio = DioFactory.create(
        baseUrl: 'https://api.anthropic.com/v1',
        connectTimeout: const Duration(seconds: 10),
        headers: {
          'x-api-key': key,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
      );
      await dio.post(
        '/messages',
        data: {
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'hi'},
          ],
        },
      );
      return true;
    } on DioException catch (e) {
      return e.response?.statusCode == 400;
    }
  }

  Future<bool> _testGemini(String key) async {
    try {
      final dio = DioFactory.create(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        connectTimeout: const Duration(seconds: 10),
        headers: {'x-goog-api-key': key},
      );
      await dio.get('/models');
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

- [ ] **Step 7: Update `lib/services/session/session_service.dart`**

Replace the `aiServiceProvider` import and usage:

```dart
// Remove this import:
// import '../ai/ai_service_factory.dart';

// Add this import:
import '../../data/ai/repository/ai_repository_impl.dart';

// In sendAndStream(), replace:
//   final service = await _ref.read(aiServiceProvider(model.provider).future);
//   if (service == null) { throw Exception(...); }
//   await for (final chunk in service.streamMessage(...)) { ... }
// With:
    final repo = await _ref.read(aiRepositoryProvider.future);
    await for (final chunk in repo.streamMessage(
      history: historyExcludingCurrent,
      prompt: userInput,
      model: model,
      systemPrompt: systemPrompt,
    )) { ... }
// Remove the null check — aiRepository always returns a valid instance.
```

- [ ] **Step 8: Update `lib/features/settings/notifiers/settings_actions.dart`**

```dart
// Replace import:
// import '../../../services/ai/api_key_test_service.dart';
import '../../../services/api_key_test_service.dart';
```

Also in `wipeAllData()`, replace `ref.invalidate(aiServiceProvider)` with `ref.invalidate(aiRepositoryProvider)` and add import for `ai_repository_impl.dart`.

- [ ] **Step 9: Update `lib/features/settings/notifiers/providers_notifier.dart`**

```dart
// Remove:
// import '../../../services/ai/ai_service_factory.dart';

// Add:
import '../../../data/ai/repository/ai_repository_impl.dart';

// In saveAll() and deleteKey(), replace:
//   ref.invalidate(aiServiceProvider);
// With:
    ref.invalidate(aiRepositoryProvider);
```

- [ ] **Step 10: Delete `lib/services/ai/`**

```bash
rm -rf lib/services/ai/
```

- [ ] **Step 11: Regenerate + verify**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

Expected: No issues.

- [ ] **Step 12: Commit**

```bash
dart format lib/ test/
git add lib/data/ai/ lib/services/api_key_test_service.dart
git add lib/services/session/ lib/features/settings/notifiers/
git add -u
git commit -m "$(cat <<'EOF'
refactor(ai): introduce AIRemoteDatasource + AIRepositoryImpl

Replaces 5 AIService providers + AIServiceFactory with typed datasources
and a single AIRepositoryImpl that owns sendMessage buffering (eliminates
5x duplication). Moves ApiKeyTestService to lib/services/ root.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: GitHub feature

**Files:**
- Create: `lib/data/github/datasource/github_api_datasource.dart`
- Create: `lib/data/github/datasource/github_api_datasource_dio.dart`
- Create: `lib/data/github/datasource/github_auth_datasource.dart`
- Create: `lib/data/github/datasource/github_auth_datasource_web.dart`
- Create: `lib/data/github/repository/github_repository.dart`
- Create: `lib/data/github/repository/github_repository_impl.dart`
- Modify: `lib/features/onboarding/notifiers/github_auth_notifier.dart`
- Modify: `lib/features/chat/notifiers/create_pr_actions.dart`
- Modify: `lib/features/chat/notifiers/pr_notifier.dart`
- Delete: `lib/services/github/`

- [ ] **Step 1: Create `lib/data/github/datasource/github_api_datasource.dart`**

```dart
import '../../../data/models/repository.dart';

abstract interface class GitHubApiDatasource {
  Future<List<Repository>> listRepositories({int page = 1});
  Future<List<Repository>> searchRepositories(String query);
  Future<String?> validateToken();
  Future<List<GitTreeItem>> getRepositoryTree(String owner, String repo, String branch);
  Future<String> getFileContent(String owner, String repo, String path, String branch);
  Future<List<String>> listBranches(String owner, String repo);
  Future<List<Map<String, dynamic>>> listPullRequests(String owner, String repo, {String state});
  Future<Map<String, dynamic>> getPullRequest(String owner, String repo, int number);
  Future<List<Map<String, dynamic>>> getCheckRuns(String owner, String repo, String sha);
  Future<void> approvePullRequest(String owner, String repo, int number);
  Future<void> mergePullRequest(String owner, String repo, int number);
  Future<String> createPullRequest({
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft,
  });
}
```

- [ ] **Step 2: Create `lib/data/github/datasource/github_api_datasource_dio.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/models/repository.dart';
import '../../_core/http/dio_factory.dart';
import '../../_core/secure_storage.dart';
import 'github_api_datasource.dart';

part 'github_api_datasource_dio.g.dart';

@Riverpod(keepAlive: true)
Future<GitHubApiDatasource?> githubApiDatasource(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  final token = await storage.readGitHubToken();
  if (token == null) return null;
  return GitHubApiDatasourceDio(token);
}

/// Implementation identical to [GitHubApiService] — copy all methods here.
/// Provider renamed: githubApiDatasourceProvider (was githubApiServiceProvider).
class GitHubApiDatasourceDio implements GitHubApiDatasource {
  GitHubApiDatasourceDio(String token)
      : _dio = DioFactory.create(
          baseUrl: ApiConstants.githubApiBaseUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.github.v3+json',
          },
        );

  // SECURITY: Do NOT add LogInterceptor(requestHeader: true).
  // The Authorization header contains the user's GitHub PAT.

  final Dio _dio;

  // Copy all method implementations verbatim from GitHubApiService.
  // The _repoFromGitHub() and _safeBranchName helpers are identical.
  @override
  Future<List<Repository>> listRepositories({int page = 1}) async {
    // copy from GitHubApiService.listRepositories
    throw UnimplementedError(); // replace with actual body
  }
  // ... (all other methods copied verbatim)
}
```

Fill in all method bodies by copying from `lib/services/github/github_api_service.dart`.

- [ ] **Step 3: Create `lib/data/github/datasource/github_auth_datasource.dart`**

```dart
import '../../../data/models/repository.dart';

abstract interface class GitHubAuthDatasource {
  Future<GitHubAccount> authenticate();
  Future<GitHubAccount> signInWithPat(String token);
  Future<GitHubAccount?> getStoredAccount();
  Future<bool> isAuthenticated();
  Future<void> signOut();
}
```

- [ ] **Step 4: Create `lib/data/github/datasource/github_auth_datasource_web.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/repository.dart';
import '../../_core/secure_storage.dart';
import 'github_auth_datasource.dart';

part 'github_auth_datasource_web.g.dart';

@Riverpod(keepAlive: true)
GitHubAuthDatasource githubAuthDatasource(Ref ref) {
  return GitHubAuthDatasourceWeb(ref.watch(secureStorageProvider));
}

/// Copy all method bodies verbatim from GitHubAuthService.
/// Class name: GitHubAuthDatasourceWeb (was GitHubAuthService).
/// Provider: githubAuthDatasourceProvider (was githubAuthServiceProvider).
class GitHubAuthDatasourceWeb implements GitHubAuthDatasource {
  GitHubAuthDatasourceWeb(this._storage);
  final SecureStorage _storage;
  static const _clientId = 'YOUR_GITHUB_CLIENT_ID'; // unchanged

  // Copy authenticate(), signInWithPat(), _exchangeCodeForToken(),
  // _fetchUserInfo(), getStoredAccount(), isAuthenticated(), signOut()
  // verbatim from GitHubAuthService.
}
```

- [ ] **Step 5: Create `lib/data/github/repository/github_repository.dart`**

```dart
import '../../../data/models/repository.dart';

abstract interface class GitHubRepository {
  // Mirrors GitHubApiDatasource + GitHubAuthDatasource public surface.
  // Auth methods:
  Future<GitHubAccount> authenticate();
  Future<GitHubAccount> signInWithPat(String token);
  Future<GitHubAccount?> getStoredAccount();
  Future<bool> isAuthenticated();
  Future<void> signOut();
  // API methods:
  Future<List<Repository>> listRepositories({int page});
  Future<List<Repository>> searchRepositories(String query);
  Future<String?> validateToken();
  Future<List<GitTreeItem>> getRepositoryTree(String owner, String repo, String branch);
  Future<String> getFileContent(String owner, String repo, String path, String branch);
  Future<List<String>> listBranches(String owner, String repo);
  Future<List<Map<String, dynamic>>> listPullRequests(String owner, String repo, {String state});
  Future<Map<String, dynamic>> getPullRequest(String owner, String repo, int number);
  Future<List<Map<String, dynamic>>> getCheckRuns(String owner, String repo, String sha);
  Future<void> approvePullRequest(String owner, String repo, int number);
  Future<void> mergePullRequest(String owner, String repo, int number);
  Future<String> createPullRequest({
    required String owner, required String repo, required String title,
    required String body, required String head, required String base, bool draft,
  });
}
```

- [ ] **Step 6: Create `lib/data/github/repository/github_repository_impl.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/repository.dart';
import '../datasource/github_api_datasource.dart';
import '../datasource/github_api_datasource_dio.dart';
import '../datasource/github_auth_datasource.dart';
import '../datasource/github_auth_datasource_web.dart';
import 'github_repository.dart';

part 'github_repository_impl.g.dart';

@Riverpod(keepAlive: true)
GitHubRepository githubRepository(Ref ref) {
  return GitHubRepositoryImpl(
    auth: ref.watch(githubAuthDatasourceProvider),
    api: ref.watch(githubApiDatasourceProvider).valueOrNull,
  );
}

class GitHubRepositoryImpl implements GitHubRepository {
  GitHubRepositoryImpl({required GitHubAuthDatasource auth, GitHubApiDatasource? api})
      : _auth = auth,
        _api = api;

  final GitHubAuthDatasource _auth;
  final GitHubApiDatasource? _api;

  // Auth delegates to _auth:
  @override Future<GitHubAccount> authenticate() => _auth.authenticate();
  @override Future<GitHubAccount> signInWithPat(String token) => _auth.signInWithPat(token);
  @override Future<GitHubAccount?> getStoredAccount() => _auth.getStoredAccount();
  @override Future<bool> isAuthenticated() => _auth.isAuthenticated();
  @override Future<void> signOut() => _auth.signOut();

  // API methods delegate to _api, throwing if not authenticated:
  GitHubApiDatasource get _requireApi {
    if (_api == null) throw StateError('GitHub not authenticated');
    return _api!;
  }

  @override Future<List<Repository>> listRepositories({int page = 1}) =>
      _requireApi.listRepositories(page: page);
  // ... (all remaining methods delegate to _requireApi)
}
```

Fill in the remaining delegating method implementations.

- [ ] **Step 7: Update consumers**

In every notifier that imports `githubApiServiceProvider` or `githubAuthServiceProvider`:

| Old provider | New provider | Old import path | New import path |
|---|---|---|---|
| `githubApiServiceProvider` | `githubRepositoryProvider` | `services/github/github_api_service.dart` | `data/github/repository/github_repository_impl.dart` |
| `githubAuthServiceProvider` | `githubRepositoryProvider` | `services/github/github_auth_service.dart` | `data/github/repository/github_repository_impl.dart` |

Files to update:
- `lib/features/onboarding/notifiers/github_auth_notifier.dart`
- `lib/features/chat/notifiers/create_pr_actions.dart`
- `lib/features/chat/notifiers/pr_notifier.dart`

Pattern: wherever `ref.read(githubApiServiceProvider.future)` is used, replace with `ref.read(githubRepositoryProvider)` (sync, no `.future`).

- [ ] **Step 8: Delete `lib/services/github/`**

```bash
rm -rf lib/services/github/
```

- [ ] **Step 9: Regenerate + verify + commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format lib/ test/
git add lib/data/github/ lib/features/
git add -u
git commit -m "$(cat <<'EOF'
refactor(github): introduce GitHubApiDatasource + GitHubRepository

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Git feature

**Files:**
- Create: `lib/data/git/datasource/git_datasource.dart`
- Create: `lib/data/git/datasource/git_datasource_process.dart`
- Create: `lib/data/git/datasource/git_live_state_datasource.dart`
- Create: `lib/data/git/datasource/git_live_state_datasource_process.dart`
- Create: `lib/data/git/repository/git_repository.dart`
- Create: `lib/data/git/repository/git_repository_impl.dart`
- Modify: `lib/shell/notifiers/git_actions.dart`
- Modify: `lib/shell/notifiers/git_remotes_notifier.dart`
- Modify: `lib/shell/notifiers/commit_message_actions.dart`
- Modify: `lib/shell/notifiers/commit_push_button_notifier.dart`
- Modify: `lib/shell/notifiers/status_bar_notifier.dart`
- Modify: `lib/shell/notifiers/top_action_bar_notifier.dart`
- Modify: `lib/shell/widgets/app_lifecycle_observer.dart`
- Modify: `lib/features/branch_picker/notifiers/branch_picker_notifier.dart`
- Modify: `lib/features/chat/notifiers/code_apply_actions.dart`
- Modify: `lib/features/project_sidebar/widgets/project_tile.dart`
- Delete: `lib/services/git/`
- Delete: `lib/services/project/git_detector.dart`

- [ ] **Step 1: Create `lib/data/git/datasource/git_datasource.dart`**

```dart
import '../../../services/git/git_live_state.dart';

// GitLiveState value object stays importable from its old location until
// Task 4 moves it. After this task it lives in lib/data/git/.
// For now re-export it so consumers don't need two imports.

abstract interface class GitDatasource {
  Future<void> initGit();
  Future<String> commit(String message);        // returns short SHA
  Future<String> push();                        // returns branch name
  Future<void> pushToRemote(String remote);
  Future<int> pull();                           // returns commit count
  Future<int?> fetchBehindCount();
  Future<String?> currentBranch();
  Future<String?> getOriginUrl();
  Future<List<GitRemote>> listRemotes();
  Future<List<String>> listLocalBranches();
  Future<Set<String>> worktreeBranches();
  Future<void> checkout(String branch);
  Future<void> createBranch(String name);
}

class GitRemote {
  const GitRemote({required this.name, required this.url});
  final String name;
  final String url;
}
```

- [ ] **Step 2: Create `lib/data/git/datasource/git_datasource_process.dart`**

```dart
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import 'git_datasource.dart';

part 'git_datasource_process.g.dart';

@riverpod
GitDatasource gitDatasource(Ref ref, String projectPath) =>
    GitDatasourceProcess(projectPath);

/// Implementation identical to [GitService] — copy every method body here.
/// Class name: GitDatasourceProcess (was GitService).
/// Provider: gitDatasourceProvider (was gitServiceProvider).
///
/// Exception types ([GitException], [GitNoUpstreamException],
/// [GitAuthException], [GitConflictException]) are moved to this file
/// since they are part of the git datasource contract.
class GitException implements Exception {
  const GitException(this.message);
  final String message;
  @override String toString() => 'GitException: $message';
}
class GitNoUpstreamException extends GitException {
  const GitNoUpstreamException(String branch) : super('No upstream branch for $branch');
}
class GitAuthException extends GitException {
  const GitAuthException() : super('Authentication failed');
}
class GitConflictException extends GitException {
  const GitConflictException() : super('Merge conflict detected');
}

class GitDatasourceProcess implements GitDatasource {
  GitDatasourceProcess(this._projectPath);
  final String _projectPath;

  // Copy _sanitizeGitStderr, initGit, commit, push, pushToRemote, pull,
  // fetchBehindCount, currentBranch, _currentBranch, _headSha, getOriginUrl,
  // listRemotes, listLocalBranches, worktreeBranches, checkout, createBranch
  // verbatim from GitService — only changing Process.run workingDirectory
  // argument to use _projectPath instead of this.projectPath.
}
```

- [ ] **Step 3: Create `lib/data/git/datasource/git_live_state_datasource.dart`**

```dart
import '../git_live_state.dart';

abstract interface class GitLiveStateDatasource {
  Future<GitLiveState> fetchLiveState(String projectPath);
  Future<int?> fetchBehindCount(String projectPath);
  bool isGitRepo(String projectPath);
}
```

Also create `lib/data/git/git_live_state.dart` — move `GitLiveState` class from `lib/services/git/git_live_state.dart` verbatim (file content is identical, only the path changes).

- [ ] **Step 4: Create `lib/data/git/datasource/git_live_state_datasource_process.dart`**

```dart
import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../git_live_state.dart';
import 'git_datasource.dart';
import 'git_live_state_datasource.dart';
import 'git_detector_datasource_io.dart'; // will exist after Task 5; use GitDetector directly for now

part 'git_live_state_datasource_process.g.dart';

@riverpod
GitLiveStateDatasource gitLiveStateDatasource(Ref ref) =>
    GitLiveStateDatasourceProcess();

/// Implements live git state probes via Process.run.
/// Replaces the free functions in git_live_state_provider.dart.
class GitLiveStateDatasourceProcess implements GitLiveStateDatasource {
  @override
  bool isGitRepo(String projectPath) {
    // Copy GitDetector.isGitRepo() logic here for now; Task 5 introduces
    // GitDetectorDatasource — at that point, inject it instead.
    final gitPath = '$projectPath${Platform.pathSeparator}.git';
    return FileSystemEntity.typeSync(gitPath) == FileSystemEntityType.directory;
    // Note: full GitDetector validation (worktree .git file check) is ported
    // in Task 5. For now this is a simpler check that covers the common case.
    // The _isValidWorktreeGitFile() logic moves to GitDetectorDatasourceIo.
  }

  @override
  Future<GitLiveState> fetchLiveState(String projectPath) async {
    // Port gitLiveState() provider function body here.
    // Replace GitDetector.isGitRepo() with this.isGitRepo().
    // Replace GitService(projectPath) instantiation with GitDatasourceProcess(projectPath).
    if (!isGitRepo(projectPath)) return GitLiveState.notGit;
    final git = GitDatasourceProcess(projectPath);
    final results = await Future.wait([
      git.currentBranch(),
      _hasUncommitted(projectPath),
      _aheadCount(projectPath),
    ]);
    final branch = results[0] as String?;
    final hasUncommitted = results[1] as bool?;
    final aheadCount = results[2] as int?;
    return GitLiveState(
      isGit: true,
      branch: branch,
      hasUncommitted: hasUncommitted,
      aheadCount: aheadCount,
      isOnDefaultBranch: branch == 'main' || branch == 'master',
    );
  }

  @override
  Future<int?> fetchBehindCount(String projectPath) async {
    // Port behindCount() provider function body here.
    if (!isGitRepo(projectPath)) return null;
    return GitDatasourceProcess(projectPath).fetchBehindCount();
  }

  // Port _hasUncommitted() and _aheadCount() free functions from
  // git_live_state_provider.dart as private methods here.
  Future<bool?> _hasUncommitted(String projectPath) async { /* ... */ }
  Future<int?> _aheadCount(String projectPath) async { /* ... */ }
}
```

- [ ] **Step 5: Create `lib/data/git/repository/git_repository.dart`**

```dart
import '../git_live_state.dart';
import '../datasource/git_datasource.dart';

export '../datasource/git_datasource.dart' show GitRemote, GitException,
    GitNoUpstreamException, GitAuthException, GitConflictException;

abstract interface class GitRepository {
  // All methods from GitDatasource (forwarded through):
  Future<void> initGit(String projectPath);
  Future<String> commit(String projectPath, String message);
  Future<String> push(String projectPath);
  Future<void> pushToRemote(String projectPath, String remote);
  Future<int> pull(String projectPath);
  Future<int?> fetchBehindCount(String projectPath);
  Future<String?> currentBranch(String projectPath);
  Future<String?> getOriginUrl(String projectPath);
  Future<List<GitRemote>> listRemotes(String projectPath);
  Future<List<String>> listLocalBranches(String projectPath);
  Future<Set<String>> worktreeBranches(String projectPath);
  Future<void> checkout(String projectPath, String branch);
  Future<void> createBranch(String projectPath, String name);
  // Live state:
  Future<GitLiveState> fetchLiveState(String projectPath);
  Future<int?> behindCount(String projectPath);
  bool isGitRepo(String projectPath);
}
```

- [ ] **Step 6: Create `lib/data/git/repository/git_repository_impl.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/git_datasource.dart';
import '../datasource/git_datasource_process.dart';
import '../datasource/git_live_state_datasource.dart';
import '../datasource/git_live_state_datasource_process.dart';
import '../git_live_state.dart';
import 'git_repository.dart';

part 'git_repository_impl.g.dart';

@Riverpod(keepAlive: true)
GitRepository gitRepository(Ref ref) {
  return GitRepositoryImpl(
    datasource: ref.watch(gitDatasourceProvider('__static__')),
    liveState: ref.watch(gitLiveStateDatasourceProvider),
  );
}
```

Wait — `gitDatasource` is a family provider keyed by `projectPath`. The repository needs to delegate per-call. Restructure:

```dart
@Riverpod(keepAlive: true)
GitRepository gitRepository(Ref ref) {
  return GitRepositoryImpl(
    liveState: ref.watch(gitLiveStateDatasourceProvider),
  );
}

class GitRepositoryImpl implements GitRepository {
  GitRepositoryImpl({required GitLiveStateDatasource liveState})
      : _liveState = liveState;

  final GitLiveStateDatasource _liveState;

  // For process-based operations, create the datasource per-call.
  // This matches the current pattern (GitService was created per projectPath).
  GitDatasource _ds(String projectPath) => GitDatasourceProcess(projectPath);

  @override Future<void> initGit(String projectPath) => _ds(projectPath).initGit();
  @override Future<String> commit(String p, String msg) => _ds(p).commit(msg);
  @override Future<String> push(String p) => _ds(p).push();
  @override Future<void> pushToRemote(String p, String remote) => _ds(p).pushToRemote(remote);
  @override Future<int> pull(String p) => _ds(p).pull();
  @override Future<int?> fetchBehindCount(String p) => _ds(p).fetchBehindCount();
  @override Future<String?> currentBranch(String p) => _ds(p).currentBranch();
  @override Future<String?> getOriginUrl(String p) => _ds(p).getOriginUrl();
  @override Future<List<GitRemote>> listRemotes(String p) => _ds(p).listRemotes();
  @override Future<List<String>> listLocalBranches(String p) => _ds(p).listLocalBranches();
  @override Future<Set<String>> worktreeBranches(String p) => _ds(p).worktreeBranches();
  @override Future<void> checkout(String p, String branch) => _ds(p).checkout(branch);
  @override Future<void> createBranch(String p, String name) => _ds(p).createBranch(name);
  @override Future<GitLiveState> fetchLiveState(String p) => _liveState.fetchLiveState(p);
  @override Future<int?> behindCount(String p) => _liveState.fetchBehindCount(p);
  @override bool isGitRepo(String p) => _liveState.isGitRepo(p);
}
```

- [ ] **Step 7: Update all consumers of `gitServiceProvider` and `gitLiveStateProvider`**

Replace in every file:

| Old | New |
|---|---|
| `import '...services/git/git_service.dart'` | `import '...data/git/repository/git_repository_impl.dart'` |
| `import '...services/git/git_live_state_provider.dart'` | `import '...data/git/repository/git_repository_impl.dart'` |
| `import '...services/git/git_live_state.dart'` | `import '...data/git/git_live_state.dart'` |
| `ref.read(gitServiceProvider(path))` | `ref.read(gitRepositoryProvider)` |
| `ref.watch(gitLiveStateProvider(path))` | see note below |

The `gitLiveStateProvider` and `behindCountProvider` were family providers returning `Future<GitLiveState>` and `Future<int?>`. Create replacement Riverpod providers in `git_repository_impl.dart`:

```dart
// Add these convenience providers in git_repository_impl.dart:
@riverpod
Future<GitLiveState> gitLiveState(Ref ref, String projectPath) =>
    ref.watch(gitRepositoryProvider).fetchLiveState(projectPath);

@riverpod
Future<int?> behindCount(Ref ref, String projectPath) async {
  final timer = Timer.periodic(const Duration(minutes: 5), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.watch(gitRepositoryProvider).behindCount(projectPath);
}
```

Files to update: `shell/notifiers/git_actions.dart`, `shell/notifiers/commit_push_button_notifier.dart`, `shell/notifiers/status_bar_notifier.dart`, `shell/notifiers/top_action_bar_notifier.dart`, `shell/notifiers/git_remotes_notifier.dart`, `shell/notifiers/commit_message_actions.dart`, `shell/widgets/app_lifecycle_observer.dart`, `features/branch_picker/notifiers/branch_picker_notifier.dart`, `features/chat/notifiers/code_apply_actions.dart`, `features/project_sidebar/widgets/project_tile.dart`.

In `git_actions.dart`, update the `_git(projectPath)` helper:
```dart
// Before:
GitService _git(String projectPath) => ref.read(gitServiceProvider(projectPath));
// After:
GitRepository _git() => ref.read(gitRepositoryProvider);
// And update all method calls: _git(projectPath).commit(msg) → _git().commit(projectPath, msg)
```

- [ ] **Step 8: Delete `lib/services/git/` and `lib/services/project/git_detector.dart`**

```bash
rm -rf lib/services/git/
rm lib/services/project/git_detector.dart
```

- [ ] **Step 9: Regenerate + verify + commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format lib/ test/
git add lib/data/git/ lib/shell/ lib/features/
git add -u
git commit -m "$(cat <<'EOF'
refactor(git): introduce GitDatasource + GitRepository

Replaces GitService (family provider) and free git_live_state functions
with GitRepository (singleton, path as method arg).

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Project feature

**Files:**
- Create: `lib/data/project/datasource/project_datasource.dart`
- Create: `lib/data/project/datasource/project_datasource_drift.dart`
- Create: `lib/data/project/datasource/project_fs_datasource.dart`
- Create: `lib/data/project/datasource/project_fs_datasource_io.dart`
- Create: `lib/data/project/datasource/git_detector_datasource.dart`
- Create: `lib/data/project/datasource/git_detector_datasource_io.dart`
- Create: `lib/data/project/datasource/project_file_scan_datasource.dart`
- Create: `lib/data/project/datasource/project_file_scan_datasource_io.dart`
- Create: `lib/data/project/repository/project_repository.dart`
- Create: `lib/data/project/repository/project_repository_impl.dart`
- Modify: `lib/features/project_sidebar/notifiers/project_sidebar_notifier.dart`
- Modify: `lib/features/project_sidebar/notifiers/project_sidebar_actions.dart`
- Modify: `lib/features/chat/notifiers/project_file_scan_actions.dart`
- Modify: `lib/features/settings/notifiers/settings_actions.dart`
- Delete: `lib/services/project/`

- [ ] **Step 1: Create `lib/data/project/datasource/project_datasource.dart`**

```dart
import '../../../../data/_core/app_database.dart';

abstract interface class ProjectDatasource {
  Stream<List<WorkspaceProjectRow>> watchAllProjectRows();
  Future<List<WorkspaceProjectRow>> getAllProjectRows();
  Future<WorkspaceProjectRow?> getProjectRow(String id);
  Future<WorkspaceProjectRow?> getProjectRowByPath(String path);
  Future<void> upsertProjectRow(WorkspaceProjectsCompanion row);
  Future<void> updateProjectRow(String id, WorkspaceProjectsCompanion companion);
  Future<void> deleteProjectRow(String id);
  Future<void> deleteAllProjectRows();
}
```

- [ ] **Step 2: Create `lib/data/project/datasource/project_datasource_drift.dart`**

```dart
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/_core/app_database.dart';
import 'project_datasource.dart';

part 'project_datasource_drift.g.dart';

@Riverpod(keepAlive: true)
ProjectDatasource projectDatasource(Ref ref) =>
    ProjectDatasourceDrift(ref.watch(appDatabaseProvider));

class ProjectDatasourceDrift implements ProjectDatasource {
  ProjectDatasourceDrift(this._db);
  final AppDatabase _db;

  @override
  Stream<List<WorkspaceProjectRow>> watchAllProjectRows() =>
      _db.projectDao.watchAllProjects();

  @override
  Future<List<WorkspaceProjectRow>> getAllProjectRows() =>
      _db.projectDao.getAllProjects();

  @override
  Future<WorkspaceProjectRow?> getProjectRow(String id) =>
      _db.projectDao.getProject(id);

  @override
  Future<WorkspaceProjectRow?> getProjectRowByPath(String path) =>
      _db.projectDao.getProjectByPath(path);

  @override
  Future<void> upsertProjectRow(WorkspaceProjectsCompanion row) =>
      _db.projectDao.upsertProject(row);

  @override
  Future<void> updateProjectRow(String id, WorkspaceProjectsCompanion companion) =>
      _db.projectDao.updateProject(id, companion);

  @override
  Future<void> deleteProjectRow(String id) => _db.projectDao.deleteProject(id);

  @override
  Future<void> deleteAllProjectRows() => _db.projectDao.deleteAllProjects();
}
```

- [ ] **Step 3: Create `lib/data/project/datasource/project_fs_datasource.dart`**

```dart
abstract interface class ProjectFsDatasource {
  bool exists(String path);
  Future<void> createDirectory(String path);
}
```

- [ ] **Step 4: Create `lib/data/project/datasource/project_fs_datasource_io.dart`**

```dart
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'project_fs_datasource.dart';

part 'project_fs_datasource_io.g.dart';

@Riverpod(keepAlive: true)
ProjectFsDatasource projectFsDatasource(Ref ref) => ProjectFsDatasourceIo();

class ProjectFsDatasourceIo implements ProjectFsDatasource {
  @override
  bool exists(String path) => Directory(path).existsSync();

  @override
  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }
}
```

- [ ] **Step 5: Create `lib/data/project/datasource/git_detector_datasource.dart`**

```dart
abstract interface class GitDetectorDatasource {
  bool isGitRepo(String directoryPath);
  String? getCurrentBranch(String directoryPath);
}
```

- [ ] **Step 6: Create `lib/data/project/datasource/git_detector_datasource_io.dart`**

```dart
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/debug_logger.dart';
import 'git_detector_datasource.dart';

part 'git_detector_datasource_io.g.dart';

@Riverpod(keepAlive: true)
GitDetectorDatasource gitDetectorDatasource(Ref ref) => GitDetectorDatasourceIo();

/// Full implementation ported verbatim from GitDetector.
/// Static methods become instance methods.
class GitDetectorDatasourceIo implements GitDetectorDatasource {
  @override
  bool isGitRepo(String directoryPath) {
    // Copy GitDetector.isGitRepo() body here.
    // Call _isValidWorktreeGitFile() as a private instance method.
  }

  bool _isValidWorktreeGitFile(String gitFilePath, {required String projectPath}) {
    // Copy GitDetector._isValidWorktreeGitFile() body here.
  }

  @override
  String? getCurrentBranch(String directoryPath) {
    // Copy GitDetector.getCurrentBranch() body here.
  }
}
```

Also update `lib/data/git/datasource/git_live_state_datasource_process.dart` to use `GitDetectorDatasourceIo` instead of the inline `isGitRepo` check added in Task 4.

- [ ] **Step 7: Create `lib/data/project/datasource/project_file_scan_datasource.dart`**

```dart
abstract interface class ProjectFileScanDatasource {
  Future<List<String>> scanCodeFiles(String rootPath);
}
```

- [ ] **Step 8: Create `lib/data/project/datasource/project_file_scan_datasource_io.dart`**

```dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/debug_logger.dart';
import 'project_file_scan_datasource.dart';

part 'project_file_scan_datasource_io.g.dart';

// Copy kMaxScanFiles, kCodeExtensions, kSkipDirs constants here.
const int kMaxScanFiles = 2000;
const Set<String> kCodeExtensions = { /* copy from project_file_scan_service.dart */ };
const Set<String> kSkipDirs = { /* copy from project_file_scan_service.dart */ };

@Riverpod(keepAlive: true)
ProjectFileScanDatasource projectFileScanDatasource(Ref ref) =>
    ProjectFileScanDatasourceIo();

/// Implementation identical to ProjectFileScanService — copy scanCodeFiles()
/// and _walk() verbatim.
class ProjectFileScanDatasourceIo implements ProjectFileScanDatasource {
  @override
  Future<List<String>> scanCodeFiles(String rootPath) async {
    final out = <String>[];
    await _walk(Directory(rootPath), rootPath, out);
    return out;
  }

  Future<void> _walk(Directory dir, String rootPath, List<String> out) async {
    // Copy from ProjectFileScanService._walk() verbatim.
  }
}
```

- [ ] **Step 9: Create `lib/data/project/repository/project_repository.dart`**

```dart
import '../../../data/models/project.dart';
import '../../../data/models/project_action.dart';

abstract interface class ProjectRepository {
  Stream<List<Project>> watchAllProjects();
  Future<Project> addExistingFolder(String directoryPath);
  Future<Project> createNewFolder(String parentPath, String folderName);
  Future<void> removeProject(String projectId);
  Future<void> updateProjectActions(String projectId, List<ProjectAction> actions);
  Future<void> refreshProjectStatuses();
  Future<void> refreshProjectStatus(String projectId);
  Future<void> relocateProject(String projectId, String newPath);
  Future<void> deleteAllProjects();
}
```

- [ ] **Step 10: Create `lib/data/project/repository/project_repository_impl.dart`**

```dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/app_database.dart';
import '../../../data/models/project.dart';
import '../../../data/models/project_action.dart';
import '../datasource/project_datasource.dart';
import '../datasource/project_datasource_drift.dart';
import '../datasource/project_fs_datasource.dart';
import '../datasource/project_fs_datasource_io.dart';
import 'project_repository.dart';

part 'project_repository_impl.g.dart';

/// Thrown when attempting to add a project whose folder path is already tracked.
class DuplicateProjectPathException implements Exception {
  DuplicateProjectPathException(this.path);
  final String path;
  @override String toString() => 'A project at "$path" already exists in Code Bench.';
}

@Riverpod(keepAlive: true)
ProjectRepository projectRepository(Ref ref) {
  return ProjectRepositoryImpl(
    db: ref.watch(projectDatasourceProvider),
    fs: ref.watch(projectFsDatasourceProvider),
  );
}

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl({
    required ProjectDatasource db,
    required ProjectFsDatasource fs,
  })  : _db = db,
        _fs = fs;

  final ProjectDatasource _db;
  final ProjectFsDatasource _fs;
  static const _uuid = Uuid();

  @override
  Stream<List<Project>> watchAllProjects() {
    return _db.watchAllProjectRows().map(
      (rows) => rows.map((r) => _toDomain(r)).toList(),
    );
  }

  /// Row → domain mapping with ProjectStatus disk probe.
  /// Moved from ProjectService._projectFromRow().
  Project _toDomain(WorkspaceProjectRow row) {
    List<ProjectAction> actions = const [];
    try {
      final decoded = jsonDecode(row.actionsJson) as List<dynamic>;
      actions = decoded
          .map((e) => ProjectAction.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      sLog('[ProjectRepositoryImpl] actionsJson FormatException for ${row.id}: $e');
    } on TypeError catch (e) {
      sLog('[ProjectRepositoryImpl] actionsJson TypeError for ${row.id}: $e');
    }

    final status = _fs.exists(row.path)
        ? ProjectStatus.available
        : ProjectStatus.missing;

    return Project(
      id: row.id,
      name: row.name,
      path: row.path,
      createdAt: row.createdAt,
      sortOrder: row.sortOrder,
      actions: actions,
      status: status,
    );
  }

  @override
  Future<Project> addExistingFolder(String directoryPath) async {
    if (!_fs.exists(directoryPath)) {
      throw ArgumentError('Directory does not exist: $directoryPath');
    }
    final existing = await _db.getProjectRowByPath(directoryPath);
    if (existing != null) throw DuplicateProjectPathException(directoryPath);

    final id = _uuid.v4();
    final uri = Uri.directory(directoryPath);
    final name = uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => directoryPath);

    await _db.upsertProjectRow(
      WorkspaceProjectsCompanion(
        id: Value(id), name: Value(name), path: Value(directoryPath),
        createdAt: Value(DateTime.now()), sortOrder: const Value(0),
      ),
    );
    return Project(id: id, name: name, path: directoryPath, createdAt: DateTime.now());
  }

  @override
  Future<Project> createNewFolder(String parentPath, String folderName) async {
    final fullPath = '$parentPath/$folderName';
    if (!_fs.exists(fullPath)) await _fs.createDirectory(fullPath);
    return addExistingFolder(fullPath);
  }

  @override
  Future<void> removeProject(String projectId) => _db.deleteProjectRow(projectId);

  @override
  Future<void> updateProjectActions(String projectId, List<ProjectAction> actions) async {
    final json = jsonEncode(actions.map((a) => a.toJson()).toList());
    await _db.updateProjectRow(projectId, WorkspaceProjectsCompanion(actionsJson: Value(json)));
  }

  @override
  Future<void> refreshProjectStatuses() async {
    final rows = await _db.getAllProjectRows();
    for (final r in rows) {
      await _db.updateProjectRow(r.id, WorkspaceProjectsCompanion(sortOrder: Value(r.sortOrder)));
    }
  }

  @override
  Future<void> refreshProjectStatus(String projectId) async {
    final row = await _db.getProjectRow(projectId);
    if (row == null) return;
    await _db.updateProjectRow(projectId, WorkspaceProjectsCompanion(sortOrder: Value(row.sortOrder)));
  }

  @override
  Future<void> relocateProject(String projectId, String newPath) async {
    if (!_fs.exists(newPath)) throw ArgumentError('Directory does not exist: $newPath');
    final existing = await _db.getProjectRowByPath(newPath);
    if (existing != null && existing.id != projectId) {
      throw DuplicateProjectPathException(newPath);
    }
    await _db.updateProjectRow(projectId, WorkspaceProjectsCompanion(path: Value(newPath)));
  }

  @override
  Future<void> deleteAllProjects() => _db.deleteAllProjectRows();
}
```

- [ ] **Step 11: Update consumers**

Replace in every file:

| Old | New |
|---|---|
| `import '...services/project/project_service.dart'` | `import '...data/project/repository/project_repository_impl.dart'` |
| `projectServiceProvider` | `projectRepositoryProvider` |
| `DuplicateProjectPathException` | import from `project_repository_impl.dart` |
| `import '...services/project/project_file_scan_service.dart'` | `import '...data/project/datasource/project_file_scan_datasource_io.dart'` |
| `projectFileScanServiceProvider` | `projectFileScanDatasourceProvider` |

Files to update:
- `lib/features/project_sidebar/notifiers/project_sidebar_notifier.dart` — `projectServiceProvider` → `projectRepositoryProvider`
- `lib/features/project_sidebar/notifiers/project_sidebar_actions.dart` — same; `DuplicateProjectPathException` import
- `lib/features/settings/notifiers/settings_actions.dart` — `projectServiceProvider` → `projectRepositoryProvider`
- `lib/features/chat/notifiers/project_file_scan_actions.dart` — `projectFileScanServiceProvider` → `projectFileScanDatasourceProvider`

- [ ] **Step 12: Delete `lib/services/project/`**

```bash
rm -rf lib/services/project/
```

- [ ] **Step 13: Regenerate + verify + commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format lib/ test/
git add lib/data/project/ lib/features/ lib/services/
git add -u
git commit -m "$(cat <<'EOF'
refactor(project): introduce ProjectDatasource + ProjectRepository

Moves row→domain mapping and ProjectStatus disk probe into
ProjectRepositoryImpl. Splits ProjectService into four typed datasources.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Session + Filesystem + IDE + Settings repositories

**Files:**
- Create: `lib/data/session/datasource/session_datasource.dart`
- Create: `lib/data/session/datasource/session_datasource_drift.dart`
- Create: `lib/data/session/repository/session_repository.dart`
- Create: `lib/data/session/repository/session_repository_impl.dart`
- Create: `lib/data/filesystem/datasource/filesystem_datasource.dart`
- Create: `lib/data/filesystem/datasource/filesystem_datasource_io.dart`
- Create: `lib/data/filesystem/repository/filesystem_repository.dart`
- Create: `lib/data/filesystem/repository/filesystem_repository_impl.dart`
- Create: `lib/data/ide/datasource/ide_launch_datasource.dart`
- Create: `lib/data/ide/datasource/ide_launch_datasource_process.dart`
- Create: `lib/data/ide/repository/ide_launch_repository.dart`
- Create: `lib/data/ide/repository/ide_launch_repository_impl.dart`
- Create: `lib/data/settings/repository/settings_repository.dart`
- Create: `lib/data/settings/repository/settings_repository_impl.dart`
- Modify: many notifiers (see below)
- Delete: `lib/services/session/`, `lib/services/filesystem/`, `lib/services/ide/`, `lib/services/settings/`

- [ ] **Step 1: Create `lib/data/session/datasource/session_datasource.dart`**

```dart
import '../../../data/_core/app_database.dart';
import '../../../data/models/chat_message.dart' as msg;
import '../../../data/models/chat_session.dart';

abstract interface class SessionDatasource {
  Stream<List<ChatSession>> watchAllSessions();
  Stream<List<ChatSession>> watchSessionsByProject(String projectId);
  Stream<List<ChatSession>> watchArchivedSessions();
  Future<ChatSession?> getSession(String sessionId);
  Future<String> createSession({
    required String modelId,
    required String providerId,
    String? title,
    String? projectId,
  });
  Future<void> updateSessionTitle(String sessionId, String title);
  Future<void> deleteSession(String sessionId);
  Future<void> archiveSession(String sessionId);
  Future<void> unarchiveSession(String sessionId);
  Future<void> deleteAllSessionsAndMessages();
  Future<List<msg.ChatMessage>> loadHistory(String sessionId, {int limit, int offset});
  Future<void> persistMessage(String sessionId, msg.ChatMessage message);
}
```

- [ ] **Step 2: Create `lib/data/session/datasource/session_datasource_drift.dart`**

```dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/_core/app_database.dart';
import '../../../data/models/chat_message.dart' as msg;
import '../../../data/models/chat_session.dart';
import 'session_datasource.dart';

part 'session_datasource_drift.g.dart';

@Riverpod(keepAlive: true)
SessionDatasource sessionDatasource(Ref ref) =>
    SessionDatasourceDrift(ref.watch(appDatabaseProvider));

/// All method bodies ported verbatim from SessionService.
/// Row→domain mapping helpers (_sessionFromRow, _messageFromRow) move here.
class SessionDatasourceDrift implements SessionDatasource {
  SessionDatasourceDrift(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Stream<List<ChatSession>> watchAllSessions() =>
      _db.sessionDao.watchAllSessions().map((rows) => rows.map(_sessionFromRow).toList());

  // ... (port all methods from SessionService, adapting the DB row→domain helpers)
  // _sessionFromRow and _messageFromRow moved from SessionService to here.
}
```

Port all methods (`watchSessionsByProject`, `watchArchivedSessions`, `getSession`, `createSession`, `updateSessionTitle`, `deleteSession`, `archiveSession`, `unarchiveSession`, `deleteAllSessionsAndMessages`, `loadHistory`, `persistMessage`) from `SessionService`, plus the private `_sessionFromRow` and `_messageFromRow` helpers.

- [ ] **Step 3: Create `lib/data/session/repository/session_repository.dart`**

```dart
import '../../../data/models/ai_model.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/chat_session.dart';

abstract interface class SessionRepository {
  // Pure CRUD (delegates to datasource):
  Stream<List<ChatSession>> watchAllSessions();
  Stream<List<ChatSession>> watchSessionsByProject(String projectId);
  Stream<List<ChatSession>> watchArchivedSessions();
  Future<ChatSession?> getSession(String sessionId);
  Future<String> createSession({required AIModel model, String? title, String? projectId});
  Future<void> updateSessionTitle(String sessionId, String title);
  Future<void> deleteSession(String sessionId);
  Future<void> archiveSession(String sessionId);
  Future<void> unarchiveSession(String sessionId);
  Future<void> deleteAllSessionsAndMessages();
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit, int offset});
  Future<void> persistMessage(String sessionId, ChatMessage message);
  // AI streaming use-case (orchestrates SessionDatasource + AIRepository):
  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
  });
}
```

- [ ] **Step 4: Create `lib/data/session/repository/session_repository_impl.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/ai/repository/ai_repository.dart';
import '../../../data/ai/repository/ai_repository_impl.dart';
import '../../../data/models/ai_model.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/chat_session.dart';
import '../datasource/session_datasource.dart';
import '../datasource/session_datasource_drift.dart';
import 'session_repository.dart';

part 'session_repository_impl.g.dart';

@Riverpod(keepAlive: true)
Future<SessionRepository> sessionRepository(Ref ref) async {
  final ai = await ref.watch(aiRepositoryProvider.future);
  return SessionRepositoryImpl(
    datasource: ref.watch(sessionDatasourceProvider),
    ai: ai,
  );
}

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({
    required SessionDatasource datasource,
    required AIRepository ai,
  })  : _ds = datasource,
        _ai = ai;

  final SessionDatasource _ds;
  final AIRepository _ai;

  // Pure CRUD — delegate to datasource:
  @override Stream<List<ChatSession>> watchAllSessions() => _ds.watchAllSessions();
  @override Stream<List<ChatSession>> watchSessionsByProject(String p) => _ds.watchSessionsByProject(p);
  @override Stream<List<ChatSession>> watchArchivedSessions() => _ds.watchArchivedSessions();
  @override Future<ChatSession?> getSession(String id) => _ds.getSession(id);
  @override Future<String> createSession({required AIModel model, String? title, String? projectId}) =>
      _ds.createSession(modelId: model.modelId, providerId: model.provider.name, title: title, projectId: projectId);
  @override Future<void> updateSessionTitle(String id, String title) => _ds.updateSessionTitle(id, title);
  @override Future<void> deleteSession(String id) => _ds.deleteSession(id);
  @override Future<void> archiveSession(String id) => _ds.archiveSession(id);
  @override Future<void> unarchiveSession(String id) => _ds.unarchiveSession(id);
  @override Future<void> deleteAllSessionsAndMessages() => _ds.deleteAllSessionsAndMessages();
  @override Future<List<ChatMessage>> loadHistory(String id, {int limit = 50, int offset = 0}) =>
      _ds.loadHistory(id, limit: limit, offset: offset);
  @override Future<void> persistMessage(String id, ChatMessage msg) => _ds.persistMessage(id, msg);

  /// AI streaming — orchestrates datasource + AIRepository.
  /// Logic ported from SessionService.sendAndStream().
  @override
  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    // Copy sendAndStream() body from SessionService verbatim,
    // replacing:
    //   _ref.read(aiServiceProvider(...).future) → _ai.streamMessage(...)
    //   service.streamMessage(...) → _ai.streamMessage(...)
    //   service.loadHistory / persistMessage / updateSessionTitle → _ds.*
    // The streaming logic (buffer, yield, activeMessageIdNotifier) stays identical.
    // Note: activeMessageIdNotifier is a Riverpod notifier that cannot be
    // injected here. Callers (ChatMessagesNotifier) must manage that state
    // themselves, as they did previously.
    throw UnimplementedError('copy from SessionService.sendAndStream()');
  }
}
```

**Important**: The `sendAndStream` body in `SessionService` references `activeMessageIdNotifier` via `_ref`. Since `SessionRepositoryImpl` has no `Ref`, the caller (`ChatMessagesNotifier`) must manage `activeMessageIdProvider` itself. This is already done in `ChatMessagesNotifier.sendMessage()` — it sets `activeMessageIdNotifier` around the stream loop. The repository's `sendAndStream` just yields `ChatMessage` objects; the notifier handles the ID tracking.

Port `sendAndStream` without the `activeMessageIdNotifier` lines; the notifier already handles that.

- [ ] **Step 5: Create `lib/data/filesystem/datasource/filesystem_datasource.dart`**

```dart
abstract interface class FilesystemDatasource {
  Future<String> readFile(String filePath);
  Future<void> writeFile(String filePath, String content);
  Future<void> createFile(String filePath);
  Future<void> createDirectory(String dirPath);
  Future<void> deleteFile(String filePath);
  Future<void> renameFile(String oldPath, String newPath);
  Stream<dynamic> watchDirectory(String dirPath); // FileSystemEvent
  String detectLanguage(String filePath);
}
```

- [ ] **Step 6: Create `lib/data/filesystem/datasource/filesystem_datasource_io.dart`**

```dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart' as app_errors;
import 'filesystem_datasource.dart';

part 'filesystem_datasource_io.g.dart';

@Riverpod(keepAlive: true)
FilesystemDatasource filesystemDatasource(Ref ref) => FilesystemDatasourceIo();

/// Implementation identical to FilesystemService — copy all methods verbatim.
class FilesystemDatasourceIo implements FilesystemDatasource {
  // Copy all methods from FilesystemService:
  // listDirectory, readFile, writeFile, createFile, createDirectory,
  // deleteFile, renameFile, watchDirectory, detectLanguage
}
```

Note: `listDirectory` (which returns `FileNode` objects) belongs in the repository layer since `FileNode` is a domain concept. The datasource just does raw I/O. Move `listDirectory` logic to `FilesystemRepositoryImpl`, or keep `FileNode` in the datasource if it's purely structural. Since `FileNode` has no business logic, keep it in the datasource file.

- [ ] **Step 7: Create `lib/data/filesystem/repository/filesystem_repository.dart`**

```dart
import 'dart:io' show FileSystemEvent;
import '../../../services/filesystem/filesystem_service.dart' show FileNode;

// Re-export FileNode so callers don't change their imports.
export '../../../services/filesystem/filesystem_service.dart' show FileNode;
// After deleting services/filesystem/, move FileNode definition here.

abstract interface class FilesystemRepository {
  Future<List<FileNode>> listDirectory(String dirPath);
  Future<String> readFile(String filePath);
  Future<void> writeFile(String filePath, String content);
  Future<void> createFile(String filePath);
  Future<void> createDirectory(String dirPath);
  Future<void> deleteFile(String filePath);
  Future<void> renameFile(String oldPath, String newPath);
  Stream<FileSystemEvent> watchDirectory(String dirPath);
  String detectLanguage(String filePath);
}
```

Move `FileNode` class definition from `filesystem_service.dart` to `filesystem_repository.dart` (or a dedicated `file_node.dart` in `lib/data/filesystem/`).

- [ ] **Step 8: Create `lib/data/filesystem/repository/filesystem_repository_impl.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/filesystem_datasource.dart';
import '../datasource/filesystem_datasource_io.dart';
import 'filesystem_repository.dart';

part 'filesystem_repository_impl.g.dart';

@Riverpod(keepAlive: true)
FilesystemRepository filesystemRepository(Ref ref) =>
    FilesystemRepositoryImpl(ref.watch(filesystemDatasourceProvider));

class FilesystemRepositoryImpl implements FilesystemRepository {
  FilesystemRepositoryImpl(this._ds);
  final FilesystemDatasource _ds;

  // Delegate everything to datasource:
  @override Future<List<FileNode>> listDirectory(String p) => _ds.listDirectory(p);
  @override Future<String> readFile(String p) => _ds.readFile(p);
  @override Future<void> writeFile(String p, String c) => _ds.writeFile(p, c);
  @override Future<void> createFile(String p) => _ds.createFile(p);
  @override Future<void> createDirectory(String p) => _ds.createDirectory(p);
  @override Future<void> deleteFile(String p) => _ds.deleteFile(p);
  @override Future<void> renameFile(String o, String n) => _ds.renameFile(o, n);
  @override Stream<dynamic> watchDirectory(String p) => _ds.watchDirectory(p);
  @override String detectLanguage(String p) => _ds.detectLanguage(p);
}
```

- [ ] **Step 9: Create IDE launch datasource + repository**

**`lib/data/ide/datasource/ide_launch_datasource.dart`** — abstract interface:
```dart
abstract interface class IdeLaunchDatasource {
  Future<String?> openVsCode(String path);
  Future<String?> openCursor(String path);
  Future<String?> openInFinder(String path);
  Future<String?> openInTerminal(String path, String terminalApp);
}
```

**`lib/data/ide/datasource/ide_launch_datasource_process.dart`** — copy method bodies from `IdeLaunchService`. Provider: `ideLaunchDatasourceProvider`. Remove the `_prefs` dependency — move `getTerminalApp()` call to the repository layer.

**`lib/data/ide/repository/ide_launch_repository.dart`** — abstract interface:
```dart
abstract interface class IdeLaunchRepository {
  Future<String?> openVsCode(String path);
  Future<String?> openCursor(String path);
  Future<String?> openInFinder(String path);
  Future<String?> openInTerminal(String path); // reads terminal app internally
}
```

**`lib/data/ide/repository/ide_launch_repository_impl.dart`**:
```dart
@Riverpod(keepAlive: true)
IdeLaunchRepository ideLaunchRepository(Ref ref) {
  return IdeLaunchRepositoryImpl(
    datasource: ref.watch(ideLaunchDatasourceProvider),
    prefs: ref.watch(generalPreferencesProvider),
  );
}

class IdeLaunchRepositoryImpl implements IdeLaunchRepository {
  // Delegate to datasource, resolve terminalApp from prefs.
  @override Future<String?> openInTerminal(String path) async {
    final app = await _prefs.getTerminalApp();
    return _ds.openInTerminal(path, app);
  }
  // ... other methods delegate directly to _ds
}
```

- [ ] **Step 10: Create Settings repository**

**`lib/data/settings/repository/settings_repository.dart`**:
```dart
abstract interface class SettingsRepository {
  // API keys:
  Future<String?> readApiKey(String provider);
  Future<void> writeApiKey(String provider, String key);
  Future<void> deleteApiKey(String provider);
  Future<String?> readOllamaUrl();
  Future<void> writeOllamaUrl(String url);
  Future<String?> readCustomEndpoint();
  Future<void> writeCustomEndpoint(String url);
  Future<String?> readCustomApiKey();
  Future<void> writeCustomApiKey(String key);
  Future<void> deleteAllSecureStorage();
  // General prefs:
  Future<bool> getAutoCommit();
  Future<void> setAutoCommit(bool value);
  Future<String> getTerminalApp();
  Future<void> setTerminalApp(String value);
  Future<bool> getDeleteConfirmation();
  Future<void> setDeleteConfirmation(bool value);
  // Onboarding:
  Future<void> markOnboardingCompleted();
  Future<void> resetOnboarding();
}
```

**`lib/data/settings/repository/settings_repository_impl.dart`**:
```dart
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => SettingsRepositoryImpl(ref);

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._ref);
  final Ref _ref;

  SecureStorage get _storage => _ref.read(secureStorageProvider);
  GeneralPreferences get _generalPrefs => _ref.read(generalPreferencesProvider);
  OnboardingPreferences get _onboardingPrefs => _ref.read(onboardingPreferencesProvider);

  // Delegate all methods — implementation body identical to SettingsService.
}
```

- [ ] **Step 11: Update consumers**

Replace across all notifiers:

| Old provider | New provider |
|---|---|
| `sessionServiceProvider` | `sessionRepositoryProvider` (note: it's now `Future<SessionRepository>`, use `.future`) |
| `filesystemServiceProvider` | `filesystemRepositoryProvider` |
| `ideLaunchServiceProvider` | `ideLaunchRepositoryProvider` |
| `settingsServiceProvider` | `settingsRepositoryProvider` |

Files to update:
- `lib/features/chat/notifiers/chat_notifier.dart` — `sessionServiceProvider` → `sessionRepositoryProvider`; `.sendAndStream(...)` call unchanged
- `lib/features/settings/notifiers/settings_actions.dart` — `settingsServiceProvider` → `settingsRepositoryProvider`; also `sessionServiceProvider`, `projectServiceProvider` (already updated)
- `lib/features/settings/notifiers/providers_notifier.dart` — `settingsServiceProvider` → `settingsRepositoryProvider`
- `lib/features/settings/notifiers/general_prefs_notifier.dart` — `settingsServiceProvider` → `settingsRepositoryProvider`
- `lib/features/settings/notifiers/archive_actions.dart` — `sessionServiceProvider` → `sessionRepositoryProvider`
- `lib/features/onboarding/notifiers/onboarding_notifier.dart` — `settingsServiceProvider` → `settingsRepositoryProvider`
- `lib/features/onboarding/notifiers/github_auth_notifier.dart` — already updated in Task 3
- `lib/shell/notifiers/ide_launch_actions.dart` — `ideLaunchServiceProvider` → `ideLaunchRepositoryProvider`
- Any other shell notifier referencing `sessionServiceProvider` or `filesystemServiceProvider`

In `chat_notifier.dart`, `ChatMessagesNotifier.sendMessage()`:
```dart
// Before:
final service = ref.read(sessionServiceProvider);
await for (final msg in service.sendAndStream(...)) { ... }

// After (sessionRepository is Future<SessionRepository>):
final repo = await ref.read(sessionRepositoryProvider.future);
await for (final msg in repo.sendAndStream(...)) { ... }

// For sync reads like loadHistory:
final repo = await ref.read(sessionRepositoryProvider.future);
```

- [ ] **Step 12: Delete old service folders**

```bash
rm -rf lib/services/session/ lib/services/filesystem/ lib/services/ide/ lib/services/settings/
```

- [ ] **Step 13: Regenerate + verify + commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format lib/ test/
git add lib/data/session/ lib/data/filesystem/ lib/data/ide/ lib/data/settings/
git add lib/features/ lib/shell/
git add -u
git commit -m "$(cat <<'EOF'
refactor(session,fs,ide,settings): introduce repositories for remaining features

SessionRepository absorbs sendAndStream orchestration (AI + persistence).
FilesystemRepository, IdeLaunchRepository, SettingsRepository created.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Apply use-case — replace dart:io with FilesystemRepository

**Files:**
- Modify: `lib/services/apply/apply_service.dart`

- [ ] **Step 1: Update `ApplyService` constructor and fields**

```dart
// Remove:
// import 'dart:io';
// import '../filesystem/filesystem_service.dart';

// Add:
import '../../data/filesystem/repository/filesystem_repository.dart';
import '../../data/filesystem/repository/filesystem_repository_impl.dart';

// Change provider:
@Riverpod(keepAlive: true)
ApplyService applyService(Ref ref) {
  return ApplyService(
    fs: ref.watch(filesystemRepositoryProvider),  // was filesystemServiceProvider
    notifier: ref.watch(appliedChangesProvider.notifier),
  );
}

// Change field type:
final FilesystemRepository _fs;  // was FilesystemService
```

- [ ] **Step 2: Update `applyChange()` — replace direct File I/O**

```dart
// Before:
//   try {
//     originalContent = await File(filePath).readAsString();
//   } on PathNotFoundException { originalContent = null; }

// After:
try {
  originalContent = await _fs.readFile(filePath);
} on app_errors.FileSystemException catch (e) {
  // FileSystemException wrapping PathNotFoundException → treat as new file
  if (e.originalError is PathNotFoundException) {
    originalContent = null;
  } else {
    rethrow;
  }
}
```

Note: `FilesystemDatasourceIo.readFile()` wraps `PathNotFoundException` in `FileSystemException`. The check on `e.originalError` lets us distinguish "file not found" from other FS errors, preserving the current behavior.

- [ ] **Step 3: Update `revertChange()` — keep `_processRunner` for git**

`revertChange()` uses `_processRunner` for `git checkout --`. This stays as-is: `ApplyService` retains the `ProcessRunner` typedef and `dart:io` import for this git operation. The `assertWithinProject` static method also retains `dart:io` for the physical symlink-resolution check.

**Architectural note**: `assertWithinProject` uses `Directory.resolveSymbolicLinksSync()` for security (path-traversal defence). This is an explicitly documented exception in `CLAUDE.md`. The arch test in Task 8 will whitelist `apply_service.dart` for `dart:io`.

- [ ] **Step 4: Update `readOriginalForDiff()` static method**

This method is static and called from `message_bubble.dart`. It cannot take a repository dependency through injection. Keep it as a static method calling `dart:io` directly:

```dart
// This method stays as-is — it is a documented exception in CLAUDE.md.
// The assertWithinProject() guard is the security control; the File I/O
// here is secondary. arch_test.dart whitelists apply_service.dart.
static Future<String?> readOriginalForDiff(String absolutePath, String projectPath) async {
  assertWithinProject(absolutePath, projectPath);
  try {
    return await File(absolutePath).readAsString();
  } on PathNotFoundException {
    return null;
  } on FileSystemException catch (e) {
    dLog('[ApplyService] readOriginalForDiff failed: ${e.message}');
    rethrow;
  }
}
```

- [ ] **Step 5: Update `readFileContent()` — use `_fs`**

```dart
Future<String?> readFileContent(String filePath, String projectPath) async {
  assertWithinProject(filePath, projectPath);
  try {
    return await _fs.readFile(filePath);
  } on app_errors.FileSystemException catch (e) {
    dLog('[ApplyService] readFileContent failed: $e');
    return null;
  }
}
```

- [ ] **Step 6: Update `isExternallyModified()` — keep as static dart:io**

This static method is called from various places. Keep it using `dart:io` under the same architectural exception.

- [ ] **Step 7: Verify + commit**

```bash
flutter analyze
dart format lib/ test/
git add lib/services/apply/
git commit -m "$(cat <<'EOF'
refactor(apply): replace FilesystemService with FilesystemRepository

Instance methods delegate to FilesystemRepository. Static security
guards (assertWithinProject, readOriginalForDiff, isExternallyModified)
retain dart:io per the documented CLAUDE.md exception.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Architectural test + final cleanup

**Files:**
- Create: `test/arch_test.dart`
- Run: `dart format`, `flutter analyze`, `flutter test`

- [ ] **Step 1: Create `test/arch_test.dart`**

```dart
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Architectural boundary rules', () {
    test('dart:io only in datasource _io/_process files and apply_service', () {
      final violations = _grep('dart:io', 'lib/')
          .where(
            (path) =>
                !path.endsWith('_io.dart') &&
                !path.endsWith('_process.dart') &&
                !path.contains('apply_service.dart'), // documented exception
          )
          .toList();
      expect(violations, isEmpty,
          reason: 'dart:io found outside permitted paths:\n${violations.join('\n')}');
    });

    test('package:dio only in datasource _dio files', () {
      final violations = _grep('package:dio', 'lib/')
          .where((path) => !path.endsWith('_dio.dart'))
          .toList();
      expect(violations, isEmpty,
          reason: 'package:dio found outside _dio datasource files:\n${violations.join('\n')}');
    });

    test('package:drift only in _drift files and _core/app_database', () {
      final violations = _grep('package:drift', 'lib/')
          .where(
            (path) =>
                !path.endsWith('_drift.dart') &&
                !path.contains('_core/app_database'),
          )
          .toList();
      expect(violations, isEmpty,
          reason: 'package:drift found outside permitted paths:\n${violations.join('\n')}');
    });

    test('widgets do not import services or datasources directly', () {
      final widgetFiles = _dartFiles('lib/')
          .where((p) => p.contains('/widgets/') || p.endsWith('_screen.dart'))
          .toList();
      final violations = <String>[];
      for (final file in widgetFiles) {
        final content = File(file).readAsStringSync();
        if (content.contains("import '") &&
            (content.contains('/services/') || content.contains('/datasource/'))) {
          // Allow the assertWithinProject exception:
          if (!content.contains('apply_service.dart')) {
            violations.add(file);
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'Widgets importing services/datasources directly:\n${violations.join('\n')}');
    });
  });
}

List<String> _grep(String pattern, String dir) {
  final result = Process.runSync('grep', ['-r', '-l', pattern, dir]);
  if (result.exitCode != 0) return [];
  return (result.stdout as String)
      .trim()
      .split('\n')
      .where((l) => l.isNotEmpty && l.endsWith('.dart'))
      .toList();
}

List<String> _dartFiles(String dir) {
  final result = Process.runSync('find', [dir, '-name', '*.dart', '-not', '-path', '*/.*']);
  if (result.exitCode != 0) return [];
  return (result.stdout as String)
      .trim()
      .split('\n')
      .where((l) => l.isNotEmpty)
      .toList();
}
```

- [ ] **Step 2: Run full suite**

```bash
dart format lib/ test/
flutter analyze
```

Expected: No issues.

```bash
flutter test
```

Expected: All tests pass including `test/arch_test.dart`.

If `arch_test.dart` finds violations, fix them before proceeding to the commit.

- [ ] **Step 3: Final commit**

```bash
git add test/arch_test.dart
git commit -m "$(cat <<'EOF'
test(arch): add architectural boundary test

Enforces dart:io/_process, package:dio/_dio, package:drift/_drift
placement rules. Whitelists apply_service.dart per CLAUDE.md exception.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review Against Spec

**Section 2 (Three-Layer Model):** All 8 features have datasource → repository → service. ✓

**Section 3 (Target Folder Tree):** Every listed file is addressed in a task. The `actions/` feature stub (action_runner_datasource) was omitted since no existing service maps to it — this is a gap left for a follow-up. ✓

**Section 4 (Naming Conventions):** `FooRepository` / `FooRepositoryImpl` / `FooBarDatasource` / `FooBarDatasourceDio` / `FooBarDatasourceDrift` / `FooBarDatasourceProcess` / `FooBarDatasourceIo` patterns all enforced. ✓

**Section 5 (Interface Contracts):** Datasource interfaces have no `sendMessage` (stream-only). Repository adds `sendMessage` buffering. `ProjectRepositoryImpl._toDomain()` owns row→domain + `ProjectStatus` probe. ✓

**Section 6 (Riverpod Wiring):** `aiRepositoryProvider` returns the interface type (`Future<AIRepository>`). Datasource and repository providers return interface types enabling test overrides. ✓

**Section 7 (Arch Boundary Rule):** `arch_test.dart` added in Task 8. `apply_service.dart` whitelisted. ✓

**Section 8 (Commit Sequence):** 8 tasks map 1:1 to spec commits. Each task ends with `flutter analyze` pass + git commit. ✓

**Deviations from spec:**
1. `aiRepositoryProvider` is `Future<AIRepository>` (async, reads SecureStorage directly) rather than the spec's family-provider approach. Reason: simpler compile path; invalidation-based refresh matches existing codebase pattern. The family-provider approach is a follow-up optimization.
2. `SessionRepository.sendAndStream()` is on the repository (not a separate use-case service) because it spans only session data + AI, both of which are constructor-injected dependencies. The spec's `services/` list omitting it supports this interpretation.
3. `apply_service.dart` retains `dart:io` for the static security guards — whitelisted in arch test per `CLAUDE.md`.
