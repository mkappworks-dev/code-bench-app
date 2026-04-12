import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:code_bench_app/core/constants/app_icons.dart';
import 'package:code_bench_app/data/models/project.dart';
import 'package:code_bench_app/features/chat/widgets/chat_input_bar.dart';
import 'package:code_bench_app/features/project_sidebar/project_sidebar_notifier.dart';
import 'package:code_bench_app/services/project/project_service.dart';

/// Minimal stub so the missing-project guard's `_isProjectAvailable` helper
/// can fire `refreshProjectStatus` in tests without pulling in a real Drift
/// database. Extending `Mock` gives us a no-crash default for any other
/// method that might get exercised incidentally.
///
/// Records every `refreshProjectStatus` call so the drift-self-heal tests can
/// assert it fired (Cases B and C) or didn't (Cases A and D).
class _FakeProjectService extends Mock implements ProjectService {
  final List<String?> refreshCalls = <String?>[];
  @override
  Future<void> refreshProjectStatus(String? projectId) async {
    refreshCalls.add(projectId);
  }
}

Project _makeProject({required String id, required String path, ProjectStatus status = ProjectStatus.available}) =>
    Project(id: id, name: id, path: path, createdAt: DateTime(2026, 4, 12), status: status);

/// Test-scoped wrap that lets callers inject the project list, the active
/// project id, and a fake ProjectService. Keeps the older no-arg shape
/// working for the effort/draft tests that don't care about projects.
Widget _wrap(
  Widget child, {
  List<Project> projects = const <Project>[],
  String? activeProjectId,
  ProjectService? projectService,
}) {
  final fakeService = projectService ?? _FakeProjectService();
  return ProviderScope(
    // Override projectsProvider so the widget tree can build without pulling
    // in the real on-disk Drift database (which leaves pending timers that
    // fail the test binding's invariant checks).
    overrides: [
      projectsProvider.overrideWith((ref) => Stream<List<Project>>.value(projects)),
      projectServiceProvider.overrideWith((ref) => fakeService),
      if (activeProjectId != null) activeProjectIdProvider.overrideWith(() => _FakeActiveProjectId(activeProjectId)),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

class _FakeActiveProjectId extends ActiveProjectIdNotifier {
  _FakeActiveProjectId(this._initial);
  final String _initial;
  @override
  String? build() => _initial;
}

/// Test harness that keeps a single ProviderScope alive while the caller
/// swaps the active sessionId via a GlobalKey. Needed because per-session
/// drafts live in module-level state that would otherwise stick around
/// across tests without the `setUp` reset below.
class _SessionSwitcher extends StatefulWidget {
  const _SessionSwitcher({super.key, required this.initial});
  final String initial;
  @override
  State<_SessionSwitcher> createState() => _SessionSwitcherState();
}

class _SessionSwitcherState extends State<_SessionSwitcher> {
  late String sessionId = widget.initial;
  void switchTo(String id) => setState(() => sessionId = id);
  @override
  Widget build(BuildContext context) => ChatInputBar(sessionId: sessionId);
}

// The send button is the one wrapping the up-arrow icon. The chat input
// has other InkWell/GestureDetectors for the chip controls, so the arrow
// icon is the most unambiguous anchor.
Finder _sendButton() => find.ancestor(of: find.byIcon(AppIcons.arrowUp), matching: find.byType(GestureDetector)).first;

// Unique substring that appears ONLY in the missing-project error snackbar,
// not in the TextField hint text or the tooltip. Lets tests target the
// send-guard's error path without false matches from rendering-side copy.
const _missingFolderSnackbarMessage = 'Right-click the project in the sidebar';

void main() {
  // `_sessionDrafts` is a module-level map in chat_input_bar.dart, so
  // entries from one test would otherwise bleed into the next. Reset it
  // before each test to keep isolation honest.
  setUp(clearSessionDraftsForTesting);

  testWidgets('effort chip shows current selection', (tester) async {
    await tester.pumpWidget(_wrap(const ChatInputBar(sessionId: 'sid')));
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('tapping effort chip opens dropdown with all options', (tester) async {
    await tester.pumpWidget(_wrap(const ChatInputBar(sessionId: 'sid')));
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
  });

  testWidgets('selecting effort option updates the chip label', (tester) async {
    await tester.pumpWidget(_wrap(const ChatInputBar(sessionId: 'sid')));
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low'));
    await tester.pumpAndSettle();
    expect(find.text('Low'), findsOneWidget);
  });

  testWidgets('switching to a never-typed-in session shows an empty draft', (tester) async {
    final key = GlobalKey<_SessionSwitcherState>();
    await tester.pumpWidget(_wrap(_SessionSwitcher(key: key, initial: 's1')));
    await tester.enterText(find.byType(TextField), 'half-written question');
    expect(find.text('half-written question'), findsOneWidget);

    // Switch to s2 which has never had anything typed — should be empty,
    // not inherit s1's draft.
    key.currentState!.switchTo('s2');
    await tester.pump();

    expect(find.text('half-written question'), findsNothing);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);
  });

  testWidgets('draft persists per-session when switching back and forth', (tester) async {
    final key = GlobalKey<_SessionSwitcherState>();
    await tester.pumpWidget(_wrap(_SessionSwitcher(key: key, initial: 's1')));

    // Type a draft in s1.
    await tester.enterText(find.byType(TextField), 's1 draft');

    // Switch to s2, type a different draft there.
    key.currentState!.switchTo('s2');
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
    await tester.enterText(find.byType(TextField), 's2 draft');

    // Switch back to s1 — original draft should reappear.
    key.currentState!.switchTo('s1');
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 's1 draft');

    // And switching forward to s2 again — that draft should also be there.
    key.currentState!.switchTo('s2');
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 's2 draft');
  });

  group('missing-project send guard', () {
    testWidgets('send is NOT blocked when status is missing but folder exists on disk', (tester) async {
      // Case C from the review: Drift last re-emitted the row as `missing`,
      // but the user has since restored the folder on disk. The guard must
      // defer to the filesystem and let the send through — otherwise the UI
      // is silently pessimistic until the next project refresh. And because
      // the cached status disagrees with disk, `_isProjectAvailable` should
      // also kick off a refresh so the sidebar tile self-heals to available.
      final dir = Directory.systemTemp.createTempSync('chat_input_bar_test_case_c_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final fake = _FakeProjectService();
      final project = _makeProject(id: 'proj-c', path: dir.path, status: ProjectStatus.missing);
      await tester.pumpWidget(
        _wrap(
          const ChatInputBar(sessionId: 'sid'),
          projects: [project],
          activeProjectId: 'proj-c',
          projectService: fake,
        ),
      );
      await tester.pump();

      // Tap the send button (text field stays empty — `_send` bails at the
      // empty-text check before actually hitting the chat message notifier,
      // so we don't need to stub the full send path).
      await tester.tap(_sendButton());
      await tester.pumpAndSettle();

      expect(
        find.textContaining(_missingFolderSnackbarMessage),
        findsNothing,
        reason: 'Guard should consult the filesystem, not the stale DB status',
      );
      expect(
        fake.refreshCalls,
        contains('proj-c'),
        reason: 'Drift between cached missing and on-disk existing should trigger self-heal',
      );
    });

    testWidgets('send IS blocked when status is available but folder vanished on disk', (tester) async {
      // Case B: the cached row still says `available`, but the folder has
      // since been deleted out-of-band (user trashed it, external script
      // moved it). The guard must consult the filesystem and block — and
      // also fire a refresh so the sidebar tile falls back to missing.
      final dir = Directory.systemTemp.createTempSync('chat_input_bar_test_case_b_');
      // Delete BEFORE pump — at send time, the folder is gone.
      dir.deleteSync(recursive: true);

      final fake = _FakeProjectService();
      final project = _makeProject(id: 'proj-b', path: dir.path, status: ProjectStatus.available);
      await tester.pumpWidget(
        _wrap(
          const ChatInputBar(sessionId: 'sid'),
          projects: [project],
          activeProjectId: 'proj-b',
          projectService: fake,
        ),
      );
      await tester.pump();

      await tester.tap(_sendButton());
      await tester.pumpAndSettle();

      expect(find.textContaining(_missingFolderSnackbarMessage), findsOneWidget);
      expect(
        fake.refreshCalls,
        contains('proj-b'),
        reason: 'Drift between cached available and vanished disk should trigger self-heal',
      );
    });

    testWidgets('send IS blocked when status is missing and folder is also missing on disk', (tester) async {
      // Case D: cached status and filesystem agree — folder is gone. Block
      // the send, show the snackbar, and do NOT fire a redundant refresh
      // (nothing to self-heal).
      final fake = _FakeProjectService();
      final project = _makeProject(
        id: 'proj-d',
        path: '/tmp/chat_input_bar_test_case_d_does_not_exist_${DateTime.now().microsecondsSinceEpoch}',
        status: ProjectStatus.missing,
      );
      await tester.pumpWidget(
        _wrap(
          const ChatInputBar(sessionId: 'sid'),
          projects: [project],
          activeProjectId: 'proj-d',
          projectService: fake,
        ),
      );
      await tester.pump();

      await tester.tap(_sendButton());
      await tester.pumpAndSettle();

      expect(find.textContaining(_missingFolderSnackbarMessage), findsOneWidget);
      expect(fake.refreshCalls, isEmpty, reason: 'Cached status and disk agree — no drift, no self-heal refresh');
    });

    testWidgets('shows "No active project" snackbar when nothing is selected', (tester) async {
      // No activeProjectId override — `_resolveActiveProject` should return
      // null and the send guard should short-circuit with the dedicated
      // snackbar (not the missing-folder one).
      final fake = _FakeProjectService();
      await tester.pumpWidget(_wrap(const ChatInputBar(sessionId: 'sid'), projectService: fake));
      await tester.pump();

      await tester.tap(_sendButton());
      await tester.pumpAndSettle();

      expect(find.text('No active project.'), findsOneWidget);
      expect(
        find.textContaining(_missingFolderSnackbarMessage),
        findsNothing,
        reason: 'The no-project branch should not fall through to the missing-folder branch',
      );
      expect(fake.refreshCalls, isEmpty, reason: 'No project means nothing to self-heal');
    });
  });
}
