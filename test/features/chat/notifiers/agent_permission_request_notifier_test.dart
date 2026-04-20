import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/session/models/permission_request.dart';
import 'package:code_bench_app/features/chat/notifiers/agent_permission_request_notifier.dart';

void main() {
  test('request() yields a future that resolves to the user choice', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(agentPermissionRequestProvider.notifier);

    const req = PermissionRequest(
      toolEventId: 'te',
      toolName: 'write_file',
      summary: 'lib/foo.dart · New file · 20 bytes',
      input: {'path': 'lib/foo.dart', 'content': '// hi'},
    );

    final future = notifier.request(req);
    expect(container.read(agentPermissionRequestProvider)?.toolName, 'write_file');

    notifier.resolve(true);
    expect(await future, isTrue);
    expect(container.read(agentPermissionRequestProvider), isNull);
  });
}
