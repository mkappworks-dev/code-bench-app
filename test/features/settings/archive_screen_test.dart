import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/session/models/chat_session.dart';
import 'package:code_bench_app/data/project/models/project.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import 'package:code_bench_app/features/archive/archive_screen.dart';
import 'package:code_bench_app/features/archive/notifiers/archive_actions.dart';

class _FakeArchiveActions extends ArchiveActions {
  final List<String> unarchiveCalls = [];
  final List<String> deleteCalls = [];
  final List<List<String>> unarchiveAllCalls = [];
  final List<List<String>> deleteAllCalls = [];

  @override
  Future<void> unarchiveSession(String id) async => unarchiveCalls.add(id);

  @override
  Future<void> deleteSession(String id) async => deleteCalls.add(id);

  @override
  Future<void> unarchiveAllForProject(List<String> ids) async => unarchiveAllCalls.add(ids);

  @override
  Future<void> deleteAllForProject(List<String> ids) async => deleteAllCalls.add(ids);
}

Widget _buildArchive({
  List<ChatSession> sessions = const [],
  List<Project> projects = const [],
  _FakeArchiveActions? archiveActions,
}) {
  return ProviderScope(
    overrides: [
      archivedSessionsProvider.overrideWith((ref) => Stream.value(sessions)),
      projectsProvider.overrideWith((ref) => Stream.value(projects)),
      if (archiveActions != null) archiveActionsProvider.overrideWith(() => archiveActions),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: [AppColors.dark]),
      home: const ArchiveScreen(),
    ),
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

  testWidgets('Unarchive button fires onUnarchive callback', (tester) async {
    final fake = _FakeArchiveActions();
    final session = ChatSession(
      sessionId: 's2',
      title: 'Another chat',
      modelId: 'm',
      providerId: 'anthropic',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    await tester.pumpWidget(_buildArchive(sessions: [session], archiveActions: fake));
    await tester.pump();

    await tester.tap(find.text('Unarchive'));
    await tester.pump();

    expect(fake.unarchiveCalls, contains('s2'));
  });

  testWidgets('deleteSession records call on fake', (tester) async {
    final fake = _FakeArchiveActions();
    await fake.deleteSession('s99');
    expect(fake.deleteCalls, contains('s99'));
  });

  testWidgets('unarchiveAllForProject records ids', (tester) async {
    final fake = _FakeArchiveActions();
    await fake.unarchiveAllForProject(['a', 'b']);
    expect(fake.unarchiveAllCalls, [
      ['a', 'b'],
    ]);
  });

  testWidgets('deleteAllForProject records ids', (tester) async {
    final fake = _FakeArchiveActions();
    await fake.deleteAllForProject(['x', 'y']);
    expect(fake.deleteAllCalls, [
      ['x', 'y'],
    ]);
  });

  testWidgets('archived session card shows Delete button', (tester) async {
    final session = ChatSession(
      sessionId: 's3',
      title: 'Chat to delete',
      modelId: 'm',
      providerId: 'anthropic',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    await tester.pumpWidget(_buildArchive(sessions: [session]));
    await tester.pump();

    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('Delete button shows confirmation dialog', (tester) async {
    final session = ChatSession(
      sessionId: 's4',
      title: 'Deletable chat',
      modelId: 'm',
      providerId: 'anthropic',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    await tester.pumpWidget(_buildArchive(sessions: [session]));
    await tester.pump();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete archived conversation?'), findsOneWidget);
    expect(find.text('Deletable chat'), findsWidgets);
  });
}
