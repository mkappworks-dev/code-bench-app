import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/utils/debug_logger.dart';
import '../notifiers/pr_notifier.dart';

/// Inline card rendering live status for a single GitHub pull request.
///
/// Polls every 30 seconds via a Timer in state so CI results, merge
/// status, and review state stay fresh while the card is on screen.
/// Uses [prCardProvider] rather than touching [GitHubApiService] directly —
/// all API access is mediated by the notifier.
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
  // How many consecutive poll failures we tolerate before giving up.
  // Tuned so a flaky connection keeps working, but a revoked token or
  // deleted PR stops burning GitHub's rate limit quickly.
  static const int _kMaxConsecutiveFailures = 3;

  int _consecutiveFailures = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  PrCardNotifierProvider get _provider => prCardProvider(widget.owner, widget.repo, widget.prNumber);

  Future<void> _poll() async {
    await ref.read(_provider.notifier).refresh();
    if (!mounted) return;
    final current = ref.read(_provider);
    // If the provider is in error state (e.g. not signed in), stop polling.
    if (current.hasError) {
      _pollTimer?.cancel();
      return;
    }
    final cardState = current.value;
    if (cardState == null) return;

    if (cardState.pollError != null) {
      // Fatal errors (revoked token, deleted PR) will keep failing — bail now
      // instead of spending _kMaxConsecutiveFailures requests confirming it.
      if (cardState.pollFatal) {
        _pollTimer?.cancel();
        return;
      }
      _consecutiveFailures++;
      if (_consecutiveFailures >= _kMaxConsecutiveFailures) _pollTimer?.cancel();
    } else {
      _consecutiveFailures = 0;
    }

    // Stop polling once the PR reaches a terminal state — avoids burning
    // rate limit against a PR that will never change.
    final prState = cardState.pr['state'] as String? ?? 'open';
    if (cardState.merged || prState == 'closed') _pollTimer?.cancel();
  }

  /// Maps an exception into a short user-facing string.
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

  Future<void> _approve() async {
    final confirmed = await _confirm(
      title: 'Approve pull request?',
      body: '${widget.owner}/${widget.repo}#${widget.prNumber}',
      actionLabel: 'Approve',
    );
    if (confirmed != true) return;
    await ref.read(_provider.notifier).approve();
    if (!mounted) return;
    // The notifier stores failures on state.actionError instead of rethrowing;
    // the inline error banner renders from that — don't also toast success.
    if (ref.read(_provider).value?.actionError != null) return;
    _showSnack('Approved');
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
    await ref.read(_provider.notifier).merge();
    if (!mounted) return;
    if (ref.read(_provider).value?.actionError != null) return;
    _showSnack('Merged');
    _pollTimer?.cancel();
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String actionLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: destructive ? AppIcons.warning : AppIcons.gitPullRequest,
        iconType: destructive ? AppDialogIconType.destructive : AppDialogIconType.teal,
        title: title,
        content: Builder(
          builder: (context) => Text(body, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.of(ctx).pop(false)),
          destructive
              ? AppDialogAction.destructive(label: actionLabel, onPressed: () => Navigator.of(ctx).pop(true))
              : AppDialogAction.primary(label: actionLabel, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    AppSnackBar.show(context, message, type: AppSnackBarType.info);
  }

  Future<void> _openOnGitHub(String htmlUrl) async {
    final uri = Uri.tryParse(htmlUrl);
    if (uri == null) {
      _showSnack('Invalid PR URL');
      return;
    }
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) _showSnack('Could not open browser — $htmlUrl');
    } catch (e) {
      dLog('[PRCard] launchUrl failed: ${e.runtimeType}');
      _showSnack('Could not open browser — $htmlUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_provider);

    return async.when(
      loading: () => Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
              const SizedBox(width: 8),
              Text(
                'Loading PR…',
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            _friendlyError(e),
            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
          ),
        ),
      ),
      data: (s) => _buildCard(s),
    );
  }

  Widget _buildCard(PrCardState s) {
    final c = AppColors.of(context);
    final title = s.pr['title'] as String? ?? '';
    final prNum = s.pr['number'] as int? ?? widget.prNumber;
    final base = (s.pr['base'] as Map<String, dynamic>?)?['ref'] as String? ?? '';
    final head = (s.pr['head'] as Map<String, dynamic>?)?['ref'] as String? ?? '';
    final commits = s.pr['commits'] as int? ?? 0;
    final htmlUrl = s.pr['html_url'] as String? ?? '';
    final badgeText = s.merged ? 'merged' : (s.pr['state'] as String? ?? 'open');
    final badgeColor = switch (badgeText) {
      'merged' => c.prMergedColor,
      'closed' => c.error,
      _ => c.success,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.inputSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stale-data banner ──────────────────────────────────────────────
          if (s.pollError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: c.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 11, color: c.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(s.pollError!, style: TextStyle(color: c.error, fontSize: 10)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (s.actionError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: c.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 11, color: c.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(s.actionError!, style: TextStyle(color: c.error, fontSize: 10)),
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
                child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 9)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: ThemeConstants.uiFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '#$prNum',
                style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$base ← $head · $commits commit${commits == 1 ? '' : 's'}',
            style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeLabel),
          ),
          if (s.checkRuns.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 4, runSpacing: 4, children: s.checkRuns.map(_buildCheckChip).toList()),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!s.approved && !s.merged)
                TextButton(
                  onPressed: _approve,
                  child: const Text('✓ Approve', style: TextStyle(fontSize: ThemeConstants.uiFontSizeSmall)),
                )
              else if (s.approved && !s.merged)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Approved ✓',
                    style: TextStyle(color: c.success, fontSize: ThemeConstants.uiFontSizeSmall),
                  ),
                ),
              const SizedBox(width: 8),
              if (!s.merged)
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

  Widget _buildCheckChip(Map<String, dynamic> check) {
    final c = AppColors.of(context);
    final name = check['name'] as String? ?? '';
    final conclusion = check['conclusion'] as String?;
    final (icon, color) = switch (conclusion) {
      'success' => ('✓', c.success),
      'failure' => ('✗', c.error),
      _ => ('⏳', c.pendingAmber),
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
