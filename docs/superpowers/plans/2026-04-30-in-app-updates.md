# In-App Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add GitHub-release-based update checking that shows a sidebar chip when a newer version is found, and lets the user download + install the new `.app` with one click.

**Architecture:** `UpdateDatasource` (Dio, GitHub API) → `UpdateRepository` → `UpdateService` (version compare, ditto install) → `UpdateNotifier` (state machine) → `UpdateChip` + `UpdateDialog` + `UpdateSection`. The install flow downloads a `.zip`, extracts it with `ditto`, backs up the current `.app`, swaps in the new one via a detached shell script, and calls `exit(0)`.

**Tech Stack:** `package_info_plus` (current version), `dio` (download), `ditto` + `Process.start` (install), `shared_preferences` (last-checked timestamp), Riverpod code-gen, `freezed`.

---

## File Map

**Create:**
```
lib/core/constants/update_constants.dart
lib/data/update/models/update_info.dart
lib/data/update/models/update_state.dart
lib/data/update/update_exception.dart
lib/data/update/datasource/update_datasource.dart
lib/data/update/datasource/update_datasource_dio.dart
lib/data/update/update_repository.dart
lib/data/update/update_repository_impl.dart
lib/services/update/update_service.dart
lib/features/settings/notifiers/update_failure.dart
lib/features/settings/notifiers/update_notifier.dart
lib/features/project_sidebar/widgets/update_chip.dart
lib/features/project_sidebar/widgets/update_dialog.dart
lib/features/settings/widgets/update_section.dart
test/services/update/update_service_test.dart
```

**Modify:**
```
lib/core/constants/app_constants.dart     — add prefUpdateLastChecked key
lib/core/constants/app_icons.dart         — add AppIcons.update
lib/shell/widgets/app_lifecycle_observer.dart  — trigger checkForUpdates on launch
lib/features/general/general_screen.dart  — add UpdateSection below About
lib/features/project_sidebar/project_sidebar.dart — add UpdateChip above SidebarFooter
```

---

### Task 1: Constants and icon

**Files:**
- Create: `lib/core/constants/update_constants.dart`
- Modify: `lib/core/constants/app_constants.dart`
- Modify: `lib/core/constants/app_icons.dart`

- [ ] **Step 1: Create `update_constants.dart`**

```dart
// lib/core/constants/update_constants.dart
const kGithubOwner = 'mkappworks-dev';
const kGithubRepo = 'code-bench-app';
const kUpdateAssetName = 'CodeBench-macos.zip';
```

- [ ] **Step 2: Add SharedPreferences key to `app_constants.dart`**

In `lib/core/constants/app_constants.dart`, add inside the `AppConstants` class after the existing `pref*` keys:

```dart
  static const String prefUpdateLastChecked = 'update_last_checked';
```

- [ ] **Step 3: Add update icon to `app_icons.dart`**

In `lib/core/constants/app_icons.dart`, add at the bottom of the `AppIcons` class (before the closing `}`):

```dart
  // Updates
  static const IconData update = LucideIcons.arrowDownToLine;
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/update_constants.dart \
        lib/core/constants/app_constants.dart \
        lib/core/constants/app_icons.dart
git commit -m "feat(update): add update constants and icon"
```

---

### Task 2: Data models and exceptions

**Files:**
- Create: `lib/data/update/models/update_info.dart`
- Create: `lib/data/update/models/update_state.dart`
- Create: `lib/data/update/update_exception.dart`
- Create: `lib/features/settings/notifiers/update_failure.dart`

- [ ] **Step 1: Create `update_info.dart`**

```dart
// lib/data/update/models/update_info.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_info.freezed.dart';

@freezed
abstract class UpdateInfo with _$UpdateInfo {
  const factory UpdateInfo({
    required String version,
    required String releaseNotes,
    required String downloadUrl,
    required DateTime publishedAt,
  }) = _UpdateInfo;
}
```

- [ ] **Step 2: Create `update_state.dart`**

```dart
// lib/data/update/models/update_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../features/settings/notifiers/update_failure.dart';
import 'update_info.dart';

part 'update_state.freezed.dart';

@freezed
sealed class UpdateState with _$UpdateState {
  const factory UpdateState.idle()                        = UpdateStateIdle;
  const factory UpdateState.checking()                    = UpdateStateChecking;
  const factory UpdateState.available(UpdateInfo info)    = UpdateStateAvailable;
  const factory UpdateState.downloading(double progress)  = UpdateStateDownloading;
  const factory UpdateState.installing()                  = UpdateStateInstalling;
  const factory UpdateState.upToDate()                    = UpdateStateUpToDate;
  const factory UpdateState.error(UpdateFailure failure)  = UpdateStateError;
}
```

