import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/repository.dart';
import '../../../services/github/github_api_service.dart';

class PrListWidget extends ConsumerStatefulWidget {
  const PrListWidget({super.key, required this.repo});

  final Repository repo;

  @override
  ConsumerState<PrListWidget> createState() => _PrListWidgetState();
}

class _PrListWidgetState extends ConsumerState<PrListWidget> {
  List<Map<String, dynamic>>? _prs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPRs();
  }

  Future<void> _loadPRs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = await ref.read(githubApiServiceProvider.future);
      if (api == null) return;
      final prs = await api.listPullRequests(
        widget.repo.owner,
        widget.repo.name,
      );
      setState(() => _prs = prs);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: ThemeConstants.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.merge,
                    size: 18,
                    color: ThemeConstants.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pull Requests — ${widget.repo.name}',
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  _CreatePRButton(repo: widget.repo),
                ],
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(
                                    color: ThemeConstants.error),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadPRs,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _prs == null || _prs!.isEmpty
                          ? const Center(
                              child: Text(
                                'No open pull requests',
                                style: TextStyle(
                                  color: ThemeConstants.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: _prs!.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final pr = _prs![i];
                                return _PrTile(pr: pr);
                              },
                            ),
            ),
          ],
        );
      },
    );
  }
}

class _PrTile extends StatelessWidget {
  const _PrTile({required this.pr});

  final Map<String, dynamic> pr;

  @override
  Widget build(BuildContext context) {
    final title = pr['title'] as String? ?? 'Untitled';
    final number = pr['number'] as int? ?? 0;
    final user =
        (pr['user'] as Map<String, dynamic>?)?['login'] as String? ?? '';
    final state = pr['state'] as String? ?? 'open';
    final isDraft = pr['draft'] as bool? ?? false;
    final baseBranch =
        (pr['base'] as Map<String, dynamic>?)?['ref'] as String? ?? '';
    final headBranch =
        (pr['head'] as Map<String, dynamic>?)?['ref'] as String? ?? '';

    return ListTile(
      leading: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDraft
              ? ThemeConstants.textMuted
              : state == 'open'
                  ? ThemeConstants.success
                  : ThemeConstants.error,
        ),
      ),
      title: Text(
        '#$number $title',
        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$headBranch → $baseBranch  ·  $user${isDraft ? '  · Draft' : ''}',
        style: const TextStyle(color: ThemeConstants.textMuted, fontSize: 11),
      ),
      hoverColor: ThemeConstants.editorLineHighlight,
    );
  }
}

class _CreatePRButton extends ConsumerStatefulWidget {
  const _CreatePRButton({required this.repo});

  final Repository repo;

  @override
  ConsumerState<_CreatePRButton> createState() => _CreatePRButtonState();
}

class _CreatePRButtonState extends ConsumerState<_CreatePRButton> {
  void _showCreateSheet() {
    showDialog<void>(
      context: context,
      builder: (_) => _CreatePRDialog(repo: widget.repo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _showCreateSheet,
      icon: const Icon(Icons.add, size: 14),
      label: const Text('New PR'),
      style: TextButton.styleFrom(foregroundColor: ThemeConstants.accent),
    );
  }
}

class _CreatePRDialog extends ConsumerStatefulWidget {
  const _CreatePRDialog({required this.repo});

  final Repository repo;

  @override
  ConsumerState<_CreatePRDialog> createState() => _CreatePRDialogState();
}

class _CreatePRDialogState extends ConsumerState<_CreatePRDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _headBranch;
  String _baseBranch = 'main';
  List<String> _branches = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final api = await ref.read(githubApiServiceProvider.future);
      if (api == null) return;
      final branches = await api.listBranches(
        widget.repo.owner,
        widget.repo.name,
      );
      setState(() {
        _branches = branches;
        _baseBranch = widget.repo.defaultBranch;
        if (branches.isNotEmpty) _headBranch = branches.first;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _headBranch == null) return;
    setState(() => _submitting = true);
    try {
      final api = await ref.read(githubApiServiceProvider.future);
      if (api == null) return;
      await api.createPullRequest(
        owner: widget.repo.owner,
        repo: widget.repo.name,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        head: _headBranch!,
        base: _baseBranch,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pull request created!'),
            backgroundColor: ThemeConstants.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create PR: $e'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeConstants.sidebarBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ThemeConstants.borderColor),
      ),
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Create Pull Request',
                          style: TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            maxWidth: 24,
                            maxHeight: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Branch selectors
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Head branch',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _headBranch,
                                dropdownColor: ThemeConstants.inputBackground,
                                style: const TextStyle(
                                  color: ThemeConstants.textPrimary,
                                  fontSize: 13,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                                items: _branches
                                    .map(
                                      (b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _headBranch = v),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: ThemeConstants.textMuted,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Base branch',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _baseBranch,
                                dropdownColor: ThemeConstants.inputBackground,
                                style: const TextStyle(
                                  color: ThemeConstants.textPrimary,
                                  fontSize: 13,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                                items: _branches
                                    .map(
                                      (b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _baseBranch = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Title
                    const Text(
                      'Title',
                      style: TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'PR title...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Body
                    const Text(
                      'Description (optional)',
                      style: TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _bodyController,
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe your changes...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create PR'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
