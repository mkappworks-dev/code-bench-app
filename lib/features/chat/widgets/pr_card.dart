import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/github/github_api_service.dart';

/// Inline card rendering live status for a single GitHub pull request.
///
/// Polls every 30 seconds via a Timer in state so CI results, merge
/// status, and review state stay fresh while the card is on screen.
/// Uses [githubApiServiceProvider] rather than constructing
/// [GitHubApiService] by hand so the PAT never leaves the provider layer.
class PRCard extends ConsumerStatefulWidget {
  const PRCard({super.key, required this.owner, required this.repo, required this.prNumber});

  final String owner;
  final String repo;
  final int prNumber;

  @override
  ConsumerState<PRCard> createState() => _PRCardState();
}

class _PRCardState extends ConsumerState<PRCard> {
  static const Duration _kPollInterval = Duration(seconds: 30);

  Map<String, dynamic>? _pr;
  List<Map<String, dynamic>> _checkRuns = const [];
  bool _approved = false;
  bool _merged = false;
  String? _loadError;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    // Use the shared keepAlive provider: it reads the token from secure
    // storage, builds the Dio client, and returns null when no PAT is set.
    // Reinventing that here would be both a duplication and a second place
    // to forget a null check.
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) {
      if (!mounted) return;
      setState(() => _loadError = 'Not signed in to GitHub.');
      return;
    }
    try {
      final pr = await svc.getPullRequest(widget.owner, widget.repo, widget.prNumber);
      final sha = (pr['head'] as Map<String, dynamic>?)?['sha'] as String?;
      var checks = const <Map<String, dynamic>>[];
      if (sha != null) {
        checks = await svc.getCheckRuns(widget.owner, widget.repo, sha);
      }
      if (!mounted) return;
      setState(() {
        _pr = pr;
        _checkRuns = checks;
        _loadError = null;
        _merged = pr['merged'] as bool? ?? _merged;
      });
    } catch (e, st) {
      dLog('[PRCard] load failed: $e\n$st');
      if (!mounted) return;
      setState(() => _loadError = 'Failed to load PR.');
    }
  }

  Future<void> _approve() async {
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) return;
    try {
      await svc.approvePullRequest(widget.owner, widget.repo, widget.prNumber);
      if (!mounted) return;
      setState(() => _approved = true);
    } catch (e, st) {
      dLog('[PRCard] approve failed: $e\n$st');
    }
  }

  Future<void> _merge() async {
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) return;
    try {
      await svc.mergePullRequest(widget.owner, widget.repo, widget.prNumber);
      if (!mounted) return;
      setState(() => _merged = true);
    } catch (e, st) {
      dLog('[PRCard] merge failed: $e\n$st');
    }
  }

  Future<void> _openOnGitHub(String htmlUrl) async {
    final uri = Uri.tryParse(htmlUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      dLog('[PRCard] launchUrl failed: $e');
    }
  }

  String _badgeText() {
    if (_merged) return 'merged';
    final state = _pr?['state'] as String? ?? 'open';
    return state;
  }

  Color _badgeColor() => switch (_badgeText()) {
    'merged' => const Color(0xFF6E40C9),
    'closed' => ThemeConstants.error,
    _ => ThemeConstants.success,
  };

  @override
  Widget build(BuildContext context) {
    if (_pr == null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
            const SizedBox(width: 8),
            Text(
              _loadError ?? 'Loading PR…',
              style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ],
        ),
      );
    }

    final title = _pr!['title'] as String? ?? '';
    final prNum = _pr!['number'] as int? ?? widget.prNumber;
    final base = (_pr!['base'] as Map<String, dynamic>?)?['ref'] as String? ?? '';
    final head = (_pr!['head'] as Map<String, dynamic>?)?['ref'] as String? ?? '';
    final commits = _pr!['commits'] as int? ?? 0;
    final htmlUrl = _pr!['html_url'] as String? ?? '';
    final badgeColor = _badgeColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(_badgeText(), style: TextStyle(color: badgeColor, fontSize: 9)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: ThemeConstants.uiFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '#$prNum',
                style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$base ← $head · $commits commit${commits == 1 ? '' : 's'}',
            style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeLabel),
          ),
          if (_checkRuns.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 4, runSpacing: 4, children: _checkRuns.map(_buildCheckChip).toList()),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!_approved && !_merged)
                TextButton(
                  onPressed: _approve,
                  child: const Text('✓ Approve', style: TextStyle(fontSize: ThemeConstants.uiFontSizeSmall)),
                )
              else if (_approved && !_merged)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Approved ✓',
                    style: TextStyle(color: ThemeConstants.success, fontSize: ThemeConstants.uiFontSizeSmall),
                  ),
                ),
              const SizedBox(width: 8),
              if (!_merged)
                TextButton(
                  onPressed: _merge,
                  child: const Text('Merge ↓', style: TextStyle(fontSize: ThemeConstants.uiFontSizeSmall)),
                ),
              const Spacer(),
              TextButton(
                onPressed: htmlUrl.isEmpty ? null : () => _openOnGitHub(htmlUrl),
                child: const Text('Open on GitHub ↗', style: TextStyle(fontSize: ThemeConstants.uiFontSizeSmall)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckChip(Map<String, dynamic> c) {
    final name = c['name'] as String? ?? '';
    final conclusion = c['conclusion'] as String?;
    final (icon, color) = switch (conclusion) {
      'success' => ('✓', ThemeConstants.success),
      'failure' => ('✗', ThemeConstants.error),
      _ => ('⏳', const Color(0xFFFFAA00)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('$icon $name', style: TextStyle(color: color, fontSize: 9)),
    );
  }
}
