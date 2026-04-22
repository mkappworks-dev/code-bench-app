import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/core/theme/app_colors.dart';
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:code_bench_app/features/mcp_servers/widgets/mcp_server_editor_dialog.dart';

Widget _buildDialogLauncher({required Future<void> Function(McpServerConfig) onSave}) {
  return MaterialApp(
    theme: ThemeData(extensions: [AppColors.dark]),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => McpServerEditorDialog(onSave: onSave),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('dialog closes when onSave succeeds', (tester) async {
    await tester.pumpWidget(_buildDialogLauncher(onSave: (_) async {}));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Fill the name field
    await tester.enterText(find.byType(TextField).first, 'My Server');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Dialog should be gone
    expect(find.byType(McpServerEditorDialog), findsNothing);
  });

  testWidgets('dialog stays open when onSave throws', (tester) async {
    await tester.pumpWidget(_buildDialogLauncher(onSave: (_) async => throw Exception('DB error')));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Fill the name field
    await tester.enterText(find.byType(TextField).first, 'My Server');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Dialog must still be visible
    expect(find.byType(McpServerEditorDialog), findsOneWidget);
  });
}