- [ ] **Step 3: Create `update_exception.dart`**

These are plain Dart classes — no code generation needed. They allow `UpdateService` and `UpdateDatasource` to throw typed errors that the notifier can catch without importing `dart:io` or `package:dio`.

```dart
// lib/data/update/update_exception.dart
sealed class UpdateException implements Exception {
  const UpdateException([this.message]);
  final String? message;
}

final class UpdateNetworkException extends UpdateException {
  const UpdateNetworkException([super.message]);
}

final class UpdateDownloadException extends UpdateException {
  const UpdateDownloadException([super.message]);
}

final class UpdateInstallException extends UpdateException {
  const UpdateInstallException([super.message]);
}
```

- [ ] **Step 4: Create `update_failure.dart`**

```dart
// lib/features/settings/notifiers/update_failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_failure.freezed.dart';

@freezed
sealed class UpdateFailure with _$UpdateFailure {
  const factory UpdateFailure.networkError([String? detail])    = UpdateNetworkError;
  const factory UpdateFailure.downloadFailed([String? detail])  = UpdateDownloadFailed;
  const factory UpdateFailure.installFailed([String? detail])   = UpdateInstallFailed;
  const factory UpdateFailure.unknown(Object error)             = UpdateUnknownError;
}
```

- [ ] **Step 5: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `update_info.freezed.dart`, `update_state.freezed.dart`, `update_failure.freezed.dart`. No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/data/update/models/ \
        lib/data/update/update_exception.dart \
        lib/features/settings/notifiers/update_failure.dart \
        lib/features/settings/notifiers/update_failure.freezed.dart
git commit -m "feat(update): add UpdateInfo, UpdateState, UpdateFailure models"
```

---

### Task 3: Datasource and repository

**Files:**
- Create: `lib/data/update/datasource/update_datasource.dart`
- Create: `lib/data/update/datasource/update_datasource_dio.dart`
- Create: `lib/data/update/update_repository.dart`
- Create: `lib/data/update/update_repository_impl.dart`

- [ ] **Step 1: Create `update_datasource.dart`**

```dart
// lib/data/update/datasource/update_datasource.dart
import '../models/update_info.dart';

abstract interface class UpdateDatasource {
  Future<UpdateInfo?> fetchLatestRelease();
  Future<String> downloadRelease({
    required String url,
    required String version,
    required void Function(int received, int total) onProgress,
  });
}
```

- [ ] **Step 2: Create `update_datasource_dio.dart`**

```dart
// lib/data/update/datasource/update_datasource_dio.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/update_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../_core/http/dio_factory.dart';
import '../models/update_info.dart';
import '../update_exception.dart';
import 'update_datasource.dart';

part 'update_datasource_dio.g.dart';

@Riverpod(keepAlive: true)
UpdateDatasource updateDatasource(Ref ref) => UpdateDatasourceDio();

class UpdateDatasourceDio implements UpdateDatasource {
  UpdateDatasourceDio()
      : _dio = DioFactory.create(
          baseUrl: '',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: const {'Accept': 'application/vnd.github+json'},
        );

  final Dio _dio;

  @override
  Future<UpdateInfo?> fetchLatestRelease() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$kGithubOwner/$kGithubRepo/releases/latest',
      );
      final data = response.data!;
      final tagName = (data['tag_name'] as String? ?? '');
      final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
      if (version.isEmpty) return null;
      final assets = (data['assets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final asset = assets.firstWhere(
        (a) => a['name'] == kUpdateAssetName,
        orElse: () => {},
      );
      final downloadUrl = asset['browser_download_url'] as String?;
      if (downloadUrl == null) return null;
      return UpdateInfo(
        version: version,
        releaseNotes: data['body'] as String? ?? '',
        downloadUrl: downloadUrl,
        publishedAt: DateTime.parse(data['published_at'] as String),
      );
    } on DioException catch (e, st) {
      dLog('[UpdateDatasource] fetchLatestRelease failed: $e\n$st');
      throw UpdateNetworkException(e.message);
    }
  }

  @override
  Future<String> downloadRelease({
    required String url,
    required String version,
    required void Function(int received, int total) onProgress,
  }) async {
    final savePath = '${Directory.systemTemp.path}/cb-update-$version.zip';
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );
      return savePath;
    } on DioException catch (e, st) {
      dLog('[UpdateDatasource] downloadRelease failed: $e\n$st');
      throw UpdateDownloadException(e.message);
    }
  }
}
```

- [ ] **Step 3: Create `update_repository.dart`**

```dart
// lib/data/update/update_repository.dart
import 'models/update_info.dart';

