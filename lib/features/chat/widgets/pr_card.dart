import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../services/github/github_api_service.dart';

/// Inline card rendering live status for a single GitHub pull request.
///
/// Polls every 30 seconds via a Timer in state so CI results, merge
/// status, and review state stay fresh while the card is on screen.
/// Uses [githubApiServiceProvider] rather than constructing
/// [GitHubApiService] by hand so the PAT never leaves the provider layer.
///
/// ### Error discipline
///
/// Every catch in this file logs **only** `e.runtimeType` (+ `statusCode`
/// for [NetworkException]). Never `'$e'`, never `'$st'`. A raw `$e` would
/// invoke `toString()` on the exception, and if it ever wraps a
/// `DioException` the dio request options — which include the
/// `Authorization: Bearer <PAT>` header — can be serialized into the log.
/// That explicitly violates the "no PAT header logging" rule in
/// `macos/Runner/README.md`.
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
  // How many consecutive load failures we tolerate before giving up and
  // parking the card in an error state. Tuned so a flaky connection with
  // one dropped request every few minutes keeps working, but a revoked
  // token or deleted PR stops burning GitHub's rate limit quickly.
  static const int _kMaxConsecutiveFailures = 3;

  Map<String, dynamic>? _pr;
  List<Map<String, dynamic>> _checkRuns = const [];
  bool _approved = false;
  bool _merged = false;
  // Rendered as an inline banner whenever non-null — whether or not the
  // initial load has succeeded. Previously this was only shown in the
  // pre-load placeholder, which meant any post-load poll failure froze
  // the card on stale data with no user-visible signal.
  String? _loadError;
  int _consecutiveFailures = 0;
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

  /// Maps an exception from [GitHubApiService] into a short user-facing
  /// string. Keep this in sync with the status codes GitHub can return
  /// for the PR endpoints used by this card.
  String _friendlyError(Object e) {
    if (e is NetworkException) {
      final s = e.statusCode;
      if (s == null) return 'Network error — check your connection.';
      if (s == 401) return 'GitHub authentication failed — check your token.';
      if (s == 403) return 'Permission denied.';
      if (s == 404) return 'Pull request not found.';
      if (s == 405) return 'Merge not allowed — state changed.';
      if (s == 409 || s == 422) return 'Cannot merge — resolve conflicts or required checks.';
      if (s >= 500) return 'GitHub service error ($s).';
      return 'Request failed ($s).';
    }
    if (e is AppException) return e.message;
    return 'Unexpected error.';
  }

  /// Returns `true` if the error represents a permanent condition where
  /// retrying would be futile (revoked token, deleted PR). The polling
  /// timer stops after seeing one of these rather than re-firing every
  /// 30 seconds against a PAT rate limit it can't recover from.
  bool _isFatal(Object e) {
    if (e is! NetworkException) return false;
    final s = e.statusCode;
    return s == 401 || s == 403 || s == 404;
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
      _pollTimer?.cancel();
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
      // `merged_at` is GitHub's canonical "this PR was merged" signal —
      // `merged` is only present on `GET /pulls/:n` responses, not on
      // list endpoints, and it's a derived field. Prefer `merged_at` so
      // a stale-shape response can't flip `_merged` back to false.
      final mergedNow = pr['merged'] as bool? ?? (pr['merged_at'] != null);
      final state = pr['state'] as String? ?? 'open';
      setState(() {
        _pr = pr;
        _checkRuns = checks;
        _loadError = null;
        _consecutiveFailures = 0;
        // Once merged, stay merged. See above.
        if (mergedNow) _merged = true;
      });
      // Stop polling once the PR reaches a terminal state. Without this
      // a chat with 10 merged PR cards burns 20 requests/min indefinitely
      // against a shared 5000/hr PAT quota, with no actionable change
      // between ticks.
      if (_merged || state == 'closed') {
        _pollTimer?.cancel();
      }
    } catch (e) {
      // SECURITY: only log runtimeType. See class-doc note on why.
      dLog('[PRCard] load failed: ${e.runtimeType}');
      if (!mounted) return;
      _consecutiveFailures++;
      setState(() => _loadError = _friendlyError(e));
      if (_isFatal(e) || _consecutiveFailures >= _kMaxConsecutiveFailures) {
        _pollTimer?.cancel();
      }
    }
  }

  Future<void> _approve() async {
    final confirmed = await _confirm(
      title: 'Approve pull request?',
      body: '${widget.owner}/${widget.repo}#${widget.prNumber}',
      actionLabel: 'Approve',
    );
    if (confirmed != true) return;
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) return;
    try {
      await svc.approvePullRequest(widget.owner, widget.repo, widget.prNumber);
      if (!mounted) return;
      setState(() => _approved = true);
      _showSnack('Approved');
    } catch (e) {
      dLog('[PRCard] approve failed: ${e.runtimeType}');
      if (!mounted) return;
      _showSnack('Approve failed: ${_friendlyError(e)}');
    }
  }

  Future<void> _merge() async {
    final confirmed = await _confirm(
      title: 'Merge pull request?',
      body:
          '${widget.owner}/${widget.repo}#${widget.prNumber}\n'
          'This will merge into the base branch using the repo default strategy.',
      actionLabel: 'Merge',
      destructive: true,
    );
    if (confirmed != true) return;
    final svc = await ref.read(githubApiServiceProvider.future);
    if (svc == null) return;
    try {
      await svc.mergePullRequest(widget.owner, widget.repo, widget.prNumber);
      if (!mounted) return;
      setState(() => _merged = true);
      _showSnack('Merged');
      // Terminal state — kick an immediate refresh then stop polling.
      _pollTimer?.cancel();
      unawaited(_load());
    } catch (e) {
      dLog('[PRCard] merge failed: ${e.runtimeType}');
      if (!mounted) return;
      _showSnack('Merge failed: ${_friendlyError(e)}');
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String actionLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: ThemeConstants.textPrimary)),
        content: Text(body, style: const TextStyle(color: ThemeConstants.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              actionLabel,
              style: TextStyle(color: destructive ? ThemeConstants.error : ThemeConstants.success),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openOnGitHub(String htmlUrl) async {
    final uri = Uri.tryParse(htmlUrl);
    if (uri == null) {
      _showSnack('Invalid PR URL');
      return;
    }
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      // `launchUrl` signals "no handler" by returning false rather than
      // throwing — which used to become a no-op click. Surface the URL
      // in a snackbar so the user can copy it manually.
      if (!launched) {
        _showSnack('Could not open browser — $htmlUrl');
      }
    } catch (e) {
      dLog('[PRCard] launchUrl failed: ${e.runtimeType}');
      _showSnack('Could not open browser — $htmlUrl');
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
          // ── Stale-data banner ─────────────────────────────────────────────
          // When polling fails after an initial load, surface the reason
          // above the card so the user knows why CI chips / merge state
          // may be out of date. Without this the card silently froze.
          if (_loadError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeConstants.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ThemeConstants.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 11, color: ThemeConstants.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_loadError!, style: const TextStyle(color: ThemeConstants.error, fontSize: 10)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
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
