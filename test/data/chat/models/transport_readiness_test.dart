import 'package:code_bench_app/data/chat/models/transport_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exhaustive switch covers every variant', () {
    String label(TransportReadiness r) => switch (r) {
      TransportReady() => 'ready',
      TransportNotInstalled() => 'notInstalled',
      TransportSignedOut() => 'signedOut',
      TransportHttpKeyMissing() => 'httpKeyMissing',
      TransportUnknown() => 'unknown',
    };

    expect(label(const TransportReadiness.ready()), 'ready');
    expect(label(const TransportReadiness.notInstalled(provider: 'codex')), 'notInstalled');
    expect(label(const TransportReadiness.signedOut(provider: 'codex', signInCommand: 'codex login')), 'signedOut');
    expect(label(const TransportReadiness.httpKeyMissing(provider: 'anthropic')), 'httpKeyMissing');
    expect(label(const TransportReadiness.unknown()), 'unknown');
  });

  test('signedOut carries provider and signInCommand', () {
    const r = TransportReadiness.signedOut(provider: 'claude-cli', signInCommand: 'claude auth login');
    expect(r, isA<TransportSignedOut>());
    expect((r as TransportSignedOut).provider, 'claude-cli');
    expect(r.signInCommand, 'claude auth login');
  });
}
