import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../../../data/settings/repository/settings_repository_impl.dart';

part 'general_prefs_notifier.g.dart';

class GeneralPrefsNotifierState {
  const GeneralPrefsNotifierState({
    required this.autoCommit,
    required this.deleteConfirmation,
    required this.terminalApp,
  });

  final bool autoCommit;
  final bool deleteConfirmation;
  final String terminalApp;

  GeneralPrefsNotifierState copyWith({bool? autoCommit, bool? deleteConfirmation, String? terminalApp}) =>
      GeneralPrefsNotifierState(
        autoCommit: autoCommit ?? this.autoCommit,
        deleteConfirmation: deleteConfirmation ?? this.deleteConfirmation,
        terminalApp: terminalApp ?? this.terminalApp,
      );
}

/// Loads general preferences on first watch and exposes setters.
/// Auto-disposes when the settings screen is not in view.
@riverpod
class GeneralPrefsNotifier extends _$GeneralPrefsNotifier {
  @override
  Future<GeneralPrefsNotifierState> build() async {
    final svc = ref.read(settingsRepositoryProvider);
    return GeneralPrefsNotifierState(
      autoCommit: await svc.getAutoCommit(),
      deleteConfirmation: await svc.getDeleteConfirmation(),
      terminalApp: await svc.getTerminalApp(),
    );
  }

  Future<void> setAutoCommit(bool value) async {
    try {
      await ref.read(settingsRepositoryProvider).setAutoCommit(value);
      _update((s) => s.copyWith(autoCommit: value));
    } catch (e, st) {
      dLog('[GeneralPrefsNotifier] setAutoCommit failed: $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> setDeleteConfirmation(bool value) async {
    try {
      await ref.read(settingsRepositoryProvider).setDeleteConfirmation(value);
      _update((s) => s.copyWith(deleteConfirmation: value));
    } catch (e, st) {
      dLog('[GeneralPrefsNotifier] setDeleteConfirmation failed: $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> setTerminalApp(String value) async {
    try {
      await ref.read(settingsRepositoryProvider).setTerminalApp(value);
      _update((s) => s.copyWith(terminalApp: value));
    } catch (e, st) {
      dLog('[GeneralPrefsNotifier] setTerminalApp failed: $e');
      state = AsyncError(e, st);
    }
  }

  /// Resets all general settings to their defaults and invalidates this
  /// provider so the settings UI rebuilds with fresh values.
  Future<void> restoreDefaults() async {
    try {
      final svc = ref.read(settingsRepositoryProvider);
      await svc.setAutoCommit(false);
      await svc.setTerminalApp('Terminal');
      await svc.setDeleteConfirmation(true);
      ref.invalidateSelf();
    } catch (e, st) {
      dLog('[GeneralPrefsNotifier] restoreDefaults failed: $e');
      state = AsyncError(e, st);
    }
  }

  void _update(GeneralPrefsNotifierState Function(GeneralPrefsNotifierState) fn) {
    final current = state.value;
    if (current != null) state = AsyncData(fn(current));
  }
}