abstract interface class UpdateRepository {
  Future<UpdateInfo?> fetchLatestRelease();
  Future<String> downloadRelease({
    required String url,
    required String version,
    required void Function(int received, int total) onProgress,
  });
}
```

- [ ] **Step 4: Create `update_repository_impl.dart`**

```dart
// lib/data/update/update_repository_impl.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'datasource/update_datasource.dart';
import 'datasource/update_datasource_dio.dart';
import 'models/update_info.dart';
import 'update_repository.dart';

part 'update_repository_impl.g.dart';

@Riverpod(keepAlive: true)
UpdateRepository updateRepository(Ref ref) =>
    UpdateRepositoryImpl(datasource: ref.watch(updateDatasourceProvider));

class UpdateRepositoryImpl implements UpdateRepository {
  UpdateRepositoryImpl({required UpdateDatasource datasource}) : _ds = datasource;

  final UpdateDatasource _ds;

  @override
  Future<UpdateInfo?> fetchLatestRelease() => _ds.fetchLatestRelease();

  @override
  Future<String> downloadRelease({
    required String url,
    required String version,
    required void Function(int received, int total) onProgress,
  }) =>
      _ds.downloadRelease(url: url, version: version, onProgress: onProgress);
}
```

- [ ] **Step 5: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `update_datasource_dio.g.dart`, `update_repository_impl.g.dart`. No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/data/update/
git commit -m "feat(update): add UpdateDatasource and UpdateRepository"
```

---

### Task 4: UpdateService and tests

**Files:**
- Create: `lib/services/update/update_service.dart`
- Create: `test/services/update/update_service_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/services/update/update_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/services/update/update_service.dart';

void main() {
  group('UpdateService.isNewer', () {
    test('true when minor is higher', () {
      expect(UpdateService.isNewer('1.2.0', '1.1.0'), isTrue);
    });
    test('true when major is higher', () {
      expect(UpdateService.isNewer('2.0.0', '1.9.9'), isTrue);
    });
    test('true when patch is higher', () {
      expect(UpdateService.isNewer('1.1.1', '1.1.0'), isTrue);
    });
    test('false when equal', () {
      expect(UpdateService.isNewer('1.1.0', '1.1.0'), isFalse);
    });
    test('false when current is higher', () {
      expect(UpdateService.isNewer('1.1.0', '1.2.0'), isFalse);
    });
    test('false when version string has fewer than 3 segments', () {
      expect(UpdateService.isNewer('1.1', '1.0.0'), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/services/update/update_service_test.dart
```

Expected: `FAILED` — `update_service.dart` does not exist yet.

- [ ] **Step 3: Create `update_service.dart`**

