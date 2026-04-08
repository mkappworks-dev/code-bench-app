import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/repository.dart';
import '../../../services/filesystem/filesystem_service.dart';
import '../../../services/github/github_api_service.dart';

class RepoFileTree extends ConsumerStatefulWidget {
  const RepoFileTree({
    super.key,
    required this.repo,
    required this.branch,
    required this.onOpenFile,
  });

  final Repository repo;
  final String branch;
  final void Function(String path, String content, String language) onOpenFile;

  @override
  ConsumerState<RepoFileTree> createState() => _RepoFileTreeState();
}

class _RepoFileTreeState extends ConsumerState<RepoFileTree> {
  List<GitTreeItem>? _tree;
  bool _loading = true;
  String? _error;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  @override
  void didUpdateWidget(RepoFileTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branch != widget.branch ||
        oldWidget.repo.name != widget.repo.name) {
      _loadTree();
    }
  }

  Future<void> _loadTree() async {
    setState(() {
      _loading = true;
      _error = null;
      _expanded.clear();
    });
    try {
      final api = await ref.read(githubApiServiceProvider.future);
      if (api == null) return;
      final items = await api.getRepositoryTree(
        widget.repo.owner,
        widget.repo.name,
        widget.branch,
      );
      setState(() => _tree = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openFile(GitTreeItem item) async {
    try {
      final api = await ref.read(githubApiServiceProvider.future);
      if (api == null) return;
      final content = await api.getFileContent(
        widget.repo.owner,
        widget.repo.name,
        item.path,
        widget.branch,
      );
      final language = FilesystemService().detectLanguage(item.path);
      widget.onOpenFile(item.path, content, language);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load file: $e'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: ThemeConstants.error),
        ),
      );
    }
    if (_tree == null || _tree!.isEmpty) {
      return const Center(
        child: Text(
          'Empty repository',
          style: TextStyle(color: ThemeConstants.textMuted),
        ),
      );
    }

    final nodes = _buildTree(_tree!);
    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, i) => _buildNode(nodes[i]),
    );
  }

  List<_TreeNode> _buildTree(List<GitTreeItem> items) {
    // Build directory structure from flat list
    final Map<String, _TreeNode> dirMap = {};
    final List<_TreeNode> roots = [];

    // First pass: create all directory nodes
    for (final item in items.where((i) => i.type == 'tree')) {
      dirMap[item.path] = _TreeNode(
        path: item.path,
        name: p.basename(item.path),
        isDir: true,
        depth: item.path.split('/').length - 1,
      );
    }

    // Second pass: create file nodes and assign parents
    for (final item in items.where((i) => i.type == 'blob')) {
      final node = _TreeNode(
        path: item.path,
        name: p.basename(item.path),
        isDir: false,
        depth: item.path.split('/').length - 1,
        item: item,
      );
      final parentPath = p.dirname(item.path);
      if (parentPath == '.') {
        roots.add(node);
      } else {
        dirMap[parentPath]?.children.add(node);
      }
    }

    // Assign directory children
    for (final entry in dirMap.entries) {
      final parentPath = p.dirname(entry.key);
      if (parentPath == '.') {
        roots.add(entry.value);
      } else {
        dirMap[parentPath]?.children.add(entry.value);
      }
    }

    // Sort: dirs first, then files
    void sortNodes(List<_TreeNode> nodes) {
      nodes.sort((a, b) {
        if (a.isDir && !b.isDir) return -1;
        if (!a.isDir && b.isDir) return 1;
        return a.name.compareTo(b.name);
      });
      for (final n in nodes) {
        sortNodes(n.children);
      }
    }

    sortNodes(roots);
    return roots;
  }

  Widget _buildNode(_TreeNode node) {
    if (node.isDir) {
      final isExpanded = _expanded.contains(node.path);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TreeItem(
            name: node.name,
            depth: node.depth,
            isDir: true,
            isExpanded: isExpanded,
            onTap: () => setState(() {
              if (isExpanded) {
                _expanded.remove(node.path);
              } else {
                _expanded.add(node.path);
              }
            }),
          ),
          if (isExpanded) ...node.children.map(_buildNode),
        ],
      );
    } else {
      return _TreeItem(
        name: node.name,
        depth: node.depth,
        isDir: false,
        onTap: () => _openFile(node.item!),
      );
    }
  }
}

class _TreeNode {
  _TreeNode({
    required this.path,
    required this.name,
    required this.isDir,
    required this.depth,
    this.item,
  });

  final String path;
  final String name;
  final bool isDir;
  final int depth;
  final GitTreeItem? item;
  final List<_TreeNode> children = [];
}

class _TreeItem extends StatelessWidget {
  const _TreeItem({
    required this.name,
    required this.depth,
    required this.isDir,
    required this.onTap,
    this.isExpanded = false,
  });

  final String name;
  final int depth;
  final bool isDir;
  final VoidCallback onTap;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: ThemeConstants.editorLineHighlight,
      child: Container(
        height: 22,
        padding: EdgeInsets.only(left: depth * 16.0 + 12),
        child: Row(
          children: [
            if (isDir)
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 14,
                color: ThemeConstants.textMuted,
              )
            else
              const SizedBox(width: 14),
            const SizedBox(width: 4),
            Icon(
              isDir ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
              size: 14,
              color: isDir ? ThemeConstants.warning : ThemeConstants.textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
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
    );
  }
}
