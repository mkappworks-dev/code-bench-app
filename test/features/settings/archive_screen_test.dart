import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/models/chat_session.dart';
import 'package:code_bench_app/data/models/project.dart';
import 'package:code_bench_app/features/chat/chat_notifier.dart';
import 'package:code_bench_app/features/project_sidebar/project_sidebar_notifier.dart';
import 'package:code_bench_app/features/settings/archive_screen.dart';

Widget _buildArchive({
  List<ChatSession> sessions = const [],
  List<Project> projects = const [],
  void Function(String)? onUnarchive,
}) {
  return ProviderScope(
    overrides: [
      archivedSessionsProvider.overrideWith((ref) => Stream.value(sessions)),
      projectsProvider.overrideWith((ref) => Stream.value(projects)),
    ],
    child: MaterialApp(home: ArchiveScreen(onUnarchive: onUnarchive ?? (_) {})),
  );
}

void main() {
  testWidgets('shows empty state when no archived sessions', (tester) async {
    await tester.pumpWidget(_buildArchive());
    await tester.pump();

    expect(find.text('No archived conversations'), findsOneWidget);
  });

  testWidgets('shows archived session title', (tester) async {
    final session = ChatSession(
      sessionId: 's1',
      title: 'Old chat',
      modelId: 'm',
      providerId: 'anthropic',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    await tester.pumpWidget(_buildArchive(sessions: [session]));
    await tester.pump();

    expect(find.text('Old chat'), findsOneWidget);
    expect(find.text('Unarchive'), findsOneWidget);
  });

  testWidgets('Unarchive button calls onUnarchive', (tester) async {
    String? unarchived;
    final session = ChatSession(
      sessionId: 's2',
      title: 'Another chat',
      modelId: 'm',
      providerId: 'anthropic',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    await tester.pumpWidget(_buildArchive(sessions: [session], onUnarchive: (id) => unarchived = id));
    await tester.pump();

    await tester.tap(find.text('Unarchive'));
    await tester.pump();

    expect(unarchived, 's2');
  });
}
