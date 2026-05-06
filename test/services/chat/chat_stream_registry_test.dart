import 'package:code_bench_app/services/chat/chat_stream_registry.dart';
import 'package:code_bench_app/services/chat/chat_stream_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('latestState returns idle for unknown sessions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(chatStreamRegistryProvider);
    expect(registry.latestState('unknown'), isA<ChatStreamIdle>());
  });

  test('watchState emits the current state immediately', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(chatStreamRegistryProvider);
    final first = await registry.watchState('s').first;
    expect(first, isA<ChatStreamIdle>());
  });
}
