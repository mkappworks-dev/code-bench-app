import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/settings/settings_service.dart';
import 'general_prefs_failure.dart';

export 'general_prefs_failure.dart';

part 'general_prefs_notifier.g.dart';

class GeneralPrefsNotifierState {
  const GeneralPrefsNotifierState({
    required this.autoCommit,
    required this.deleteConfirmation,
    required this.terminalApp,
    required this.themeMode,
  });

  final bool autoCommit;
  final bool deleteConfirmation;
  final String terminalApp;
  final ThemeMode themeMode;

  GeneralPrefsNotifierState copyWith({
    bool? autoCommit,
    bool? deleteConfirmation,
    String? terminalApp,
    ThemeMode? themeMode,
  }) => GeneralPrefsNotifierState(
    autoCommit: autoCommit ?? this.autoCommit,
    deleteConfirmation: deleteConfirmation ?? this.deleteConfirmation,
    terminalApp: terminalApp ?? this.terminalApp,
    themeMode: themeMode ?? this.themeMode,
  );
}

/// Loads general preferences on first watch and exposes setters.
/// Auto-disposes when the settings screen is not in view.
@riverpod
class GeneralPrefsNotifier extends _$GeneralPrefsNotifier {
  @override
  Future<GeneralPrefsNotifierState> build() async {
    final svc = ref.read(settingsServiceProvider);
    return GeneralPrefsNotifierState(
      autoCommit: await svc.getAutoCommit(),
      deleteConfirmation: await svc.getDeleteConfirmation(),
      terminalApp: await svc.getTerminalApp(),
      themeMode: await svc.getThemeMode(),
    );
  }

  GeneralPrefsFailure _asFailure(Object e) => switch (e) {
    StorageException() => const GeneralPrefsFailure.saveFailed(),
    _ => GeneralPrefsFailure.unknown(e),
  };

  Future<void> setAutoCommit(bool value) async {
    final next = await AsyncValue.guard(() async {
      try {
        await ref.read(settingsServiceProvider).setAutoCommit(value);
      } catch (e, st) {
        dLog('[GeneralPrefsNotifier] setAutoCommit failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
      return (state.value ?? await build()).copyWith(autoCommit: value);
    });
    if (ref.mounted) state = next;
  }

  Future<void> setDeleteConfirmation(bool value) async {
    final next = await AsyncValue.guard(() async {
      try {
        await ref.read(settingsServiceProvider).setDeleteConfirmation(value);
      } catch (e, st) {
        dLog('[GeneralPrefsNotifier] setDeleteConfirmation failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
      return (state.value ?? await build()).copyWith(deleteConfirmation: value);
    });
    if (ref.mounted) state = next;
  }

  Future<void> setTerminalApp(String value) async {
    final next = await AsyncValue.guard(() async {
      try {
        await ref.read(settingsServiceProvider).setTerminalApp(value);
      } catch (e, st) {
        dLog('[GeneralPrefsNotifier] setTerminalApp failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
      return (state.value ?? await build()).copyWith(terminalApp: value);
    });
    if (ref.mounted) state = next;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final next = await AsyncValue.guard(() async {
      try {
        await ref.read(settingsServiceProvider).setThemeMode(mode);
      } catch (e, st) {
        dLog('[GeneralPrefsNotifier] setThemeMode failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
      return (state.value ?? await build()).copyWith(themeMode: mode);
    });
    if (ref.mounted) state = next;
  }

  /// Resets all general settings to their defaults and invalidates this
  /// provider so the settings UI rebuilds with fresh values.
  Future<void> restoreDefaults() async {
    final next = await AsyncValue.guard(() async {
      try {
        final svc = ref.read(settingsServiceProvider);
        await svc.setAutoCommit(false);
        await svc.setTerminalApp('Terminal');
        await svc.setDeleteConfirmation(true);
      } catch (e, st) {
        dLog('[GeneralPrefsNotifier] restoreDefaults failed: $e');
        Error.throwWithStackTrace(_asFailure(e), st);
      }
      ref.invalidateSelf();
      return state.value ?? await build();
    });
    if (ref.mounted) state = next;
  }
}
