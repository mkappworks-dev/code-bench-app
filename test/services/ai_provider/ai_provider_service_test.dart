import 'package:code_bench_app/data/ai/datasource/ai_provider_datasource.dart';
import 'package:code_bench_app/data/shared/ai_model.dart';
import 'package:code_bench_app/services/ai_provider/ai_provider_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDs implements AIProviderDatasource {
  _FakeDs({required this.id, required this.detectResult, required this.authResult, this.onVerifyAuth})
    : displayName = 'Fake';

  final DetectionResult detectResult;
  final AuthStatus authResult;
  final void Function()? onVerifyAuth;

  @override
  final String id;
  @override
  final String displayName;

  @override
  Future<DetectionResult> detect() async => detectResult;

  @override
  Future<AuthStatus> verifyAuth() async {
    onVerifyAuth?.call();
    return authResult;
  }

  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities();

  @override
  Stream<ProviderRuntimeEvent> sendAndStream({
    required String prompt,
    required String sessionId,
    required String workingDirectory,
    ProviderTurnSettings? settings,
  }) => throw UnimplementedError();

  @override
  void respondToPermissionRequest(String sessionId, String requestId, {required bool approved}) =>
      throw UnimplementedError();

  @override
  void cancel(String sessionId) => throw UnimplementedError();

  @override
  Future<void> dispose() async {}
}

class _AIProviderServiceUnderTest extends AIProviderService {
  _AIProviderServiceUnderTest(this._fakes);
  final Map<String, AIProviderDatasource> _fakes;
  @override
  Map<String, AIProviderDatasource> build() => _fakes;
}

void main() {
  test('listWithStatus returns ProviderEntry with both install and auth status', () async {
    final fake = _FakeDs(
      id: 'fake',
      detectResult: const DetectionResult.installed('1.0.0'),
      authResult: const AuthStatus.unauthenticated(signInCommand: 'fake login'),
    );
    final container = ProviderContainer(
      overrides: [
        aIProviderServiceProvider.overrideWith(() => _AIProviderServiceUnderTest({'fake': fake})),
      ],
    );
    addTearDown(container.dispose);

    final entries = await container.read(aIProviderServiceProvider.notifier).listWithStatus();
    expect(entries, hasLength(1));
    expect(entries.first.status, isA<ProviderAvailable>());
    expect(entries.first.authStatus, isA<AuthUnauthenticated>());
  });

  test('listWithStatus skips auth probe when install is missing', () async {
    var verifyAuthCalled = false;
    final fake = _FakeDs(
      id: 'gone',
      detectResult: const DetectionResult.missing(),
      authResult: const AuthStatus.unknown(),
      onVerifyAuth: () => verifyAuthCalled = true,
    );
    final container = ProviderContainer(
      overrides: [
        aIProviderServiceProvider.overrideWith(() => _AIProviderServiceUnderTest({'gone': fake})),
      ],
    );
    addTearDown(container.dispose);

    final entries = await container.read(aIProviderServiceProvider.notifier).listWithStatus();
    expect(entries, hasLength(1));
    expect(entries.first.status, isA<ProviderUnavailable>());
    expect(entries.first.authStatus, const AuthStatus.unknown());
    expect(verifyAuthCalled, isFalse, reason: 'auth probe should not run when install is missing');
  });

  test('getAuthStatus returns unknown for unregistered provider', () async {
    final container = ProviderContainer(
      overrides: [aIProviderServiceProvider.overrideWith(() => _AIProviderServiceUnderTest({}))],
    );
    addTearDown(container.dispose);
    final result = await container.read(aIProviderServiceProvider.notifier).getAuthStatus('nope');
    expect(result, const AuthStatus.unknown());
  });
}
