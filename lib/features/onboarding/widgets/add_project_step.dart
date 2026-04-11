import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../services/project/git_detector.dart';
import '../../../services/project/project_service.dart';

class AddProjectStep extends ConsumerStatefulWidget {
  const AddProjectStep({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  ConsumerState<AddProjectStep> createState() => _AddProjectStepState();
}

class _AddProjectStepState extends ConsumerState<AddProjectStep> {
  String? _selectedPath;
  bool _adding = false;

  bool get _isGitRepo =>
      _selectedPath != null && GitDetector.isGitRepo(_selectedPath!);

  Future<void> _browse() async {
    final result = await FilePicker.getDirectoryPath();
    if (result != null) setState(() => _selectedPath = result);
  }

  Future<void> _addProject() async {
    if (_selectedPath == null) return;
    setState(() => _adding = true);
    try {
      await ref
          .read(projectServiceProvider)
          .addExistingFolder(_selectedPath!);
      if (mounted) widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add project: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildDropZone()),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4A7CFF),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: _selectedPath == null || _adding ? null : _addProject,
          child: _adding
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Add Project', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildDropZone() {
    if (_selectedPath != null) {
      return _SelectedFolderPreview(
        path: _selectedPath!,
        isGit: _isGitRepo,
        onBrowse: _browse,
      );
    }

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        setState(() => _selectedPath = details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isDragOver = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isDragOver
                ? const Color(0xFF1A1F2E)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDragOver
                  ? const Color(0xFF4A7CFF)
                  : const Color(0xFF2A2A2A),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📁', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              const Text(
                'Drop a folder here',
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Text('— or —',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _browse,
                child: const Text(
                  'Browse for folder…',
                  style:
                      TextStyle(color: Color(0xFF4A7CFF), fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Selected folder preview ────────────────────────────────────────────────

class _SelectedFolderPreview extends StatelessWidget {
  const _SelectedFolderPreview({
    required this.path,
    required this.isGit,
    required this.onBrowse,
  });

  final String path;
  final bool isGit;
  final VoidCallback onBrowse;

  String get _projectName {
    final segments = path.split(Platform.pathSeparator)
      ..removeWhere((s) => s.isEmpty);
    return segments.isNotEmpty ? segments.last : path;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.folderOpen,
                  size: 18, color: Color(0xFF888888)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _projectName,
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isGit) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F3D1F),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFF1A6B35)),
                            ),
                            child: const Text(
                              'git',
                              style: TextStyle(
                                  color: Color(0xFF4CAF50), fontSize: 9),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      path,
                      style: const TextStyle(
                          color: Color(0xFF666666), fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onBrowse,
            child: const Text(
              'Change folder',
              style: TextStyle(
                color: Color(0xFF4A7CFF),
                fontSize: 11,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
