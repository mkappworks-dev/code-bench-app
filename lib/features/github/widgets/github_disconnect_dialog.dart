// lib/features/github/widgets/github_disconnect_dialog.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/widgets/app_dialog.dart';
import '../notifiers/github_auth_notifier.dart';

class GitHubDisconnectDialog extends ConsumerStatefulWidget {
  const GitHubDisconnectDialog({super.key, required this.onConfirmed});

  final VoidCallback onConfirmed;

  static Future<void> show(BuildContext context, {required VoidCallback onConfirmed}) => showDialog<void>(
    context: context,
    builder: (_) => GitHubDisconnectDialog(onConfirmed: onConfirmed),
  );

  @override
  ConsumerState<GitHubDisconnectDialog> createState() => _GitHubDisconnectDialogState();
}

class _GitHubDisconnectDialogState extends ConsumerState<GitHubDisconnectDialog> {
  // Tracks whether the user has tapped the OAuth revoke link. Combined with an
  // empty installations list, this confirms GitHub-side revocation is complete
  // and triggers auto-completion of the local disconnect.
  bool _oauthLinkOpened = false;

  // Polls installations while the OAuth revoke page is open so the dialog
  // owns its own refresh cadence — does not depend on GithubConnectedCard's
  // lifecycle observer (which may be unmounted if the user navigates away
  // from settings while the dialog is showing).
  Timer? _installationsPoll;

  @override
  void dispose() {
    _installationsPoll?.cancel();
    super.dispose();
  }

  Future<bool> _openUrl(String url) async {
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e, st) {
      dLog('[GitHubDisconnectDialog] launchUrl failed: $e\n$st');
      return false;
    }
  }

  Future<void> _openOAuthRevoke() async {
    final ok = await _openUrl('https://github.com/settings/connections/applications/${ApiConstants.githubClientId}');
    // Only mark the OAuth step as opened after launchUrl actually succeeded —
    // a failed launch must not enable phantom auto-completion of disconnect.
    if (!ok || !mounted) return;
    setState(() => _oauthLinkOpened = true);
    _installationsPoll?.cancel();
    _installationsPoll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      ref.read(gitHubAuthProvider.notifier).refreshInstallations();
    });
  }

  void _complete() {
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final installs = ref.watch(githubInstallationsProvider).asData?.value ?? [];
    final showOauthRow = !(_oauthLinkOpened && installs.isEmpty);
    final hasManualSteps = showOauthRow || installs.isNotEmpty;

    // Once the user has opened the OAuth revoke page and GitHub confirms the
    // app installation is gone, auto-complete the local disconnect so the app
    // never ends up in a "Connected" state with an already-revoked token.
    ref.listen(githubInstallationsProvider, (_, next) {
      if (!_oauthLinkOpened) return;
      if (next case AsyncData(value: final v) when v.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
      }
    });

    return PopScope(
      // Prevent barrier-tap and back-key dismissal after revocation so the
      // user cannot escape into the broken "Connected + spinner" UI state.
      canPop: !(_oauthLinkOpened && installs.isEmpty),
      child: AppDialog(
        icon: Icons.link_off_rounded,
        iconType: AppDialogIconType.destructive,
        title: 'Disconnect GitHub',
        subtitle: 'Review what will be revoked before continuing.',
        content: _DisconnectContent(
          installs: installs,
          showOauthRow: showOauthRow,
          hasManualSteps: hasManualSteps,
          onOAuthRevoke: _openOAuthRevoke,
          onOpenUrl: _openUrl,
        ),
        actions: [
          // Hide Cancel once revocation is confirmed — only Disconnect remains.
          if (!(_oauthLinkOpened && installs.isEmpty))
            AppDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
          AppDialogAction.destructive(label: 'Disconnect', onPressed: _complete),
        ],
      ),
    );
  }
}

class _DisconnectContent extends StatelessWidget {
  const _DisconnectContent({
    required this.installs,
    required this.showOauthRow,
    required this.hasManualSteps,
    required this.onOAuthRevoke,
    required this.onOpenUrl,
  });

  final List<GitHubAppInstallation> installs;
  final bool showOauthRow;
  final bool hasManualSteps;
  final VoidCallback onOAuthRevoke;
  final Future<void> Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionLabel(label: 'Removed from this device', c: c),
        const SizedBox(height: 6),
        _Row(
          icon: Icons.check_circle_outline_rounded,
          iconColor: c.success,
          text: 'Stored token and account info',
          c: c,
        ),
        if (hasManualSteps) ...[
          const SizedBox(height: 14),
          _SectionLabel(label: 'Revoke manually on GitHub', c: c),
          const SizedBox(height: 6),
          if (showOauthRow) _LinkRow(text: 'OAuth app access', linkLabel: 'Revoke ↗', onTap: onOAuthRevoke, c: c),
          for (final install in installs) ...[
            const SizedBox(height: 4),
            _LinkRow(
              text: 'App: @${install.accountLogin}',
              linkLabel: 'Manage / Remove ↗',
              onTap: () => onOpenUrl(install.manageUrl),
              c: c,
            ),
          ],
        ],
        const SizedBox(height: 6),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.c});

  final String label;
  final AppColors c;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(color: c.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.iconColor, required this.text, required this.c});

  final IconData icon;
  final Color iconColor;
  final String text;
  final AppColors c;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: iconColor),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
      ),
    ],
  );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.text, required this.linkLabel, required this.onTap, required this.c});

  final String text;
  final String linkLabel;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.open_in_new_rounded, size: 11, color: c.mutedFg),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
      ),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            linkLabel,
            style: TextStyle(color: c.accent, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    ],
  );
}
