import 'package:code_bench_app/data/ai/models/auth_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exhaustive switch covers every variant', () {
    String label(AuthStatus s) => switch (s) {
      AuthAuthenticated() => 'authenticated',
      AuthUnauthenticated() => 'unauthenticated',
      AuthUnknown() => 'unknown',
    };

    expect(label(const AuthStatus.authenticated()), 'authenticated');
    expect(label(const AuthStatus.unauthenticated(signInCommand: 'foo login')), 'unauthenticated');
    expect(label(const AuthStatus.unknown()), 'unknown');
  });

  test('unauthenticated carries signInCommand and optional hint', () {
    const a = AuthStatus.unauthenticated(signInCommand: 'codex login');
    expect(a, isA<AuthUnauthenticated>());
    expect((a as AuthUnauthenticated).signInCommand, 'codex login');
    expect(a.hint, isNull);

    const b = AuthStatus.unauthenticated(signInCommand: 'claude auth login', hint: 'subscription required');
    expect((b as AuthUnauthenticated).hint, 'subscription required');
  });
}
