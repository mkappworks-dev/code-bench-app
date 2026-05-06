import 'package:code_bench_app/data/ai/datasource/codex_cli_datasource_process.dart';
import 'package:code_bench_app/data/ai/models/auth_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCodexAuthOutput', () {
    test('"Logged in using ChatGPT" returns authenticated', () {
      final out = parseCodexAuthOutput(0, 'Logged in using ChatGPT\n');
      expect(out, const AuthStatus.authenticated());
    });

    test('"Logged in using API key" returns authenticated', () {
      final out = parseCodexAuthOutput(0, 'Logged in using API key\n');
      expect(out, const AuthStatus.authenticated());
    });

    test('"Not logged in" with non-zero exit returns unauthenticated', () {
      // codex login status writes "Not logged in" to stderr and exits 1;
      // the parser trusts the content over the exit code.
      final out = parseCodexAuthOutput(1, 'Not logged in\n');
      expect(out, isA<AuthUnauthenticated>());
      expect((out as AuthUnauthenticated).signInCommand, 'codex login');
    });

    test('unrecognised output returns unknown', () {
      expect(parseCodexAuthOutput(0, 'something else\n'), const AuthStatus.unknown());
    });

    test('empty output returns unknown', () {
      expect(parseCodexAuthOutput(1, ''), const AuthStatus.unknown());
    });
  });
}
