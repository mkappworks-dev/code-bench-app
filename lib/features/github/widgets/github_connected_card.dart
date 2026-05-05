// lib/features/github/widgets/github_connected_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/debug_logger.dart';
import '../notifiers/github_auth_notifier.dart';

class GithubConnectedCard extends ConsumerStatefulWidget {
  const GithubConnectedCard({super.key, required this.account, required this.onDisconnect});

  final GitHubAccount account;
  final VoidCallback onDisconnect;

  @override
  ConsumerState<GithubConnectedCard> createState() => _GithubConnectedCardState();
}

class _GithubConnectedCardState extends ConsumerState<GithubConnectedCard> with WidgetsBindingObserver {
  bool _disconnectHovered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(githubInstallationsProvider);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      dLog('[GithubConnectedCard] launchUrl failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final installationsAsync = ref.watch(githubInstallationsProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.account.avatarUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.account.avatarUrl,
                width: 36,
                height: 36,
                errorBuilder: (_, _, _) => PersonIcon(c: c),
              ),
            )
          else
            PersonIcon(c: c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.account.username,
                  style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 12, color: c.success),
                    const SizedBox(width: 3),
                    Text('Connected', style: TextStyle(color: c.success, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                _InstallationsRow(
                  installationsAsync: installationsAsync,
                  onOpenUrl: _openUrl,
                  onInstall: () => _openUrl(ApiConstants.githubAppInstallUrl),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _disconnectHovered = true),
            onExit: (_) => setState(() => _disconnectHovered = false),
            child: GestureDetector(
              onTap: widget.onDisconnect,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _disconnectHovered ? c.errorTintBg : c.chipFill,
                  border: Border.all(color: _disconnectHovered ? c.error.withValues(alpha: 0.3) : c.chipStroke),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Disconnect',
                  style: TextStyle(
                    color: _disconnectHovered ? c.error : c.chipText,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallationsRow extends StatelessWidget {
  const _InstallationsRow({required this.installationsAsync, required this.onOpenUrl, required this.onInstall});

  final AsyncValue<List<GitHubAppInstallation>> installationsAsync;
  final void Function(String url) onOpenUrl;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return installationsAsync.when(
      loading: () => Row(
        children: [
          SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.mutedFg)),
          const SizedBox(width: 4),
          Text(
            'Checking App…',
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
          ),
        ],
      ),
      error: (_, _) => Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 11, color: c.warning),
          const SizedBox(width: 3),
          Text(
            'Could not check App — ',
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
          ),
          GestureDetector(
            onTap: onInstall,
            child: Text(
              'Install',
              style: TextStyle(color: c.accent, fontSize: ThemeConstants.uiFontSizeLabel, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      data: (installs) {
        if (installs.isEmpty) {
          return Row(
            children: [
              Icon(Icons.extension_off_outlined, size: 11, color: c.warning),
              const SizedBox(width: 3),
              Text(
                'App not installed — ',
                style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
              ),
              GestureDetector(
                onTap: onInstall,
                child: Text(
                  'Install',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: ThemeConstants.uiFontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }

        return Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.extension, size: 11, color: c.success),
                const SizedBox(width: 3),
                Text(
                  installs.length == 1 ? 'Installed' : 'Installed (${installs.length})',
                  style: TextStyle(color: c.success, fontSize: ThemeConstants.uiFontSizeLabel),
                ),
              ],
            ),
            for (final install in installs)
              GestureDetector(
                onTap: () => onOpenUrl(install.manageUrl),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@${install.accountLogin}',
                      style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Manage / Remove ↗',
                      style: TextStyle(
                        color: c.accent,
                        fontSize: ThemeConstants.uiFontSizeLabel,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            GestureDetector(
              onTap: onInstall,
              child: Text(
                '+ Add more',
                style: TextStyle(
                  color: c.accent,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PersonIcon extends StatelessWidget {
  const PersonIcon({super.key, required this.c});

  final AppColors c;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: c.inputSurface, shape: BoxShape.circle),
    child: Icon(Icons.person, size: 20, color: c.textSecondary),
  );
}
