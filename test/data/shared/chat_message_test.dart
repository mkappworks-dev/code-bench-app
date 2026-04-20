import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/data/session/models/permission_request.dart';

void main() {
  test('ChatMessage defaults iterationCapReached to false and pendingPermissionRequest to null', () {
    final msg = ChatMessage(
      id: 'm',
      sessionId: 's',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime(2026, 4, 20),
    );
    expect(msg.iterationCapReached, isFalse);
    expect(msg.pendingPermissionRequest, isNull);
  });

  test('ChatMessage round-trips new fields through JSON', () {
    final msg = ChatMessage(
      id: 'm',
      sessionId: 's',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime(2026, 4, 20),
      iterationCapReached: true,
      pendingPermissionRequest: const PermissionRequest(
        toolEventId: 'te1',
        toolName: 'write_file',
        summary: 'lib/foo.dart · New file · 20 bytes',
        input: {'path': 'lib/foo.dart', 'content': '// hi'},
      ),
    );
    final round = ChatMessage.fromJson(msg.toJson());
    expect(round.iterationCapReached, isTrue);
    expect(round.pendingPermissionRequest?.toolName, 'write_file');
  });
}
