import 'package:code_bench_app/data/ai/models/cli_detection.dart';
import 'package:code_bench_app/services/cli/cli_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('binary not on PATH → notInstalled', () async {
    final service = container.read(cliDetectionServiceProvider.notifier);
    final detection = await service.probe('definitely-not-a-real-binary-abc');
    expect(detection, isA<CliNotInstalled>());
  });

  test('binary exists and parser handles graceful degradation', () async {
    final service = container.read(cliDetectionServiceProvider.notifier);
    final detection = await service.probe('/bin/echo');
    expect(detection, isA<CliInstalled>());
  });

  test('TTL cache: second probe within TTL returns cached value', () async {
    final service = container.read(cliDetectionServiceProvider.notifier);
    final first = await service.probe('/bin/echo', ttl: const Duration(minutes: 5));
    final second = await service.probe('/bin/echo', ttl: const Duration(minutes: 5));
    expect(identical(first, second), isTrue);
  });

  test('invalidate forces re-probe', () async {
    final service = container.read(cliDetectionServiceProvider.notifier);
    final first = await service.probe('/bin/echo');
    service.invalidate('/bin/echo');
    final second = await service.probe('/bin/echo');
    expect(identical(first, second), isFalse);
  });
}