```dart
// lib/services/update/update_service.dart
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/update/models/update_info.dart';
import '../../data/update/update_exception.dart';
import '../../data/update/update_repository.dart';
import '../../data/update/update_repository_impl.dart';

part 'update_service.g.dart';

@Riverpod(keepAlive: true)
UpdateService updateService(Ref ref) =>
    UpdateService(repository: ref.watch(updateRepositoryProvider));

class UpdateService {
  UpdateService({required UpdateRepository repository}) : _repo = repository;

  final UpdateRepository _repo;

  Future<UpdateInfo?> checkForUpdate() async {
    final info = await _repo.fetchLatestRelease();
    if (info == null) return null;
    final packageInfo = await PackageInfo.fromPlatform();
    return isNewer(info.version, packageInfo.version) ? info : null;
  }

  Future<String> downloadUpdate({
    required UpdateInfo info,
    required void Function(double progress) onProgress,
  }) =>
      _repo.downloadRelease(
        url: info.downloadUrl,
        version: info.version,
        onProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );

  Future<void> installUpdate(String zipPath) async {
    final extractDir = '${Directory.systemTemp.path}/cb-update-extracted';

    // Extract .zip — ditto preserves macOS xattrs and codesign metadata
    final extractResult = await Process.run('ditto', ['-x', '-k', zipPath, extractDir]);
    if (extractResult.exitCode != 0) {
      dLog('[UpdateService] ditto extract failed: ${extractResult.stderr}');
      throw UpdateInstallException('ditto extract failed: ${extractResult.stderr}');
    }

    // Resolve current .app path from executable: walk up 3 levels
    // e.g. /Applications/Code Bench.app/Contents/MacOS/code_bench_app → .app
    final appPath = p.dirname(p.dirname(p.dirname(Platform.resolvedExecutable)));

    // Find extracted .app directory
    final extracted = Directory(extractDir)
        .listSync()
        .whereType<Directory>()
        .firstWhere((d) => d.path.endsWith('.app'), orElse: () {
      throw const UpdateInstallException('No .app found in extracted zip');
    });

    // Write backup-first relaunch script:
    // mv current → .old, ditto new → current, open on success, restore on failure
    final scriptPath = '${Directory.systemTemp.path}/cb_relaunch.sh';
    final script = '''#!/bin/bash
sleep 1
mv "\$1" "\$1.old"
ditto "\$2" "\$1"
if [ \$? -eq 0 ]; then
  rm -rf "\$1.old"
  open "\$1"
else
  mv "\$1.old" "\$1"
fi
''';
    await File(scriptPath).writeAsString(script);
    await Process.run('chmod', ['+x', scriptPath]);
    await Process.start('/bin/bash', [scriptPath, appPath, extracted.path]);

    exit(0);
  }

  static bool isNewer(String latest, String current) {
    final l = latest.split('.').map(int.tryParse).whereType<int>().toList();
    final c = current.split('.').map(int.tryParse).whereType<int>().toList();
    if (l.length < 3 || c.length < 3) return false;
    for (var i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }
}
```

- [ ] **Step 4: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `update_service.g.dart`. No errors.

- [ ] **Step 5: Run tests to confirm they pass**

```bash
flutter test test/services/update/update_service_test.dart
```

Expected: 6 tests, all `PASSED`.

- [ ] **Step 6: Commit**

```bash
git add lib/services/update/ \
        test/services/update/
git commit -m "feat(update): add UpdateService with version compare and install"
```

---

### Task 5: UpdateNotifier

**Files:**
- Create: `lib/features/settings/notifiers/update_notifier.dart`

- [ ] **Step 1: Create `update_notifier.dart`**

```dart
// lib/features/settings/notifiers/update_notifier.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/update/models/update_info.dart';
import '../../../data/update/models/update_state.dart';
import '../../../data/update/update_exception.dart';
import '../../../services/update/update_service.dart';
import 'update_failure.dart';

part 'update_notifier.g.dart';

@Riverpod(keepAlive: true)
class UpdateNotifier extends _$UpdateNotifier {
  @override
  UpdateState build() => const UpdateState.idle();

  Future<void> checkForUpdates() async {
    // Guard: do not interrupt an in-progress download or install
    if (state is UpdateStateChecking ||
        state is UpdateStateDownloading ||
        state is UpdateStateInstalling) return;

    state = const UpdateState.checking();
    try {
      final info = await ref.read(updateServiceProvider).checkForUpdate();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.prefUpdateLastChecked,
        DateTime.now().toIso8601String(),
      );
      state = info != null ? UpdateState.available(info) : const UpdateState.upToDate();
    } on UpdateNetworkException catch (e, st) {
      dLog('[UpdateNotifier] checkForUpdates network error: $e\n$st');
      state = UpdateState.error(UpdateFailure.networkError(e.message));
    } catch (e, st) {
      dLog('[UpdateNotifier] checkForUpdates failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.unknown(e));
    }
  }

  Future<void> downloadAndInstall(UpdateInfo info) async {
    state = const UpdateState.downloading(0);
    try {
      final zipPath = await ref.read(updateServiceProvider).downloadUpdate(
        info: info,
        onProgress: (progress) => state = UpdateState.downloading(progress),
      );
      state = const UpdateState.installing();
      await ref.read(updateServiceProvider).installUpdate(zipPath);
      // exit(0) is called inside installUpdate — code below is unreachable on success
    } on UpdateDownloadException catch (e, st) {
      dLog('[UpdateNotifier] download failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.downloadFailed(e.message));
    } on UpdateInstallException catch (e, st) {
      dLog('[UpdateNotifier] install failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.installFailed(e.message));
    } catch (e, st) {
      dLog('[UpdateNotifier] downloadAndInstall failed: $e\n$st');
      state = UpdateState.error(UpdateFailure.unknown(e));
    }
  }

  void dismiss() => state = const UpdateState.idle();
}
```

