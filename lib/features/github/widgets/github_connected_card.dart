// lib/features/github/widgets/github_connected_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/debug_logger.dart';
import '../notifiers/github_auth_notifier.dart';

const String _kInstallAppLabel = 'Install GitHub App ↗';
const String _kManageLabel = 'Manage ↗';

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
      ref.read(gitHubAuthProvider.notifier).refreshInstallations();
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Account header row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.account.avatarUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      widget.account.avatarUrl,
                      width: 30,
                      height: 30,
                      errorBuilder: (_, _, _) => PersonIcon(c: c),
                    ),
                  )
                else
                  PersonIcon(c: c),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.account.username,
                        style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 10, color: c.success),
                          const SizedBox(width: 3),
                          Text(
                            'Connected',
                            style: TextStyle(color: c.success, fontSize: ThemeConstants.uiFontSizeLabel),
                          ),
                        ],
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
          ),
          Divider(height: 1, thickness: 1, color: c.deepBorder),
          // ── Installations section ───────────────────────────────────────
          _InstallationsSection(
            installationsAsync: installationsAsync,
            onOpenUrl: _openUrl,
            onInstall: () => _openUrl(ApiConstants.githubAppInstallUrl),
          ),
        ],
      ),
    );
  }
}

// ── Installations section ─────────────────────────────────────────────────────

class _InstallationsSection extends StatelessWidget {
  const _InstallationsSection({required this.installationsAsync, required this.onOpenUrl, required this.onInstall});

  final AsyncValue<List<GitHubAppInstallation>> installationsAsync;
  final void Function(String url) onOpenUrl;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return installationsAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.mutedFg)),
            const SizedBox(width: 6),
            Text(
              'Checking App…',
              style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
          ],
        ),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 12, color: c.warning),
            const SizedBox(width: 5),
            Text(
              'Could not check — ',
              style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
            GestureDetector(
              onTap: onInstall,
              child: Text(
                _kInstallAppLabel,
                style: TextStyle(
                  color: c.accent,
                  fontSize: ThemeConstants.uiFontSizeLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      data: (installs) {
        if (installs.isEmpty) return _EmptyInstallState(onInstall: onInstall);
        return _InstalledList(installs: installs, onOpenUrl: onOpenUrl, onInstall: onInstall);
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyInstallState extends StatelessWidget {
  const _EmptyInstallState({required this.onInstall});

  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.extension_off_outlined, size: 22, color: c.iconInactive),
          const SizedBox(height: 7),
          Text(
            'App not installed',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: ThemeConstants.uiFontSizeSmall,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Install the GitHub App on an org or\npersonal account to enable Code Bench.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel, height: 1.5),
          ),
          const SizedBox(height: 11),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onInstall,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: c.accentTintLight,
                  border: Border.all(color: c.accentBorderTeal),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _kInstallAppLabel,
                  style: TextStyle(
                    color: c.accent,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    fontWeight: FontWeight.w500,
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

// ── Installed list ────────────────────────────────────────────────────────────

class _InstalledList extends StatelessWidget {
  const _InstalledList({required this.installs, required this.onOpenUrl, required this.onInstall});

  final List<GitHubAppInstallation> installs;
  final void Function(String url) onOpenUrl;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final install in installs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: _InstallRow(install: install, onManage: () => onOpenUrl(install.manageUrl)),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.deepBorder)),
          ),
          child: Row(
            children: [
              Text(
                '${installs.length} ${installs.length == 1 ? 'install' : 'installs'}',
                style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onInstall,
                  child: Text(
                    _kInstallAppLabel,
                    style: TextStyle(
                      color: c.accent,
                      fontSize: ThemeConstants.uiFontSizeLabel,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Single installation row ───────────────────────────────────────────────────

class _InstallRow extends StatelessWidget {
  const _InstallRow({required this.install, required this.onManage});

  final GitHubAppInstallation install;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.frostedBg,
        border: Border.all(color: c.faintBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: c.chipFill,
              border: Border.all(color: c.chipStroke),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(install.isOrg ? Icons.business : Icons.person, size: 11, color: c.textMuted),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              install.accountLogin,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: ThemeConstants.uiFontSizeSmall,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: c.successBadgeBg,
              border: Border.all(color: c.success.withValues(alpha: 0.14)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'Installed',
              style: TextStyle(color: c.success, fontSize: ThemeConstants.uiFontSizeBadge),
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onManage,
              child: Text(
                _kManageLabel,
                style: TextStyle(color: c.dimFg, fontSize: ThemeConstants.uiFontSizeBadge),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fallback avatar ───────────────────────────────────────────────────────────

class PersonIcon extends StatelessWidget {
  const PersonIcon({super.key, required this.c});

  final AppColors c;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(color: c.inputSurface, shape: BoxShape.circle),
    child: Icon(Icons.person, size: 17, color: c.textSecondary),
  );
}
