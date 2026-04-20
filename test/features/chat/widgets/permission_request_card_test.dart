import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/session/models/permission_request.dart';
import 'package:code_bench_app/features/chat/notifiers/agent_permission_request_notifier.dart';
import 'package:code_bench_app/features/chat/widgets/permission_request_card.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: ThemeData.dark().copyWith(extensions: [AppColors.dark]),
    home: Scaffold(body: child),
  ),
);

void main() {
  const writeReq = PermissionRequest(
    toolEventId: 'te',
    toolName: 'write_file',
    summary: 'lib/foo.dart · New file · 20 bytes',
    input: {'path': 'lib/foo.dart', 'content': '// line1\n// line2\n// line3\n'},
  );

  const emptyContentReq = PermissionRequest(
    toolEventId: 'te',
    toolName: 'write_file',
    summary: 'lib/foo.dart · New file · 0 bytes',
    input: {'path': 'lib/foo.dart', 'content': ''},
  );

  testWidgets('collapsed by default — no preview visible, Show diff label present', (tester) async {
    await tester.pumpWidget(_wrap(const PermissionRequestCard(request: writeReq)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Show diff'), findsOneWidget);
    expect(find.text('// line1'), findsNothing);
  });

  testWidgets('tapping Show diff reveals preview and flips to Hide diff', (tester) async {
    await tester.pumpWidget(_wrap(const PermissionRequestCard(request: writeReq)));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Show diff'));
    await tester.pumpAndSettle();

    expect(find.text('// line1'), findsOneWidget);
    expect(find.textContaining('Hide diff'), findsOneWidget);
  });

  testWidgets('disclosure hidden when preview cannot be built', (tester) async {
    await tester.pumpWidget(_wrap(const PermissionRequestCard(request: emptyContentReq)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Show diff'), findsNothing);
  });

  testWidgets('Allow calls resolve(true)', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              theme: ThemeData.dark().copyWith(extensions: [AppColors.dark]),
              home: const Scaffold(body: PermissionRequestCard(request: writeReq)),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final future = container.read(agentPermissionRequestProvider.notifier).request(writeReq);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Allow'));
    await tester.pumpAndSettle();

    expect(await future, isTrue);
  });
}
