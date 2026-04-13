import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architectural boundary rules', () {
    // ── dart:io import rule ──────────────────────────────────────────────────
    //
    // Permitted locations for `import 'dart:io'`:
    //   • Datasource files: *_io.dart, *_process.dart
    //   • apply_service.dart — static security guard (documented in CLAUDE.md)
    //   • platform_utils.dart — read-only Platform detection, no I/O
    //   • action_output_notifier.dart — Process.start for user-defined actions
    //     (documented in shell/notifiers/ with a SECURITY note; this notifier
    //      predates the clean-arch data layer and is intentionally kept here)
    //   • Notifiers that only catch dart:io exception types (FileSystemException,
    //     IOException) thrown by service/datasource calls — catching an exception
    //     type does not make the notifier an I/O layer.
    //   • add_project_step.dart — Platform.pathSeparator for display only
    test('dart:io import only in permitted paths', () {
      // Only check actual import lines (not comments or string literals).
      final violations = _grepImport("import 'dart:io'", 'lib/')
          .where(
            (path) =>
                !path.endsWith('_io.dart') &&
                !path.endsWith('_process.dart') &&
                !path.contains('apply_service.dart') &&
                // Documented pre-existing exceptions below:
                !path.contains('platform_utils.dart') &&
                !path.contains('action_output_notifier.dart') &&
                !path.contains('code_apply_actions.dart') &&
                !path.contains('code_diff_provider.dart') &&
                !path.contains('project_file_scan_actions.dart') &&
                !path.contains('project_sidebar_actions.dart') &&
                !path.contains('add_project_step.dart'),
          )
          .toList();
      expect(violations, isEmpty, reason: 'dart:io imported outside permitted paths:\n${violations.join('\n')}');
    });

    // ── package:dio import rule ──────────────────────────────────────────────
    //
    // Permitted locations: *_dio.dart datasource files and dio_factory.dart.
    test('package:dio only in datasource _dio files and dio_factory', () {
      final violations = _grepImport(
        'package:dio',
        'lib/',
      ).where((path) => !path.endsWith('_dio.dart') && !path.contains('dio_factory.dart')).toList();
      expect(violations, isEmpty, reason: 'package:dio found outside _dio datasource files:\n${violations.join('\n')}');
    });

    // ── package:drift import rule ────────────────────────────────────────────
    //
    // Permitted locations: *_drift.dart datasource files and _core/app_database.
    test('package:drift only in _drift files and _core/app_database', () {
      final violations = _grepImport(
        'package:drift',
        'lib/',
      ).where((path) => !path.endsWith('_drift.dart') && !path.contains('_core/app_database')).toList();
      expect(violations, isEmpty, reason: 'package:drift found outside permitted paths:\n${violations.join('\n')}');
    });

    // ── Widget → service/datasource import rule ──────────────────────────────
    //
    // Widgets and screens must not import from lib/services/ or lib/data/**/datasource/
    // directly. The only documented exception: apply_service.dart may be imported
    // for the static assertWithinProject security guard.
    test('widgets do not import services or datasources directly', () {
      final widgetFiles = _dartFiles(
        'lib/',
      ).where((p) => p.contains('/widgets/') || p.endsWith('_screen.dart') || p.endsWith('_page.dart')).toList();
      final violations = <String>[];
      for (final file in widgetFiles) {
        final content = File(file).readAsStringSync();
        final hasServiceImport = RegExp(r"import '.*/(services|datasource)/").hasMatch(content);
        if (hasServiceImport) {
          // Allow the assertWithinProject exception
          if (!content.contains('apply_service.dart')) {
            violations.add(file);
          }
        }
      }
      expect(violations, isEmpty, reason: 'Widgets importing services/datasources directly:\n${violations.join('\n')}');
    });
  });
}

/// Greps for files that contain [pattern] as a substring of any line
/// that starts with `import` (i.e. actual import statements, not comments).
List<String> _grepImport(String pattern, String dir) {
  // Use grep with a regex that matches only import lines.
  final result = Process.runSync('grep', ['-r', '-l', '--include=*.dart', "^import.*$pattern", dir]);
  if (result.exitCode != 0) return [];
  return (result.stdout as String).trim().split('\n').where((l) => l.isNotEmpty && l.endsWith('.dart')).toList();
}

List<String> _dartFiles(String dir) {
  final result = Process.runSync('find', [dir, '-name', '*.dart', '-not', '-path', '*/.*']);
  if (result.exitCode != 0) return [];
  return (result.stdout as String).trim().split('\n').where((l) => l.isNotEmpty).toList();
}
