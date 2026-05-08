import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/session/models/chat_session.dart';
import 'package:code_bench_app/data/shared/chat_message.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_session_streaming.dart';
import 'package:code_bench_app/features/project_sidebar/widgets/conversation_tile.dart';

class _IdleChatMessages extends ChatMessagesNotifier {
  @override
  Future<List<ChatMessage>> build(String sessionId) async => const [];
}

Widget _wrap(Widget child, String sessionId) {
  return ProviderScope(
    overrides: [
      chatSessionStreamingProvider(sessionId).overrideWith((_) => Stream.value(false)),
      chatSessionFailedProvider(sessionId).overrideWith((_) => Stream.value(false)),
      chatMessagesProvider(sessionId).overrideWith(() => _IdleChatMessages()),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: [AppColors.dark]),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  final session = ChatSession(
    sessionId: 's1',
    title: 'My session',
    modelId: 'gpt-4',
    providerId: 'openai',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );

  testWidgets('right-click shows Archive option', (tester) async {
    String? archived;
    await tester.pumpWidget(
      _wrap(
        ConversationTile(
          session: session,
          isActive: false,
          onTap: () {},
          onArchive: () => archived = session.sessionId,
        ),
        session.sessionId,
      ),
    );

    await tester.sendEventToBinding(
      TestPointer(1, PointerDeviceKind.mouse).hover(tester.getCenter(find.text('My session'))),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('My session')),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Archive'), findsOneWidget);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(archived, 's1');
  });

  testWidgets('right-click Delete shows confirmation dialog before firing onDelete', (tester) async {
    bool deleted = false;
    await tester.pumpWidget(
      _wrap(
        ConversationTile(session: session, isActive: false, onTap: () {}, onDelete: () => deleted = true),
        session.sessionId,
      ),
    );

    await tester.sendEventToBinding(
      TestPointer(1, PointerDeviceKind.mouse).hover(tester.getCenter(find.text('My session'))),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('My session')),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Dialog shown, onDelete not yet called.
    expect(find.text('Delete this conversation?'), findsOneWidget);
    expect(deleted, isFalse);

    // Confirm deletion.
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });

  testWidgets('right-click Delete — Cancel does not call onDelete', (tester) async {
    bool deleted = false;
    await tester.pumpWidget(
      _wrap(
        ConversationTile(session: session, isActive: false, onTap: () {}, onDelete: () => deleted = true),
        session.sessionId,
      ),
    );

    await tester.sendEventToBinding(
      TestPointer(1, PointerDeviceKind.mouse).hover(tester.getCenter(find.text('My session'))),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('My session')),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
  });
}