- [ ] **Step 2: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `update_notifier.g.dart`. No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/notifiers/update_notifier.dart \
        lib/features/settings/notifiers/update_notifier.g.dart
git commit -m "feat(update): add UpdateNotifier state machine"
```

---

### Task 6: UpdateChip widget

**Files:**
- Create: `lib/features/project_sidebar/widgets/update_chip.dart`

- [ ] **Step 1: Create `update_chip.dart`**

```dart
// lib/features/project_sidebar/widgets/update_chip.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/update/models/update_state.dart';
import '../../settings/notifiers/update_notifier.dart';
import 'update_dialog.dart';

class UpdateChip extends ConsumerStatefulWidget {
  const UpdateChip({super.key});

  @override
  ConsumerState<UpdateChip> createState() => _UpdateChipState();
}

class _UpdateChipState extends ConsumerState<UpdateChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateNotifierProvider);
    final info = switch (updateState) {
      UpdateStateAvailable(:final info) => info,
      _ => null,
    };
    if (info == null) return const SizedBox.shrink();

    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => UpdateDialog.show(context, info),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: _hovered ? c.accentTintMid : c.accentTintLight,
              border: Border.all(color: c.accentBorderTeal),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(AppIcons.update, size: 12, color: c.accentLight),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'v${info.version} available',
                    style: TextStyle(
                      color: c.accentLight,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(AppIcons.chevronRight, size: 10, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/project_sidebar/widgets/update_chip.dart
git commit -m "feat(update): add UpdateChip sidebar widget"
```

---

### Task 7: UpdateDialog widget

**Files:**
- Create: `lib/features/project_sidebar/widgets/update_dialog.dart`

- [ ] **Step 1: Create `update_dialog.dart`**

```dart
// lib/features/project_sidebar/widgets/update_dialog.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/update_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/update/models/update_info.dart';
import '../../../data/update/models/update_state.dart';
import '../../settings/notifiers/update_failure.dart';
import '../../settings/notifiers/update_notifier.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  const UpdateDialog({super.key, required this.info});

  final UpdateInfo info;

  static Future<void> show(BuildContext context, UpdateInfo info) =>
      showDialog<void>(context: context, builder: (_) => UpdateDialog(info: info));

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadVersion());
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _currentVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateNotifierProvider);
    final busy = updateState is UpdateStateDownloading || updateState is UpdateStateInstalling;

    final title = switch (updateState) {
      UpdateStateDownloading() => 'Downloading…',
      UpdateStateInstalling() => 'Installing…',
      UpdateStateError() => 'Update Failed',
      _ => 'Update Available',
    };

    final subtitle = switch (updateState) {
      UpdateStateDownloading(:final progress) =>
        'Downloading… ${(progress * 100).round()}%',
      UpdateStateInstalling() => 'The app will restart shortly',
      UpdateStateError() => 'Something went wrong',
      _ => 'Code Bench ${widget.info.version} is ready',
    };

    return AppDialog(
      icon: AppIcons.update,
      iconType: AppDialogIconType.teal,
      title: title,
      subtitle: subtitle,
      maxWidth: 400,
      content: _DialogContent(
        info: widget.info,
        updateState: updateState,
        currentVersion: _currentVersion,
      ),
      actions: [
        AppDialogAction.cancel(
          onPressed: busy
              ? null
              : () {
                  ref.read(updateNotifierProvider.notifier).dismiss();
                  Navigator.of(context).pop();
                },
        ),
        AppDialogAction.primary(
          label: 'Download & Install',
          onPressed: switch (updateState) {
            UpdateStateAvailable() || UpdateStateError() => () => unawaited(
                  ref
                      .read(updateNotifierProvider.notifier)
                      .downloadAndInstall(widget.info),
                ),
            _ => null,
          },
        ),
      ],
    );
  }
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({
    required this.info,
    required this.updateState,
    required this.currentVersion,
  });

  final UpdateInfo info;
  final UpdateState updateState;
  final String currentVersion;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Version badge row
        Row(
          children: [
            _VersionBadge(label: currentVersion.isEmpty ? '…' : 'v$currentVersion', isNew: false),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(AppIcons.arrowRight, size: 12, color: c.textMuted),
            ),
            _VersionBadge(label: 'v${info.version}', isNew: true),
          ],
        ),
        const SizedBox(height: 12),
        // State-specific content
        switch (updateState) {
          UpdateStateDownloading(:final progress) => _ProgressBar(progress: progress),
          UpdateStateInstalling() => _InstallingRow(),
          UpdateStateError(:final failure) => _ErrorRow(failure: failure, info: info),
          _ => _ReleaseNotes(notes: info.releaseNotes),
        },
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.label, required this.isNew});
  final String label;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isNew ? c.accentTintLight : c.chipFill,
        border: Border.all(color: isNew ? c.accentBorderTeal : c.chipStroke),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isNew ? c.accentLight : c.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.faintBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        child: Text(
          notes.isEmpty ? 'No release notes.' : notes,
          style: TextStyle(color: c.textSecondary, fontSize: 11, height: 1.6),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Downloading update…', style: TextStyle(color: c.textMuted, fontSize: 10)),
            Text('${(progress * 100).round()}%', style: TextStyle(color: c.textMuted, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: c.chipFill,
            valueColor: AlwaysStoppedAnimation(c.accent),
          ),
        ),
      ],
    );
  }
}

