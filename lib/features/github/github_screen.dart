import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/constants/theme_constants.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../data/models/repository.dart';
import '../../features/editor/editor_notifier.dart';
import '../../services/github/github_api_service.dart';
import '../../services/github/github_auth_service.dart';
import 'widgets/commit_dialog.dart';
import 'widgets/pr_list_widget.dart';
import 'widgets/repo_file_tree.dart';

class GithubScreen extends ConsumerStatefulWidget {
  const GithubScreen({super.key});

  @override
  ConsumerState<GithubScreen> createState() => _GithubScreenState();
}

class _GithubScreenState extends ConsumerState<GithubScreen> {
  final _searchController = TextEditingController();
  final _searchSubject = BehaviorSubject<String>.seeded('');
  List<Repository>? _repos;
  bool _loading = false;
  String? _error;
  Repository? _selectedRepo;
  String? _selectedBranch;
  List<String> _branches = [];
  _GithubView _view = _GithubView.repos;

  @override
  void initState() {
    super.initState();
    _searchSubject
        .debounceTime(const Duration(milliseconds: 400))
        .listen((query) => _search(query));
    _loadRepos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubject.close();
    super.dispose();
  }

  Future<void> _loadRepos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = await ref.read(githubApiServiceProvider.future);
      if (api == null) {
        setState(() => _loading = false);
        return;
      }
      final repos = await api.listRepositories();
      setState(() => _repos = repos);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadRepos();
      return;
    }
    setState(() => _loading = true);
    try {
      final api = await ref.read(githubApiServiceProvider.future);
      if (api == null) return;
      final repos = await api.searchRepositories(query);
      setState(() => _repos = repos);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _connect() async {
    try {
      final authService = ref.read(githubAuthServiceProvider);
      await authService.authenticate();
      await _loadRepos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GitHub auth failed: $e'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    }
  }

  Future<void> _selectRepo(Repository repo) async {
    final api = await ref.read(githubApiServiceProvider.future);
    if (api == null) return;
    try {
      final branches = await api.listBranches(repo.owner, repo.name);
      setState(() {
        _selectedRepo = repo;
        _selectedBranch = repo.defaultBranch;
        _branches = branches;
        _view = _GithubView.files;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load branches: $e')));
      }
    }
  }

  Future<void> _openFile(String path, String content, String language) async {
    final repo = _selectedRepo!;
    final label = '[GitHub] $path';
    ref.read(editorTabsProvider.notifier).openFile(
          OpenFile(
            path: '${repo.owner}/${repo.name}/$path',
            content: content,
            language: language,
            isReadOnly: true,
            label: label,
          ),
        );
    ref
        .read(activeFilePathProvider.notifier)
        .set('${repo.owner}/${repo.name}/$path');
    if (mounted) context.go('/editor');
  }

  @override
  Widget build(BuildContext context) {
    final apiAsync = ref.watch(githubApiServiceProvider);

    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: apiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(error: e.toString(), onRetry: _loadRepos),
        data: (api) {
          if (api == null) return _ConnectGitHub(onConnect: _connect);

          return _view == _GithubView.repos
              ? _RepoList(
                  repos: _repos,
                  loading: _loading,
                  error: _error,
                  searchController: _searchController,
                  onSearch: (q) => _searchSubject.add(q),
                  onRefresh: _loadRepos,
                  onSelectRepo: _selectRepo,
                )
              : _RepoDetail(
                  repo: _selectedRepo!,
                  branch: _selectedBranch!,
                  branches: _branches,
                  onBranchChanged: (b) => setState(() => _selectedBranch = b),
                  onBack: () => setState(() => _view = _GithubView.repos),
                  onOpenFile: _openFile,
                  onCommit: () => _showCommitDialog(context),
                  onShowPRs: () => _showPRList(context),
                );
        },
      ),
    );
  }

  void _showCommitDialog(BuildContext context) {
    if (_selectedRepo == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => CommitDialog(
        repo: _selectedRepo!,
        branch: _selectedBranch!,
        branches: _branches,
      ),
    );
  }

  void _showPRList(BuildContext context) {
    if (_selectedRepo == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ThemeConstants.sidebarBackground,
      isScrollControlled: true,
      builder: (_) => PrListWidget(repo: _selectedRepo!),
    );
  }
}

