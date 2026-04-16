import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/apply/models/applied_change.dart';
import 'package:code_bench_app/data/project/models/project.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/chat/widgets/changes_panel.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [
      // Override the stream-based projectsProvider so it doesn't hit the
      // database layer. An empty list is fine — changes_panel gracefully
      // handles project == null.
      projectsProvider.overrideWith((ref) => Stream.value(<Project>[])),
    ],
  );
  return c;
}

Widget _wrap(Widget child, ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: ThemeData(extensions: [AppColors.dark]),
      home: Scaffold(body: child),
    ),
  );
}

AppliedChange _makeChange({
  String id = 'c1',
  String sessionId = 'sid',
  String messageId = 'm1',
  String filePath = '/tmp/proj/lib/main.dart',
  String? originalContent = 'old',
  String newContent = 'new',
  int additions = 0,
  int deletions = 0,
}) => AppliedChange(
  id: id,
  sessionId: sessionId,
  messageId: messageId,
  filePath: filePath,
  originalContent: originalContent,
  newContent: newContent,
  appliedAt: DateTime.now(),
  additions: additions,
  deletions: deletions,
);

void main() {
  testWidgets('renders persisted +N and −N from AppliedChange', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    container.read(appliedChangesProvider.notifier).apply(_makeChange(additions: 7, deletions: 3));

    await tester.pumpWidget(_wrap(const ChangesPanel(sessionId: 'sid'), container));

    expect(find.text('+7'), findsOneWidget);
    expect(find.text('\u22123'), findsOneWidget);
  });

  testWidgets('shows "No changes yet" placeholder when empty', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(const ChangesPanel(sessionId: 'sid'), container));

    expect(find.text('No changes yet'), findsOneWidget);
  });

  testWidgets('swapping N lines for N different lines does NOT show +0 −0 (regression guard)', (tester) async {
    // In the pre-fix world, _lineCounts computed a signed line-delta
    // (newLines - originalLines), which returned 0/0 when the line count
    // was unchanged — visually identical to "no change". After the fix,
    // the panel reads persisted additions/deletions from AppliedChange,
    // so a 10-for-10 swap shows non-zero counts on both sides.
    final container = _container();
    addTearDown(container.dispose);

    container.read(appliedChangesProvider.notifier).apply(_makeChange(additions: 10, deletions: 10));

    await tester.pumpWidget(_wrap(const ChangesPanel(sessionId: 'sid'), container));

    expect(find.text('+10'), findsOneWidget);
    expect(find.text('\u221210'), findsOneWidget);
    // Explicit regression assertions: the old buggy rendering is gone.
    expect(find.text('+0'), findsNothing);
    expect(find.text('\u22120'), findsNothing);
  });

  testWidgets('groups multiple changes under their messageId', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    final notifier = container.read(appliedChangesProvider.notifier);
    notifier.apply(_makeChange(id: 'c1', messageId: 'm1', additions: 1, deletions: 0));
    notifier.apply(
      _makeChange(id: 'c2', messageId: 'm1', filePath: '/tmp/proj/lib/other.dart', additions: 2, deletions: 0),
    );

    await tester.pumpWidget(_wrap(const ChangesPanel(sessionId: 'sid'), container));

    // One "Message 1" header for the grouped m1 bundle
    expect(find.text('Message 1'), findsOneWidget);
    // Both file basenames render
    expect(find.text('main.dart'), findsOneWidget);
    expect(find.text('other.dart'), findsOneWidget);
  });
}
