import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import 'ide_launch_datasource.dart';

part 'ide_launch_datasource_process.g.dart';

@Riverpod(keepAlive: true)
IdeLaunchDatasource ideLaunchDatasource(Ref ref) => IdeLaunchDatasourceProcess();

class IdeLaunchDatasourceProcess implements IdeLaunchDatasource {
  static const _vsCodeNotFoundMessage =
      "VS Code CLI not found — install it from the Command Palette "
      "(Shell Command: Install 'code' in PATH)";
  static const _cursorNotFoundMessage =
      "Cursor CLI not found — install it from the Command Palette "
      "(Shell Command: Install 'cursor' in PATH)";

  static List<String> buildVsCodeArgs(String path) => [path];
  static List<String> buildFinderArgs(String path) => ['--', path];
  static List<String> buildTerminalArgs(String path, String terminalApp) => ['-a', terminalApp, '--', path];

  @override
  Future<String?> openVsCode(String path) async {
    try {
      final result = await Process.run('code', buildVsCodeArgs(path));
      if (result.exitCode != 0) return _vsCodeNotFoundMessage;
      return null;
    } on ProcessException {
      return _vsCodeNotFoundMessage;
    }
  }

  @override
  Future<String?> openCursor(String path) async {
    try {
      final result = await Process.run('cursor', buildVsCodeArgs(path));
      if (result.exitCode == 0) return null;
    } on ProcessException {
      // CLI not found — try open -a Cursor fallback below.
    }
    try {
      final fallback = await Process.run('open', ['-a', 'Cursor', '--', path]);
      if (fallback.exitCode != 0) return _cursorNotFoundMessage;
      return null;
    } on ProcessException {
      return _cursorNotFoundMessage;
    }
  }

  @override
  Future<String?> openInFinder(String path) async {
    try {
      final result = await Process.run('open', buildFinderArgs(path));
      if (result.exitCode != 0) {
        return 'Could not open Finder for $path';
      }
      return null;
    } on ProcessException {
      return 'Could not open Finder — `open` command unavailable.';
    }
  }

  @override
  Future<String?> openInTerminal(String path, String terminalApp) async {
    // Defense-in-depth: reject a terminal app name that looks like a flag.
    if (terminalApp.startsWith('-')) {
      sLog('[openInTerminal] flag-shaped terminal app rejected: "$terminalApp"');
      return 'Invalid terminal app configured: $terminalApp';
    }
    try {
      final result = await Process.run('open', buildTerminalArgs(path, terminalApp));
      if (result.exitCode != 0) {
        return 'Could not open terminal app "$terminalApp" — check Settings → General.';
      }
      return null;
    } on ProcessException {
      return 'Could not open terminal — `open` command unavailable.';
    }
  }
}