enum _GithubView { repos, files }

class _ConnectGitHub extends StatelessWidget {
  const _ConnectGitHub({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.source_outlined,
            size: 64,
            color: ThemeConstants.textMuted,
          ),
          const SizedBox(height: 24),
          const Text(
            'Connect GitHub',
            style: TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse repositories, view files, and commit changes.',
            style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onConnect,
            icon: const Icon(Icons.link),
            label: const Text('Connect GitHub Account'),
          ),
        ],
      ),
    );
  }
}

class _RepoList extends StatelessWidget {
  const _RepoList({
    required this.repos,
    required this.loading,
    required this.error,
    required this.searchController,
    required this.onSearch,
    required this.onRefresh,
    required this.onSelectRepo,
  });

  final List<Repository>? repos;
  final bool loading;
  final String? error;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;
  final ValueChanged<Repository> onSelectRepo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            onChanged: onSearch,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText: 'Search repositories...',
              prefixIcon: Icon(Icons.search, size: 16),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const SkeletonLoader(itemCount: 8)
              : error != null
                  ? _ErrorView(error: error!, onRetry: onRefresh)
                  : repos == null || repos!.isEmpty
                      ? const Center(
                          child: Text(
                            'No repositories found',
                            style: TextStyle(color: ThemeConstants.textMuted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: repos!.length,
                          itemBuilder: (context, index) {
                            final repo = repos![index];
                            return _RepoTile(
                              repo: repo,
                              onTap: () => onSelectRepo(repo),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _RepoDetail extends ConsumerWidget {
  const _RepoDetail({
    required this.repo,
    required this.branch,
    required this.branches,
    required this.onBranchChanged,
    required this.onBack,
    required this.onOpenFile,
    required this.onCommit,
    required this.onShowPRs,
  });

  final Repository repo;
  final String branch;
  final List<String> branches;
  final ValueChanged<String> onBranchChanged;
  final VoidCallback onBack;
  final void Function(String path, String content, String language) onOpenFile;
  final VoidCallback onCommit;
  final VoidCallback onShowPRs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: ThemeConstants.sidebarBackground,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 16),
                onPressed: onBack,
                tooltip: 'Back to repos',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${repo.owner}/${repo.name}',
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Branch selector
              PopupMenuButton<String>(
                onSelected: onBranchChanged,
                color: ThemeConstants.sidebarBackground,
                tooltip: 'Switch branch',
                itemBuilder: (_) => branches
                    .map(
                      (b) => PopupMenuItem(
                        value: b,
                        child: Text(
                          b,
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: ThemeConstants.borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_tree_outlined,
                        size: 12,
                        color: ThemeConstants.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        branch,
                        style: const TextStyle(
                          color: ThemeConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Icon(
                        Icons.expand_more,
                        size: 14,
                        color: ThemeConstants.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Actions
              IconButton(
                icon: const Icon(Icons.commit, size: 16),
                tooltip: 'Commit changes',
                onPressed: onCommit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.merge, size: 16),
                tooltip: 'Pull requests',
                onPressed: onShowPRs,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // File tree
        Expanded(
          child: RepoFileTree(
            repo: repo,
            branch: branch,
            onOpenFile: onOpenFile,
          ),
        ),
      ],
    );
  }
}

class _RepoTile extends StatelessWidget {
  const _RepoTile({required this.repo, required this.onTap});

  final Repository repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        repo.isPrivate ? Icons.lock_outline : Icons.source_outlined,
        size: 16,
        color: ThemeConstants.textMuted,
      ),
      title: Text(
        '${repo.owner}/${repo.name}',
        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 13),
      ),
      subtitle: repo.description != null
          ? Text(
              repo.description!,
              style: const TextStyle(
                color: ThemeConstants.textMuted,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (repo.language != null) ...[
            Text(
              repo.language!,
              style: const TextStyle(
                color: ThemeConstants.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 12),
          ],
          const Icon(
            Icons.star_outline,
            size: 13,
            color: ThemeConstants.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            '${repo.starCount}',
            style: const TextStyle(
              color: ThemeConstants.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
      hoverColor: ThemeConstants.editorLineHighlight,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: ThemeConstants.error,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
