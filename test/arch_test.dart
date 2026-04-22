import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architectural boundary rules', () {
    // ── dart:io import rule ──────────────────────────────────────────────────
    //
    // CLAUDE.md rule: dart:io is allowed only in `lib/data/**/datasource/` and
    // `lib/services/`. Everything else requires a documented exception below.
    //
    // Permitted locations:
    //   • Datasource files: *_io.dart, *_process.dart
    //   • All of lib/services/ — CLAUDE.md explicitly permits dart:io there
    //   • apply_repository.dart — the static assertWithinProject security guard
    //     uses dart:io Directory/symlink APIs; documented exception in CLAUDE.md
    //   • platform_utils.dart — read-only Platform detection, no I/O
    test('dart:io import only in permitted paths', () {
      final violations = _grepImport("dart:io", 'lib/')
          .where(
            (path) =>
                !path.endsWith('_io.dart') &&
                !path.endsWith('_process.dart') &&
                !path.contains('/services/') &&
                !path.contains('apply_repository.dart') &&
                !path.contains('platform_utils.dart'),
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

    // ── Widget → service/datasource/repository import rule ──────────────────
    //
    // Widgets and screens must not import from lib/services/, lib/data/**/datasource/,
    // or lib/data/**/repository/ directly. Documented exceptions:
    //   • apply_service.dart — ApplyRepository.assertWithinProject static security
    //     guard (imported via apply_service.dart's re-exports)
    test('widgets do not import services or datasources directly', () {
      final widgetFiles = _dartFiles(
        'lib/',
      ).where((p) => p.contains('/widgets/') || p.endsWith('_screen.dart') || p.endsWith('_page.dart')).toList();
      final violations = <String>[];
      for (final file in widgetFiles) {
        final content = File(file).readAsStringSync();
        final hasServiceImport = RegExp(r"import '.*/(services|datasource|repository)/").hasMatch(content);
        if (hasServiceImport) {
          // Allow documented exceptions
          if (!content.contains('apply_service.dart')) {
            violations.add(file);
          }
        }
      }
      expect(violations, isEmpty, reason: 'Widgets importing services/datasources directly:\n${violations.join('\n')}');
    });

    // ── Notifier → Repository direct access rule ────────────────────────────
    //
    // Notifiers must call services, not repositories directly.
    test('notifiers do not read repository providers directly', () {
      final notifierFiles = _dartFiles('lib/')
          .where((p) => p.contains('/notifiers/') && (p.endsWith('_actions.dart') || p.endsWith('_notifier.dart')))
          .toList();
      final violations = <String>[];
      for (final file in notifierFiles) {
        final content = File(file).readAsStringSync();
        final hasRepoRead =
            RegExp(r'ref\.read\(\w*[Rr]epository[Pp]rovider').hasMatch(content) ||
            RegExp(r'ref\.watch\(\w*[Rr]epository[Pp]rovider').hasMatch(content);
        if (hasRepoRead) {
          violations.add(file);
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Notifiers reading repository providers directly (use a service):\n'
            '${violations.join('\n')}',
      );
    });

    // ── Service → feature import rule ───────────────────────────────────────
    test('services do not import from lib/features/', () {
      final violations =
          (_grepImport("package:code_bench_app/features/", 'lib/services/')
                ..addAll(_grepImport("'../../../features/", 'lib/services/'))
                ..addAll(_grepImport("'../../features/", 'lib/services/')))
              .toList();
      expect(violations, isEmpty, reason: 'Services importing from lib/features/:\n${violations.join('\n')}');
    });

    // ── Data → service import rule ───────────────────────────────────────────
    //
    // Files in lib/data/ must not import from lib/services/.
    test('data layer does not import from lib/services/', () {
      final violations = _grepImport("package:code_bench_app/services/", 'lib/data/')
        ..addAll(_grepImport("'../../../services/", 'lib/data/'))
        ..addAll(_grepImport("'../../services/", 'lib/data/'));
      expect(violations, isEmpty, reason: 'Data layer importing from lib/services/:\n${violations.join('\n')}');
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
