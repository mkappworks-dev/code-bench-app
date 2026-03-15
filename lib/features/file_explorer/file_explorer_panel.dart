import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../services/filesystem/filesystem_service.dart';
import '../editor/editor_notifier.dart';

class FileExplorerPanel extends ConsumerStatefulWidget {
  const FileExplorerPanel({super.key});

  @override
  ConsumerState<FileExplorerPanel> createState() => _FileExplorerPanelState();
}

class _FileExplorerPanelState extends ConsumerState<FileExplorerPanel> {
  final Map<String, bool> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final workDir = ref.watch(workingDirectoryProvider);

    return Container(
      color: ThemeConstants.sidebarBackground,
      child: Column(
        children: [
          // Header
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text(
                  'EXPLORER',
                  style: TextStyle(
                    color: ThemeConstants.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.folder_open_outlined, size: 16),
                  tooltip: 'Open folder',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                  onPressed: _openFolder,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // File tree
          Expanded(
            child: workDir == null
                ? const _NoFolderOpen()
                : _FileTree(rootPath: workDir, expanded: _expanded),
          ),
        ],
      ),
    );
  }

  Future<void> _openFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      ref.read(workingDirectoryProvider.notifier).set(result);
      setState(() => _expanded.clear());
      if (mounted) context.go('/editor');
    }
  }
}

class _FileTree extends ConsumerWidget {
  const _FileTree({required this.rootPath, required this.expanded});

  final String rootPath;
  final Map<String, bool> expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DirectoryNode(
      path: rootPath,
      depth: 0,
      expanded: expanded,
      isRoot: true,
    );
  }
}

class _DirectoryNode extends ConsumerStatefulWidget {
  const _DirectoryNode({
    required this.path,
    required this.depth,
    required this.expanded,
    this.isRoot = false,
    super.key,
  });

  final String path;
  final int depth;
  final Map<String, bool> expanded;
  final bool isRoot;

  @override
  ConsumerState<_DirectoryNode> createState() => _DirectoryNodeState();
}

class _DirectoryNodeState extends ConsumerState<_DirectoryNode> {
  late Future<List<FileNode>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _childrenFuture = ref.read(filesystemServiceProvider).listDirectory(widget.path);
    if (widget.isRoot) widget.expanded[widget.path] = true;
  }

  bool get _isExpanded => widget.expanded[widget.path] ?? false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isRoot)
          _FileExplorerItem(
            path: widget.path,
            depth: widget.depth,
            isDirectory: true,
            isExpanded: _isExpanded,
            onTap: () => setState(() {
              widget.expanded[widget.path] = !_isExpanded;
            }),
          ),
        if (_isExpanded)
          FutureBuilder<List<FileNode>>(
            future: _childrenFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.only(left: (widget.depth + 1) * 16.0),
                  child: const SizedBox(
                    height: 20,
                    child: LinearProgressIndicator(minHeight: 1),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) return const SizedBox();
              return Column(
                children: snapshot.data!.map((node) {
                  if (node.isDirectory) {
                    return _DirectoryNode(
                      key: ValueKey(node.path),
                      path: node.path,
                      depth: widget.depth + 1,
                      expanded: widget.expanded,
                    );
                  } else {
                    return _FileExplorerItem(
                      path: node.path,
                      depth: widget.depth + 1,
                      isDirectory: false,
                      onTap: () => _openFile(context, ref, node.path),
                    );
                  }
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref, String path) async {
    try {
      final fs = ref.read(filesystemServiceProvider);
      final content = await fs.readFile(path);
      final language = fs.detectLanguage(path);

      ref.read(editorTabsProvider.notifier).openFile(OpenFile(
            path: path,
            content: content,
            language: language,
          ));
      ref.read(activeFilePathProvider.notifier).set(path);

      if (context.mounted) context.go('/editor');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    }
  }
}

class _FileExplorerItem extends StatefulWidget {
  const _FileExplorerItem({
    required this.path,
    required this.depth,
    required this.isDirectory,
    required this.onTap,
    this.isExpanded = false,
  });

  final String path;
  final int depth;
  final bool isDirectory;
  final VoidCallback onTap;
  final bool isExpanded;

  @override
  State<_FileExplorerItem> createState() => _FileExplorerItemState();
}

class _FileExplorerItemState extends State<_FileExplorerItem> {
  bool _hovered = false;

  String get _name => widget.path.split('/').last;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 22,
          color: _hovered ? ThemeConstants.editorLineHighlight : Colors.transparent,
          padding: EdgeInsets.only(left: widget.depth * 16.0 + 8),
          child: Row(
            children: [
              if (widget.isDirectory)
                Icon(
                  widget.isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 14,
                  color: ThemeConstants.textMuted,
                )
              else
                const SizedBox(width: 14),
              const SizedBox(width: 4),
              Icon(
                widget.isDirectory ? Icons.folder_outlined : _getFileIcon(),
                size: 14,
                color: widget.isDirectory
                    ? ThemeConstants.warning
                    : ThemeConstants.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _name,
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    final ext = _name.contains('.') ? _name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
        return Icons.code;
      case 'json':
        return Icons.data_object;
      case 'md':
        return Icons.article_outlined;
      case 'yaml':
      case 'yml':
        return Icons.settings_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}

class _NoFolderOpen extends StatelessWidget {
  const _NoFolderOpen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No folder open.\nClick the folder icon to open a directory.',
          style: TextStyle(
            color: ThemeConstants.textMuted,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
