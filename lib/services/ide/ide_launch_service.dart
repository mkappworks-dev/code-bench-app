import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/local/general_preferences.dart';

part 'ide_launch_service.g.dart';

@Riverpod(keepAlive: true)
IdeLaunchService ideLaunchService(Ref ref) => IdeLaunchService(ref.watch(generalPreferencesProvider));

class IdeLaunchService {
  IdeLaunchService(this._prefs);

  final GeneralPreferences _prefs;

  static const _vsCodeNotFoundMessage = "VS Code CLI not found — install it from the Command Palette "
      "(Shell Command: Install 'code' in PATH)";
  static const _cursorNotFoundMessage = "Cursor CLI not found — install it from the Command Palette "
      "(Shell Command: Install 'cursor' in PATH)";

  static List<String> buildVsCodeArgs(String path) => [path];
  static List<String> buildFinderArgs(String path) => [path];
  static List<String> buildTerminalArgs(String path, String terminalApp) => ['-a', terminalApp, path];

  /// Opens [path] in VS Code. Returns an error message if the CLI is not
  /// found, or null on success.
  Future<String?> openVsCode(String path) async {
    try {
      final result = await Process.run('code', buildVsCodeArgs(path));
      if (result.exitCode != 0) return _vsCodeNotFoundMessage;
      return null;
    } on ProcessException {
      return _vsCodeNotFoundMessage;
    }
  }

  /// Opens [path] in Cursor, falling back to `open -a Cursor` if the CLI is
  /// missing.
  Future<String?> openCursor(String path) async {
    try {
      final result = await Process.run('cursor', buildVsCodeArgs(path));
      if (result.exitCode == 0) return null;
    } on ProcessException {
      // CLI not found — try open -a Cursor fallback below.
    }
    try {
      final fallback = await Process.run('open', ['-a', 'Cursor', path]);
      if (fallback.exitCode != 0) return _cursorNotFoundMessage;
      return null;
    } on ProcessException {
      return _cursorNotFoundMessage;
    }
  }

  /// Opens [path] in Finder.
  Future<void> openInFinder(String path) async {
    await Process.run('open', buildFinderArgs(path));
  }

  /// Opens [path] in the configured terminal app.
  Future<void> openInTerminal(String path) async {
    final app = await _prefs.getTerminalApp();
    await Process.run('open', buildTerminalArgs(path, app));
  }
}