class _InstallingRow extends StatelessWidget {
  const _InstallingRow();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: c.accent),
        ),
        const SizedBox(width: 10),
        Text('Replacing app bundle and relaunching…',
            style: TextStyle(color: c.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.failure, required this.info});
  final UpdateFailure failure;
  final UpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final message = switch (failure) {
      UpdateNetworkError() => 'Could not reach GitHub. Check your connection.',
      UpdateDownloadFailed() => 'Download failed. Check your connection and try again.',
      UpdateInstallFailed() => 'Install failed. Try downloading manually.',
      UpdateUnknownError() => 'Something went wrong. Try downloading manually.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(color: c.error, fontSize: 11)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            try {
              launchUrl(Uri.parse(
                'https://github.com/$kGithubOwner/$kGithubRepo/releases/latest',
              ));
            } catch (_) {}
          },
          child: Text(
            'Download manually →',
            style: TextStyle(
              color: c.accent,
              fontSize: 11,
              decoration: TextDecoration.underline,
              decorationColor: c.accent,
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/project_sidebar/widgets/update_dialog.dart
git commit -m "feat(update): add UpdateDialog with download progress and error handling"
```

---

### Task 8: UpdateSection widget

**Files:**
- Create: `lib/features/settings/widgets/update_section.dart`

- [ ] **Step 1: Create `update_section.dart`**

```dart
// lib/features/settings/widgets/update_section.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/update/models/update_state.dart';
import '../../general/widgets/settings_group.dart';
import '../notifiers/update_notifier.dart';
import 'section_label.dart';

class UpdateSection extends ConsumerStatefulWidget {
  const UpdateSection({super.key});

  @override
  ConsumerState<UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends ConsumerState<UpdateSection> {
  String _lastChecked = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadLastChecked());
  }

  Future<void> _loadLastChecked() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(AppConstants.prefUpdateLastChecked);
    if (!mounted || iso == null) return;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return;
    final now = DateTime.now();
    final label = DateUtils.isSameDay(dt, now)
        ? 'Today at ${DateFormat.jm().format(dt)}'
        : DateFormat.MMMd().format(dt);
    setState(() => _lastChecked = label);
  }

  @override
  Widget build(BuildContext context) {
    // Reload last-checked label whenever a check completes
    ref.listen(updateNotifierProvider, (prev, next) {
      if (prev is UpdateStateChecking && next is! UpdateStateChecking) {
        unawaited(_loadLastChecked());
      }
    });

    final updateState = ref.watch(updateNotifierProvider);
    final isChecking = updateState is UpdateStateChecking;
    final c = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Updates'),
        const SizedBox(height: 8),
        SettingsGroup(
          rows: [
            SettingsRow(
              label: 'Check for updates',
              description: _lastChecked.isEmpty ? 'Never checked' : 'Last checked $_lastChecked',
              trailing: _CheckButton(
                isChecking: isChecking,
                onTap: () => unawaited(
                  ref.read(updateNotifierProvider.notifier).checkForUpdates(),
                ),
              ),
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckButton extends StatefulWidget {
  const _CheckButton({required this.isChecking, required this.onTap});
  final bool isChecking;
  final VoidCallback onTap;

  @override
  State<_CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<_CheckButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      cursor: widget.isChecking ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isChecking ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered && !widget.isChecking ? c.chipStroke : c.chipFill,
            border: Border.all(color: c.chipStroke),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            widget.isChecking ? 'Checking…' : 'Check now',
            style: TextStyle(
              color: widget.isChecking ? c.textMuted : c.textPrimary,
              fontSize: ThemeConstants.uiFontSizeSmall,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/settings/widgets/update_section.dart
git commit -m "feat(update): add UpdateSection for Settings > General"
```

---

### Task 9: Wire everything up

**Files:**
- Modify: `lib/shell/widgets/app_lifecycle_observer.dart`
- Modify: `lib/features/general/general_screen.dart`
- Modify: `lib/features/project_sidebar/project_sidebar.dart`

- [ ] **Step 1: Add on-launch check to `app_lifecycle_observer.dart`**

Add the import at the top of the file:

```dart
import '../../features/settings/notifiers/update_notifier.dart';
```

In `_AppLifecycleObserverState.initState()`, add after `WidgetsBinding.instance.addObserver(this);`:

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateNotifierProvider.notifier).checkForUpdates();
    });
```

The full `initState` should look like:

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateNotifierProvider.notifier).checkForUpdates();
    });
  }
```

- [ ] **Step 2: Add `UpdateSection` to `general_screen.dart`**

Add the import at the top of `lib/features/general/general_screen.dart`:

```dart
import '../settings/widgets/update_section.dart';
```

In the `build` method, locate the `SectionLabel('About')` block. Add a new "Updates" section directly after the closing `]` of the About `SettingsGroup` and before the `if (kDebugMode)` block:

```dart
          Divider(height: 36, thickness: 1, color: c.borderColor),
          const UpdateSection(),
```

The `UpdateSection` widget includes its own `SectionLabel('Updates')` and `SizedBox(height: 8)` internally, so no additional wrapping is needed.

- [ ] **Step 3: Add `UpdateChip` to `project_sidebar.dart`**

Add the import at the top of `lib/features/project_sidebar/project_sidebar.dart`:

```dart
import 'widgets/update_chip.dart';
```

In the `build` method, locate the `Column` that contains `SidebarFooter`. Add `const UpdateChip()` just before `const SidebarFooter()`:

```dart
          const UpdateChip(),
          const SidebarFooter(),
```

The full bottom of the Column should look like:

```dart
          Expanded(
            child: projectsAsync.when(
              // ... existing code ...
            ),
          ),
          const UpdateChip(),
          const SidebarFooter(),
```

- [ ] **Step 4: Commit**

```bash
git add lib/shell/widgets/app_lifecycle_observer.dart \
        lib/features/general/general_screen.dart \
        lib/features/project_sidebar/project_sidebar.dart
git commit -m "feat(update): wire UpdateChip, UpdateSection, and on-launch check"
```

---

### Task 10: Final checks

- [ ] **Step 1: Format**

```bash
dart format lib/ test/
```

Expected: files reformatted, no errors.

- [ ] **Step 2: Analyze**

```bash
flutter analyze
```

Expected: `No issues found!` (or only pre-existing warnings unrelated to this feature).

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: all tests pass, including the 6 new `UpdateService.isNewer` tests.

- [ ] **Step 4: Commit format changes if any**

```bash
git add -u
git diff --cached --quiet || git commit -m "chore: dart format after in-app updates feature"
```

---

## Manual smoke test checklist

After running `flutter run -d macos`:

1. **Launch check** — open Console.app and confirm no crash; the chip should not appear if already on the latest version
2. **Settings > General** — scroll to bottom, confirm "Updates" section appears with "Never checked" (first run) or a timestamp
3. **"Check now" button** — tap it; label changes to "Checking…" briefly, then shows updated timestamp
4. **Simulate available update** — temporarily change `kGithubRepo` to a repo with a higher version tag; relaunch; chip should appear above Settings button
5. **Chip tap** — opens dialog with correct version badge and release notes
6. **"Later" button** — closes dialog; chip disappears (state resets to idle)
