import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/session/models/chat_session.dart';
import 'package:code_bench_app/features/project_sidebar/widgets/conversation_tile.dart';

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
      MaterialApp(
        theme: ThemeData(extensions: [AppColors.dark]),
        home: Scaffold(
          body: ConversationTile(
            session: session,
            isActive: false,
            onTap: () {},
            onArchive: () => archived = session.sessionId,
          ),
        ),
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
}
