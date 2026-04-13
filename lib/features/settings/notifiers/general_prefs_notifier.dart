import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/settings/settings_service.dart';

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
    final svc = ref.read(settingsServiceProvider);
    return GeneralPrefsNotifierState(
      autoCommit: await svc.getAutoCommit(),
      deleteConfirmation: await svc.getDeleteConfirmation(),
      terminalApp: await svc.getTerminalApp(),
    );
  }

  Future<void> setAutoCommit(bool value) async {
    await ref.read(settingsServiceProvider).setAutoCommit(value);
    _update((s) => s.copyWith(autoCommit: value));
  }

  Future<void> setDeleteConfirmation(bool value) async {
    await ref.read(settingsServiceProvider).setDeleteConfirmation(value);
    _update((s) => s.copyWith(deleteConfirmation: value));
  }

  Future<void> setTerminalApp(String value) async {
    await ref.read(settingsServiceProvider).setTerminalApp(value);
    _update((s) => s.copyWith(terminalApp: value));
  }

  /// Resets all general settings to their defaults and invalidates this
  /// provider so the settings UI rebuilds with fresh values.
  Future<void> restoreDefaults() async {
    final svc = ref.read(settingsServiceProvider);
    await svc.setAutoCommit(false);
    await svc.setTerminalApp('Terminal');
    await svc.setDeleteConfirmation(true);
    ref.invalidateSelf();
  }

  void _update(GeneralPrefsNotifierState Function(GeneralPrefsNotifierState) fn) {
    final current = state.value;
    if (current != null) state = AsyncData(fn(current));
  }
}
