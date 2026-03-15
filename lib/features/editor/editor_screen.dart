import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import 'editor_notifier.dart';
import 'widgets/code_editor_widget.dart';
import 'widgets/file_tab_bar.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilePath = ref.watch(activeFilePathProvider);
    final tabs = ref.watch(editorTabsProvider);

    if (tabs.isEmpty) {
      return const _NoFileOpen();
    }

    final activeFile = tabs.firstWhere(
      (f) => f.path == activeFilePath,
      orElse: () => tabs.first,
    );

    return Column(
      children: [
        FileTabBar(tabs: tabs, activeFilePath: activeFilePath),
        Expanded(
          child: CodeEditorWidget(file: activeFile),
        ),
      ],
    );
  }
}

class EditorPanel extends ConsumerWidget {
  const EditorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const EditorScreen();
  }
}

class _NoFileOpen extends StatelessWidget {
  const _NoFileOpen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeConstants.editorBackground,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.code,
              size: 48,
              color: ThemeConstants.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'No file open',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Open a file from the explorer',
              style: TextStyle(
                color: ThemeConstants.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
