import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/models/chat_message.dart';
import 'package:code_bench_app/features/chat/widgets/message_bubble.dart'
    show MessageBubble, StreamingDot, parseCodeFenceInfo;

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

ChatMessage _msg(MessageRole role, {bool streaming = false}) => ChatMessage(
      id: 'id',
      sessionId: 'sid',
      role: role,
      content: 'Hello world',
      timestamp: DateTime.now(),
      isStreaming: streaming,
    );

void main() {
  testWidgets('user message is right-aligned', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: _msg(MessageRole.user))));
    final align = tester.widget<Align>(find.byType(Align).first);
    expect(align.alignment, Alignment.centerRight);
  });

  testWidgets('assistant message has no background container', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: _msg(MessageRole.assistant))));
    // No avatar icon
    expect(find.byIcon(Icons.smart_toy), findsNothing);
    // No role label text
    expect(find.text('Assistant'), findsNothing);
  });

  testWidgets('streaming shows pulsing dot, not CircularProgressIndicator', (tester) async {
    await tester.pumpWidget(
      _wrap(MessageBubble(message: _msg(MessageRole.assistant, streaming: true))),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(StreamingDot), findsOneWidget);
  });

  group('parseCodeFenceInfo', () {
    test('returns language only when no filename', () {
      final result = parseCodeFenceInfo('dart');
      expect(result.$1, 'dart');
      expect(result.$2, isNull);
    });

    test('returns language and filename when both present', () {
      final result = parseCodeFenceInfo('dart lib/auth/middleware.dart');
      expect(result.$1, 'dart');
      expect(result.$2, 'lib/auth/middleware.dart');
    });

    test('handles filename with spaces via second+ word join', () {
      final result = parseCodeFenceInfo('dart path with spaces/file.dart');
      expect(result.$1, 'dart');
      expect(result.$2, 'path with spaces/file.dart');
    });
  });
}
