import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/theme_constants.dart';
import '../features/chat/chat_notifier.dart';
import '../features/chat/chat_panel.dart';
import '../features/editor/editor_notifier.dart';
import '../features/file_explorer/file_explorer_panel.dart';
import '../services/session/session_service.dart';
import 'widgets/app_title_bar.dart';
import 'widgets/side_nav_rail.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  double _explorerWidth = AppConstants.defaultExplorerWidth;
  double _chatWidth = AppConstants.defaultChatWidth;
  bool _explorerVisible = true;

  @override
  void initState() {
    super.initState();
    _loadPaneWidths();
  }

  Future<void> _loadPaneWidths() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _explorerWidth =
          prefs.getDouble(AppConstants.prefExplorerWidth) ??
          AppConstants.defaultExplorerWidth;
      _chatWidth =
          prefs.getDouble(AppConstants.prefChatWidth) ??
          AppConstants.defaultChatWidth;
    });
  }

  Future<void> _savePaneWidths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefExplorerWidth, _explorerWidth);
    await prefs.setDouble(AppConstants.prefChatWidth, _chatWidth);
  }

  Future<void> _newChat() async {
    final model = ref.read(selectedModelProvider);
    final service = ref.read(sessionServiceProvider);
    final sessionId = await service.createSession(model: model);
    ref.read(activeSessionIdProvider.notifier).set(sessionId);
    if (mounted) context.go('/chat/$sessionId');
  }

  Future<void> _saveCurrentFile() async {
    final activePath = ref.read(activeFilePathProvider);
    if (activePath == null) return;
    final tabs = ref.read(editorTabsProvider);
    final file = tabs.where((f) => f.path == activePath).firstOrNull;
    if (file == null || file.isReadOnly || !file.isDirty) return;
    await ref.read(saveFileProvider(activePath).future);
  }

  void _closeCurrentTab() {
    final activePath = ref.read(activeFilePathProvider);
    if (activePath == null) return;
    ref.read(editorTabsProvider.notifier).closeFile(activePath);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final showEditorPanes =
        location.startsWith('/editor') ||
        location.startsWith('/chat') ||
        location.startsWith('/github');

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _newChat,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _newChat,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            _saveCurrentFile,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _saveCurrentFile,
        const SingleActivator(LogicalKeyboardKey.keyW, meta: true):
            _closeCurrentTab,
        const SingleActivator(LogicalKeyboardKey.keyW, control: true):
            _closeCurrentTab,
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            setState(() => _explorerVisible = !_explorerVisible),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            setState(() => _explorerVisible = !_explorerVisible),
        const SingleActivator(LogicalKeyboardKey.comma, meta: true): () =>
            context.go('/settings'),
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
            context.go('/settings'),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const AppTitleBar(),
            Expanded(
              child: Row(
                children: [
                  SideNavRail(currentLocation: location),
                  Expanded(
                    child: Row(
                      children: [
                        if (showEditorPanes && _explorerVisible) ...[
                          SizedBox(
                            width: _explorerWidth,
                            child: const FileExplorerPanel(),
                          ),
                          _ResizableDivider(
                            onDrag: (delta) {
                              setState(() {
                                _explorerWidth = (_explorerWidth + delta).clamp(
                                  AppConstants.minPaneWidth,
                                  400,
                                );
                              });
                              _savePaneWidths();
                            },
                          ),
                        ],
                        Expanded(child: widget.child),
                        if (showEditorPanes) ...[
                          _ResizableDivider(
                            onDrag: (delta) {
                              setState(() {
                                _chatWidth = (_chatWidth - delta).clamp(
                                  AppConstants.minPaneWidth,
                                  600,
                                );
                              });
                              _savePaneWidths();
                            },
                          ),
                          SizedBox(width: _chatWidth, child: const ChatPanel()),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResizableDivider extends StatelessWidget {
  const _ResizableDivider({required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(width: 4, color: ThemeConstants.dividerColor),
      ),
    );
  }
}
