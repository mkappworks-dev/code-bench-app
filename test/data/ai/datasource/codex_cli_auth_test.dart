import 'package:code_bench_app/data/ai/datasource/codex_cli_datasource_process.dart';
import 'package:code_bench_app/data/ai/models/auth_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCodexAuthOutput', () {
    test('exit 0 with "Logged in using ChatGPT" returns authenticated', () {
      final out = parseCodexAuthOutput(0, 'Logged in using ChatGPT\n');
      expect(out, const AuthStatus.authenticated());
    });

    test('exit 0 with "Logged in using API key" returns authenticated', () {
      final out = parseCodexAuthOutput(0, 'Logged in using API key\n');
      expect(out, const AuthStatus.authenticated());
    });

    test('exit 0 with "Not logged in" returns unauthenticated with codex login', () {
      final out = parseCodexAuthOutput(0, 'Not logged in\n');
      expect(out, isA<AuthUnauthenticated>());
      expect((out as AuthUnauthenticated).signInCommand, 'codex login');
    });

    test('exit 0 with unrecognised stdout returns unknown', () {
      expect(parseCodexAuthOutput(0, 'something else\n'), const AuthStatus.unknown());
    });

    test('non-zero exit returns unknown', () {
      expect(parseCodexAuthOutput(1, ''), const AuthStatus.unknown());
    });
  });
}
