import 'package:code_bench_app/data/ai/datasource/claude_cli_datasource_process.dart';
import 'package:code_bench_app/data/ai/models/auth_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseClaudeAuthOutput', () {
    test('exit 0 with loggedIn:true returns authenticated', () {
      final out = parseClaudeAuthOutput(0, '{"loggedIn":true,"email":"u@x.com"}');
      expect(out, const AuthStatus.authenticated());
    });

    test('exit 0 with loggedIn:false returns unauthenticated with claude auth login', () {
      final out = parseClaudeAuthOutput(0, '{"loggedIn":false}');
      expect(out, isA<AuthUnauthenticated>());
      expect((out as AuthUnauthenticated).signInCommand, 'claude auth login');
    });

    test('exit 0 with malformed JSON returns unknown', () {
      expect(parseClaudeAuthOutput(0, 'not json'), const AuthStatus.unknown());
    });

    test('exit 0 with JSON missing loggedIn returns unknown', () {
      expect(parseClaudeAuthOutput(0, '{"email":"u@x.com"}'), const AuthStatus.unknown());
    });

    test('non-zero exit with valid JSON honours the loggedIn field', () {
      // claude auth status --json exits 1 when not signed in but still emits
      // a structured body — the parser must trust the JSON over the exit code.
      final out = parseClaudeAuthOutput(1, '{"loggedIn":false,"authMethod":"none"}');
      expect(out, isA<AuthUnauthenticated>());
      expect((out as AuthUnauthenticated).signInCommand, 'claude auth login');
    });

    test('non-zero exit with malformed JSON returns unknown', () {
      expect(parseClaudeAuthOutput(1, 'unexpected error'), const AuthStatus.unknown());
    });
  });
}
